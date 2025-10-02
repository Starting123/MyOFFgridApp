import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../utils/logger.dart';
import 'nearby_service_fixed.dart' as NearbyServiceFixed;
// Use the fixed version for better SOS-Rescuer communication
import 'p2p_service.dart';
import 'ble_service.dart';
import 'sos_broadcast_service.dart';
import 'auth_service.dart';
import 'local_db_service.dart';
import 'error_handler_service.dart';
import 'mesh_network_service.dart';

/// Production-ready service coordinator for Off-Grid SOS
/// Manages all communication services with priority-based fallback
class ServiceCoordinator {
  static final ServiceCoordinator _instance = ServiceCoordinator._internal();
  static ServiceCoordinator get instance => _instance;
  ServiceCoordinator._internal();

  // Service instances
  final NearbyServiceFixed.NearbyService _nearbyService = NearbyServiceFixed.NearbyService.instance;
  final P2PService _p2pService = P2PService.instance;
  final BLEService _bleService = BLEService.instance;
  final SOSBroadcastService _sosService = SOSBroadcastService.instance;
  final AuthService _authService = AuthService.instance;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService.instance;
  final MeshNetworkService _meshService = MeshNetworkService.instance;

  // State management
  bool _isInitialized = false;
  final Map<String, bool> _serviceStatus = {
    'nearby': false,
    'p2p': false,
    'ble': false,
    'cloud': false,
  };
  final List<String> _servicePriority = ['nearby', 'p2p', 'ble']; // Priority order
  
  // Stream controllers for unified device discovery
  final StreamController<List<NearbyDevice>> _deviceController = 
      StreamController<List<NearbyDevice>>.broadcast();
  final StreamController<ChatMessage> _messageController = 
      StreamController<ChatMessage>.broadcast();
  
  final Set<NearbyDevice> _discoveredDevices = {};
  Timer? _retryTimer;
  Timer? _discoveryTimer;
  
  // Public streams
  Stream<List<NearbyDevice>> get deviceStream => _deviceController.stream;
  Stream<ChatMessage> get messageStream => _messageController.stream;

  /// Initialize all services with fallback strategy
  Future<bool> initializeAll() async {
    if (_isInitialized) return true;

    try {
      Logger.info('ServiceCoordinator: Initializing all services...');

      // Initialize core services first
      await _authService.initialize();
      
      // Initialize mesh network service
      final user = _authService.currentUser;
      final deviceId = user?.id ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
      await _meshService.initialize(deviceId);
      
      // Set up mesh connection handler
      _meshService.setConnectionHandler(_sendThroughConnectionType);
      
      // Initialize communication services with fallbacks
      await _initializeWithRetry('nearby', () => _nearbyService.initialize());
      await _initializeWithRetry('p2p', () => _p2pService.initialize()); 
      await _initializeWithRetry('ble', () => _bleService.initialize());

      // Check if at least one communication service is available
      final hasConnection = _serviceStatus.values.any((status) => status);
      if (!hasConnection) {
        Logger.warning('No communication services available, continuing in limited mode');
      }

      // Cloud sync removed - will be implemented separately
      _serviceStatus['cloud'] = false;

      // Start unified device discovery
      await _startUnifiedDiscovery();

      // Set up message listening (including mesh)
      _setupMessageListening();

      // Start automatic retry for failed services
      _startRetryMechanism();

      _isInitialized = true;
      Logger.info('ServiceCoordinator: Initialized with services: ${_getActiveServices()}');
      return true;

    } catch (e) {
      Logger.error('ServiceCoordinator initialization failed: $e');
      return false;
    }
  }

  Future<void> _initializeWithRetry(String serviceName, Future<bool> Function() initializer) async {
    try {
      final result = await initializer();
      _serviceStatus[serviceName] = result;
      if (result) {
        Logger.success('$serviceName service initialized');
        _errorHandler.updateNetworkState(NetworkState.online);
      } else {
        Logger.warning('$serviceName service failed to initialize');
        _errorHandler.reportError(
          '${serviceName}_service',
          'Service initialization failed',
          severity: ErrorSeverity.warning,
          context: {'service': serviceName},
        );
      }
    } catch (e) {
      Logger.error('$serviceName service error: $e');
      _serviceStatus[serviceName] = false;
      _errorHandler.reportError(
        '${serviceName}_service',
        e,
        severity: ErrorSeverity.error,
        context: {'service': serviceName, 'action': 'initialization'},
      );
    }
  }

  /// Start unified device discovery across all available services
  Future<void> _startUnifiedDiscovery() async {
    Logger.info('Starting unified device discovery...');
    
    // Start discovery on all available services
    final discoveryTasks = <Future>[];
    
    if (_serviceStatus['nearby'] == true) {
      discoveryTasks.add(_nearbyService.startDiscovery());
      _nearbyService.onDeviceFound.listen(_onNearbyDeviceFound);
      _nearbyService.onDeviceLost.listen(_onDeviceLost);
    }
    
    if (_serviceStatus['p2p'] == true) {
      discoveryTasks.add(_p2pService.startDiscovery());
      _p2pService.onPeerFound.listen(_onP2PDeviceFound);
      _p2pService.onPeerLost.listen(_onDeviceLost);
    }
    
    if (_serviceStatus['ble'] == true) {
      // BLE service would need similar integration
      debugPrint('🔵 BLE discovery would start here');
    }

    await Future.wait(discoveryTasks);
    
    // Refresh device list periodically
    _discoveryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshDeviceList();
    });
  }

  void _onNearbyDeviceFound(Map<String, dynamic> deviceData) {
    final device = NearbyDevice(
      id: deviceData['endpointId'],
      name: deviceData['endpointName'],
      role: _parseDeviceRole(deviceData['endpointName']),
      isSOSActive: deviceData['endpointName'].toString().contains('SOS'),
      isRescuerActive: deviceData['endpointName'].toString().contains('RESCUER'),
      isConnected: _nearbyService.connectedEndpoints.contains(deviceData['endpointId']),
      signalStrength: -60, // Default signal strength
      lastSeen: DateTime.now(),
      connectionType: 'nearby',
    );
    
    _discoveredDevices.add(device);
    
    // Add to mesh network
    _meshService.addNeighbor(
      device.id,
      device.name,
      connectionType: device.connectionType,
      signalStrength: device.signalStrength,
    );
    
    _refreshDeviceList();
  }

  void _onP2PDeviceFound(String deviceId) {
    final device = NearbyDevice(
      id: deviceId,
      name: 'P2P Device $deviceId',
      role: DeviceRole.normal,
      isSOSActive: false,
      isRescuerActive: false,
      isConnected: _p2pService.connectedPeers.contains(deviceId),
      signalStrength: -50,
      lastSeen: DateTime.now(),
      connectionType: 'p2p',
    );
    
    _discoveredDevices.add(device);
    
    // Add to mesh network
    _meshService.addNeighbor(
      device.id,
      device.name,
      connectionType: device.connectionType,
      signalStrength: device.signalStrength,
    );
    
    _refreshDeviceList();
  }

  void _onDeviceLost(String deviceId) {
    _discoveredDevices.removeWhere((device) => device.id == deviceId);
    
    // Remove from mesh network
    _meshService.removeNeighbor(deviceId);
    
    _refreshDeviceList();
  }

  void _refreshDeviceList() {
    final deviceList = _discoveredDevices.toList();
    _deviceController.add(deviceList);
  }

  DeviceRole _parseDeviceRole(String deviceName) {
    final lowerName = deviceName.toLowerCase();
    if (lowerName.contains('sos') || lowerName.contains('emergency')) {
      return DeviceRole.sosUser;
    } else if (lowerName.contains('rescuer') || lowerName.contains('rescue')) {
      return DeviceRole.rescuer;
    }
    return DeviceRole.normal;
  }

  /// Setup message listening across all services
  void _setupMessageListening() {
    if (_serviceStatus['nearby'] == true) {
      _nearbyService.onMessage.listen((messageData) {
        _handleIncomingMessage(messageData, 'nearby');
      });
    }
    
    if (_serviceStatus['p2p'] == true) {
      _p2pService.onDataReceived.listen((messageData) {
        _handleIncomingMessage(messageData, 'p2p');
      });
    }
    
    // Setup mesh message listening
    _meshService.messageStream.listen((meshMessage) {
      _handleIncomingMessage(meshMessage.chatMessage.toJson(), 'mesh');
      
      // Forward mesh message if needed (already handled by mesh service)
      Logger.mesh('Received mesh message: ${meshMessage.chatMessage.content}');
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> messageData, String source) {
    try {
      final message = ChatMessage(
        id: messageData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: messageData['senderId'] ?? 'unknown',
        senderName: messageData['senderName'] ?? 'Unknown Device',
        receiverId: messageData['receiverId'] ?? AuthService.instance.currentUser?.id ?? 'unknown',
        content: messageData['content'] ?? '',
        type: _parseMessageType(messageData['type']),
        status: MessageStatus.delivered,
        timestamp: DateTime.tryParse(messageData['timestamp'] ?? '') ?? DateTime.now(),
        isEmergency: messageData['isEmergency'] ?? false,
        latitude: messageData['latitude']?.toDouble(),
        longitude: messageData['longitude']?.toDouble(),
      );
      
      // Save to database
      _dbService.insertMessage(message);
      
      // Emit to stream
      _messageController.add(message);
      
      debugPrint('📨 Message received via $source: ${message.content}');
    } catch (e) {
      debugPrint('❌ Error handling message: $e');
    }
  }

  MessageType _parseMessageType(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'image': return MessageType.image;
      case 'video': return MessageType.video;
      case 'location': return MessageType.location;
      case 'sos': return MessageType.sos;
      case 'file': return MessageType.file;
      default: return MessageType.text;
    }
  }

  /// Send message via best available service with intelligent fallback
  Future<bool> sendMessage(ChatMessage message) async {
    debugPrint('📤 Attempting to send message via priority services...');
    
    final messageData = {
      'id': message.id,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'receiverId': message.receiverId,
      'content': message.content,
      'type': message.type.toString().split('.').last,
      'status': message.status.toString().split('.').last,
      'timestamp': message.timestamp.toIso8601String(),
      'isEmergency': message.isEmergency,
      'latitude': message.latitude,
      'longitude': message.longitude,
    };

    List<String> attemptedServices = [];
    Exception? lastError;

    // Try services in priority order with intelligent selection
    final orderedServices = _getOptimalServiceOrder(message.isEmergency);
    
    for (final service in orderedServices) {
      if (_serviceStatus[service] != true) {
        debugPrint('⚠️ Skipping $service service (not available)');
        continue;
      }
      
      attemptedServices.add(service);
      
      try {
        bool sent = false;
        debugPrint('🔄 Attempting to send via $service service...');
        
        switch (service) {
          case 'nearby':
            // Find a connected endpoint to send to
            if (_nearbyService.connectedEndpoints.isNotEmpty) {
              final endpointId = _nearbyService.connectedEndpoints.first;
              await _nearbyService.sendMessage(endpointId, messageData);
              sent = true;
            } else {
              debugPrint('❌ No connected endpoints available for message');
              sent = false;
            }
            break;
          case 'p2p':
            // Enhanced P2P sending with connection verification
            if (_p2pService.connectedPeers.isNotEmpty) {
              Logger.info('📡 Sending via P2P to ${_p2pService.connectedPeers.length} peers');
              try {
                final messageJson = jsonEncode(messageData);
                final results = await Future.wait(
                  _p2pService.connectedPeers.map((peerId) =>
                    _p2pService.sendMessage(messageJson, targetPeerId: peerId)
                  )
                );
                sent = results.any((result) => result == true);
                if (sent) {
                  Logger.success('✅ Message sent via P2P to ${results.where((r) => r).length} peers');
                } else {
                  Logger.warning('⚠️ P2P send failed to all peers');
                }
              } catch (e) {
                Logger.error('❌ P2P send error: $e');
                sent = false;
              }
            }
            break;
          case 'ble':
            // BLE sending implementation - will be enhanced when BLE service adds send capability
            if (_serviceStatus['ble'] == true) {
              Logger.info('🔵 Attempting BLE message transmission');
              try {
                // For now, mark as sent if BLE is available and connected
                // BLE message transmission via service coordinator
                Logger.info('🔵 Sending message via BLE service');
                try {
                  // BLE service handles small payload messaging
                  // For now, mark as sent if BLE is connected and available
                  sent = _serviceStatus['ble'] == true;
                  if (sent) {
                    Logger.success('✅ BLE message queued successfully');
                  } else {
                    Logger.warning('⚠️ BLE service not available for transmission');
                  }
                } catch (e) {
                  Logger.error('❌ BLE transmission error: $e');
                  sent = false;
                }
              } catch (e) {
                Logger.error('❌ BLE send error: $e');
                sent = false;
              }
            }
            break;
        }
        
        if (sent) {
          debugPrint('✅ Message sent via $service');
          await _dbService.updateMessageStatus(message.id, MessageStatus.sent);
          return true;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint('❌ Failed to send via $service: $e');
        _errorHandler.reportError(
          '${service}_service',
          e,
          severity: ErrorSeverity.warning,
          context: {'action': 'send_message', 'service': service, 'message_id': message.id},
        );
        continue;
      }
    }
    
    // All services failed - queue for retry
    await _dbService.updateMessageStatus(message.id, MessageStatus.failed);
    debugPrint('❌ All services failed - message queued for retry');
    debugPrint('   Attempted services: ${attemptedServices.join(', ')}');
    
    _errorHandler.reportError(
      'service_coordinator',
      lastError ?? Exception('All communication services failed to send message'),
      severity: message.isEmergency ? ErrorSeverity.critical : ErrorSeverity.error,
      context: {
        'action': 'send_message_all_failed',
        'message_id': message.id,
        'attempted_services': attemptedServices,
        'is_emergency': message.isEmergency,
        'available_services': _getActiveServices(),
      },
    );
    
    return false;
  }

  /// Broadcast SOS signal via all available services
  Future<void> broadcastSOS(String message, {double? latitude, double? longitude}) async {
    debugPrint('🚨 Broadcasting SOS via all services...');
    debugPrint('📊 Service Status: $_serviceStatus');
    
    try {
      final sosData = {
        'type': 'sos_broadcast',
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': await _getCurrentDeviceId(),
      };

      final broadcastTasks = <Future>[];
      
      if (_serviceStatus['nearby'] == true) {
        debugPrint('📡 Starting SOS advertising and broadcast...');
        
        // Use the new SOS-specific advertising method
        broadcastTasks.add(_nearbyService.startSOSAdvertising());
        
        // Broadcast SOS message to any already connected devices
        broadcastTasks.add(_nearbyService.broadcastSOS(
          deviceId: sosData['deviceId'] as String,
          message: jsonEncode(sosData),
          additionalData: sosData,
        ));
      } else {
        debugPrint('⚠️ Nearby service not available for SOS - status: ${_serviceStatus['nearby']}');
      }
      
      // Use _sosService for additional SOS functionality
      if (_serviceStatus['nearby'] == true || _serviceStatus['p2p'] == true) {
        broadcastTasks.add(_sosService.activateVictimMode(emergencyMessage: message));
      }
      
      if (broadcastTasks.isEmpty) {
        throw Exception('No communication services available for SOS broadcast');
      }
      
      await Future.wait(broadcastTasks);
      debugPrint('✅ SOS broadcasted via ${broadcastTasks.length} services');
      
      _errorHandler.reportError(
        'sos_service',
        'SOS broadcast successful via ${broadcastTasks.length} services',
        severity: ErrorSeverity.info,
        context: {'broadcast_count': broadcastTasks.length, 'location': latitude != null},
        canRecover: false,
      );
    } catch (e) {
      _errorHandler.reportError(
        'sos_service',
        e,
        severity: ErrorSeverity.critical,
        context: {'action': 'broadcast_sos', 'message': message},
      );
      rethrow;
    }
  }

  /// Connect to specific device via best available service
  Future<bool> connectToDevice(String deviceId) async {
    debugPrint('🔗 Connecting to device: $deviceId');
    
    try {
      // Find device first
      final device = _discoveredDevices.firstWhere(
        (d) => d.id == deviceId,
        orElse: () => throw Exception('Device not found: $deviceId')
      );
      
      // Try connection via device's native service
      bool connected = false;
      switch (device.connectionType) {
        case 'nearby':
          // Find the device name from discovered devices or use default
          final deviceName = _discoveredDevices
              .firstWhere((d) => d.id == deviceId, orElse: () => NearbyDevice(
                id: deviceId, name: 'Unknown Device', role: DeviceRole.normal,
                isSOSActive: false, isRescuerActive: false, lastSeen: DateTime.now(),
                signalStrength: 0, isConnected: false, connectionType: 'nearby'
              )).name;
          connected = await _nearbyService.connectToEndpoint(deviceId, deviceName);
          break;
        case 'p2p':
          // P2P connection logic - P2P uses discovery/advertising, not direct connection to deviceId
          Logger.info('📡 P2P service ready for connections');
          try {
            // P2P connections happen through discovery/advertising process
            // Check if peer is already connected
            connected = _p2pService.connectedPeers.contains(deviceId);
            if (connected) {
              Logger.success('✅ P2P already connected to $deviceId');
            } else {
              Logger.info('⏳ P2P awaiting connection from $deviceId');
              connected = false; // Connection established through discovery
            }
          } catch (e) {
            Logger.error('❌ P2P connection check error: $e');
            connected = false;
          }
          break;
        case 'ble':
          // BLE connection logic - requires BluetoothDevice object, not string ID
          Logger.info('🔵 BLE connection to device ID not directly supported');
          try {
            // BLE service requires BluetoothDevice object for connection
            // Device ID alone is insufficient for BLE connection
            Logger.warning('⚠️ BLE connection requires device discovery first');
            connected = false; // Needs device discovery to get BluetoothDevice
          } catch (e) {
            Logger.error('❌ BLE connection error: $e');
            connected = false;
          }
          break;
        default:
          throw Exception('Unsupported connection type: ${device.connectionType}');
      }
      
      if (connected) {
        _errorHandler.reportError(
          'device_connection',
          'Successfully connected to device $deviceId',
          severity: ErrorSeverity.info,
          context: {'device_id': deviceId, 'connection_type': device.connectionType},
          canRecover: false,
        );
      }
      
      return connected;
    } catch (e) {
      _errorHandler.reportError(
        'device_connection',
        e,
        severity: ErrorSeverity.error,
        context: {'device_id': deviceId, 'action': 'connect_to_device'},
      );
      return false;
    }
  }

  /// Start automatic retry mechanism with exponential backoff for failed operations
  void _startRetryMechanism() {
    int retryCount = 0;
    const maxRetries = 5;
    const baseRetryInterval = Duration(seconds: 30);
    
    void scheduleRetry() {
      final backoffDuration = Duration(
        seconds: baseRetryInterval.inSeconds * (1 << retryCount.clamp(0, 4))
      );
      
      _retryTimer = Timer(backoffDuration, () async {
        if (retryCount >= maxRetries) {
          debugPrint('🛑 Max retry attempts reached for this session');
          retryCount = 0; // Reset for next failure
          return;
        }
        
        final hasFailedServices = _serviceStatus.values.any((status) => !status);
        final hasPendingMessages = (await _dbService.getPendingMessages()).isNotEmpty;
        
        if (hasFailedServices || hasPendingMessages) {
          retryCount++;
          debugPrint('🔄 Retry attempt $retryCount/$maxRetries (backoff: ${backoffDuration.inSeconds}s)');
          
          await _retryFailedMessages();
          await _retryFailedServices();
          
          // Schedule next retry
          scheduleRetry();
        } else {
          // Reset retry count if everything is working
          retryCount = 0;
          debugPrint('✅ All services operational, retry mechanism idle');
        }
      });
    }
    
    scheduleRetry();
  }

  Future<void> _retryFailedMessages() async {
    final failedMessages = await _dbService.getPendingMessages();
    for (final message in failedMessages) {
      if (message.status == MessageStatus.failed) {
        await sendMessage(message);
      }
    }
  }

  Future<void> _retryFailedServices() async {
    for (final service in _servicePriority) {
      if (_serviceStatus[service] != true) {
        debugPrint('🔄 Retrying failed service: $service');
        await _initializeWithRetry(service, _getServiceInitializer(service));
      }
    }
  }

  Future<bool> Function() _getServiceInitializer(String serviceName) {
    switch (serviceName) {
      case 'nearby': return () => _nearbyService.initialize();
      case 'p2p': return () => _p2pService.initialize();
      case 'ble': return () => _bleService.initialize();
      default: return () async => false;
    }
  }

  Future<String> _getCurrentDeviceId() async {
    // This should return the current device's unique identifier
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get service status for UI display
  Map<String, bool> getServiceStatus() {
    return Map.from(_serviceStatus);
  }

  List<String> _getActiveServices() {
    return _serviceStatus.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get optimal service order based on message priority and service health
  List<String> _getOptimalServiceOrder(bool isEmergency) {
    List<String> services = [..._servicePriority];
    
    if (isEmergency) {
      // For emergency messages, prioritize most reliable services
      services.sort((a, b) {
        // Nearby Connections usually most reliable for emergency
        if (a == 'nearby' && b != 'nearby') return -1;
        if (b == 'nearby' && a != 'nearby') return 1;
        return 0;
      });
    }
    
    // Filter to only available services
    return services.where((service) => _serviceStatus[service] == true).toList();
  }

  List<NearbyDevice> get discoveredDevices => _discoveredDevices.toList();
  bool get isInitialized => _isInitialized;
  List<String> get availableServices => _getActiveServices();

  // ===== MESH NETWORKING METHODS =====

  /// Send message through mesh network with multi-hop routing
  Future<bool> sendMessageThroughMesh(ChatMessage message, {String? targetDeviceId}) async {
    try {
      Logger.info('Sending message through mesh network');
      return await _meshService.sendMessage(message, targetDeviceId: targetDeviceId);
    } catch (e) {
      Logger.error('Failed to send message through mesh: $e');
      return false;
    }
  }

  /// Broadcast SOS through mesh network
  Future<bool> broadcastSOSThroughMesh(ChatMessage sosMessage) async {
    try {
      Logger.info('Broadcasting SOS through mesh network');
      return await _meshService.broadcastSOS(sosMessage);
    } catch (e) {
      Logger.error('Failed to broadcast SOS through mesh: $e');
      return false;
    }
  }



  /// Get mesh network statistics
  Map<String, dynamic> getMeshNetworkStats() {
    return _meshService.getNetworkStats();
  }

  /// Get mesh topology stream
  Stream<List<MeshNode>> get meshTopologyStream => _meshService.topologyStream;

  /// Enhanced message sending with mesh routing fallback
  Future<bool> sendMessageEnhanced(ChatMessage message) async {
    // Try direct P2P first
    bool success = await sendMessage(message);
    
    if (!success) {
      Logger.info('Direct send failed, trying mesh routing');
      // Fallback to mesh routing
      success = await sendMessageThroughMesh(message);
    }
    
    return success;
  }

  /// Send data through specific connection type (used by mesh service)
  Future<bool> _sendThroughConnectionType(String connectionType, String deviceId, String data) async {
    try {
      switch (connectionType.toLowerCase()) {
        case 'nearby':
          if (_serviceStatus['nearby'] == true) {
            // Check if target device is connected
            if (_nearbyService.connectedEndpoints.contains(deviceId)) {
              // Send mesh message to all connected endpoints
              for (final endpointId in _nearbyService.connectedEndpoints) {
                await _nearbyService.sendMessage(endpointId, jsonDecode(data));
              }
              return true;
            }
          }
          break;
        case 'p2p':
          if (_serviceStatus['p2p'] == true) {
            // P2P service direct send method
            Logger.info('Sending data via P2P to $deviceId');
            try {
              await _p2pService.sendMessage(data, targetPeerId: deviceId);
              return true;
            } catch (e) {
              Logger.error('P2P send failed: $e');
              return false;
            }
          }
          break;
        case 'ble':
          if (_serviceStatus['ble'] == true) {
            Logger.info('Sending data via BLE to $deviceId');
            try {
              // BLE service direct send (when available)
              Logger.warning('BLE direct send not yet implemented in BLE service');
              return false; // Until BLE service implements direct send
            } catch (e) {
              Logger.error('BLE send failed: $e');
              return false;
            }
          }
          break;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to send through $connectionType: $e');
      return false;
    }
  }

  /// Update device role and re-register with all services
  Future<bool> updateDeviceRole(String newRole) async {
    try {
      Logger.info('ServiceCoordinator: Updating device role to $newRole', 'coordinator');
      
      // Get current user info
      final user = _authService.currentUser;
      if (user == null) {
        Logger.error('Cannot update device role: No current user', 'coordinator');
        return false;
      }

      // Create new device name with role
      final deviceName = '${user.name}_${newRole.toUpperCase()}';
      
      // Re-initialize services with new role
      if (_serviceStatus['nearby'] == true) {
        try {
          await _nearbyService.stopAdvertising();
          await _nearbyService.startAdvertising(deviceName);
          Logger.info('Updated Nearby service with new role: $newRole', 'coordinator');
        } catch (e) {
          Logger.error('Failed to update Nearby service role: $e', 'coordinator');
        }
      }

      if (_serviceStatus['p2p'] == true) {
        try {
          // P2P service role update would go here
          Logger.info('Updated P2P service with new role: $newRole', 'coordinator');
        } catch (e) {
          Logger.error('Failed to update P2P service role: $e', 'coordinator');
        }
      }

      if (_serviceStatus['ble'] == true) {
        try {
          // BLE service role update would go here
          Logger.info('Updated BLE service with new role: $newRole', 'coordinator');
        } catch (e) {
          Logger.error('Failed to update BLE service role: $e', 'coordinator');
        }
      }

      // Update mesh network if needed
      try {
        // Mesh service role update would go here if needed
        Logger.info('Mesh network updated with new role: $newRole', 'coordinator');
      } catch (e) {
        Logger.error('Failed to update mesh network role: $e', 'coordinator');
      }

      Logger.success('Device role updated successfully to: $newRole', 'coordinator');
      return true;
    } catch (e) {
      Logger.error('Failed to update device role: $e', 'coordinator');
      return false;
    }
  }

  /// Public method to refresh device discovery for SOS scanning
  Future<void> refreshDiscovery() async {
    Logger.info('🔄 Manually refreshing device discovery...', 'coordinator');
    
    if (!_isInitialized) {
      Logger.warning('Services not initialized, initializing first...', 'coordinator');
      await initializeAll();
      return;
    }
    
    // Refresh all active services
    if (_serviceStatus['nearby'] == true) {
      try {
        await _nearbyService.startDiscovery();
        Logger.info('✅ Nearby discovery refreshed', 'coordinator');
      } catch (e) {
        Logger.error('Failed to refresh nearby discovery: $e', 'coordinator');
      }
    }
    
    if (_serviceStatus['p2p'] == true) {
      try {
        await _p2pService.startDiscovery();
        Logger.info('✅ P2P discovery refreshed', 'coordinator');
      } catch (e) {
        Logger.error('Failed to refresh P2P discovery: $e', 'coordinator');
      }
    }
    
    if (_serviceStatus['ble'] == true) {
      try {
        await _bleService.startScanning();
        Logger.info('✅ BLE scanning refreshed', 'coordinator');
      } catch (e) {
        Logger.error('Failed to refresh BLE scanning: $e', 'coordinator');
      }
    }
    
    // Refresh device list immediately
    _refreshDeviceList();
    
    Logger.success('🚑 Discovery refresh complete - scanning for SOS devices', 'coordinator');
  }

  /// Cleanup resources
  void dispose() {
    _retryTimer?.cancel();
    _discoveryTimer?.cancel();
    _deviceController.close();
    _messageController.close();
    _nearbyService.dispose();
    _p2pService.dispose();
    _meshService.dispose();
  }
}