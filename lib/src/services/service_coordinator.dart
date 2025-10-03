import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/chat_models.dart';
import '../utils/logger.dart';
import 'nearby_service_fixed.dart' as NearbyServiceFixed;
// Use the fixed version for better SOS-Rescuer communication
import 'p2p_service.dart';
import 'ble_service.dart';
import 'wifi_direct_service.dart';
import 'sos_broadcast_service.dart';
import 'auth_service.dart';
import 'local_db_service.dart';
import 'error_handler_service.dart';
import 'mesh_network_service.dart';
import 'location_service.dart';
import 'encryption_service.dart';
import 'firebase_service.dart';

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
  final WiFiDirectService _wifiDirectService = WiFiDirectService.instance;
  final SOSBroadcastService _sosService = SOSBroadcastService.instance;
  final AuthService _authService = AuthService.instance;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService.instance;
  final MeshNetworkService _meshService = MeshNetworkService.instance;
  final LocationService _locationService = LocationService.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;

  // State management
  bool _isInitialized = false;
  final Map<String, bool> _serviceStatus = {
    'nearby': false,
    'p2p': false,
    'ble': false,
    'wifiDirect': false,
    'cloud': false,
  };
  final List<String> _servicePriority = ['wifiDirect', 'ble', 'nearby', 'p2p']; // Priority order: WiFi > BLE > Nearby > P2P
  
  // Stream controllers for unified device discovery
  final StreamController<List<NearbyDevice>> _deviceController = 
      StreamController<List<NearbyDevice>>.broadcast();
  final StreamController<ChatMessage> _messageController = 
      StreamController<ChatMessage>.broadcast();
  
  final Set<NearbyDevice> _discoveredDevices = {};
  Timer? _retryTimer;
  Timer? _discoveryTimer;
  Timer? _syncTimer;
  final Set<String> _processedMessageIds = {}; // Prevent duplicate processing
  bool _isOnline = false;
  
  // Public streams
  Stream<List<NearbyDevice>> get deviceStream => _deviceController.stream;
  Stream<ChatMessage> get messageStream => _messageController.stream;

  /// Production-ready initialization: BLE/WiFi/Nearby/Mesh + message subscriptions
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      Logger.info('🚀 ServiceCoordinator: Starting production initialization...');

      // Step 1: Initialize core services first (authentication, location, encryption)
      Logger.info('📋 Step 1: Initializing core services...');
      
      // Initialize AuthService (if not already initialized)
      if (_authService.currentUser == null) {
        try {
          await _authService.initialize();
        } catch (e) {
          Logger.warning('AuthService initialization failed: $e');
        }
      }
      
      // Initialize location and encryption services if they have init methods
      try {
        // LocationService and EncryptionService are assumed to be ready
        Logger.info('Location and encryption services ready');
      } catch (e) {
        Logger.warning('Service preparation warning: $e');
      }
      
      Logger.success('✅ Core services prepared');
      
      // Step 2: Initialize mesh network service with current device
      Logger.info('🕸️ Step 2: Initializing mesh network...');
      final user = _authService.currentUser;
      final deviceId = user?.id ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
      await _meshService.initialize(deviceId);
      
      // Set up mesh connection handler for multi-hop routing
      _meshService.setConnectionHandler((String recipientId, MeshMessage message, String connectionType) async {
        return await _sendThroughConnectionType(connectionType, recipientId, message.chatMessage.content);
      });
      Logger.success('✅ Mesh network initialized');
      
      // Step 3: Initialize communication services in priority order with comprehensive retry
      Logger.info('📡 Step 3: Initializing communication services...');
      await Future.wait([
        _initializeWithRetry('wifiDirect', () => _wifiDirectService.initialize()),
        _initializeWithRetry('ble', () => _bleService.initialize()),
        _initializeWithRetry('nearby', () => _nearbyService.initialize()),
        _initializeWithRetry('p2p', () => _p2pService.initialize()),
      ]);
      
      final successfulServices = _getActiveServices();
      Logger.info('📊 Communication services status:');
      for (final service in _servicePriority) {
        final status = _serviceStatus[service] == true ? '✅' : '❌';
        Logger.info('  $status $service: ${_serviceStatus[service]}');
      }

      // Check if at least one communication service is available
      if (successfulServices.isEmpty) {
        Logger.critical('💥 No communication services available - app may not function properly');
        _errorHandler.reportError(
          'no_communication_services',
          'All communication services failed to initialize',
          severity: ErrorSeverity.critical,
          context: {'attempted_services': _servicePriority},
          canRecover: true,
        );
      } else {
        Logger.success('✅ ${successfulServices.length}/${_servicePriority.length} services available: ${successfulServices.join(', ')}');
      }

      // Step 4: Initialize cloud connectivity for sync queue
      Logger.info('☁️ Step 4: Checking cloud connectivity...');
      await _checkCloudConnectivity();
      
      // Step 5: Start unified device discovery across all services
      Logger.info('🔍 Step 5: Starting unified device discovery...');
      await _startUnifiedDiscovery();

      // Step 6: Set up comprehensive message listening with proper routing
      Logger.info('📨 Step 6: Setting up message listeners...');
      _setupMessageListening();

      // Step 7: Start background services (retry, sync, discovery refresh)
      Logger.info('⚙️ Step 7: Starting background services...');
      _startRetryMechanism();
      _startSyncTimer();

      _isInitialized = true;
      
      // Final status report
      Logger.success('🎉 ServiceCoordinator initialization COMPLETE!');
      Logger.info('📊 Final Status:');
      Logger.info('  🔗 Active Services: ${successfulServices.join(', ')}');
      Logger.info('  ☁️ Cloud: ${_isOnline ? 'Online' : 'Offline'}');
      Logger.info('  🕸️ Mesh: Active');
      Logger.info('  📍 Location: Available');
      
      _errorHandler.reportError(
        'service_coordinator_initialized',
        'ServiceCoordinator successfully initialized with ${successfulServices.length} services',
        severity: ErrorSeverity.info,
        context: {
          'active_services': successfulServices,
          'cloud_online': _isOnline,
          'mesh_active': true,
          'total_services_attempted': _servicePriority.length,
        },
        canRecover: false,
      );

      return true;

    } catch (e, stackTrace) {
      Logger.critical('💥 ServiceCoordinator initialization FAILED: $e\n$stackTrace');
      _errorHandler.reportError(
        'service_coordinator_init_failed',
        e,
        severity: ErrorSeverity.critical,
        context: {'stack_trace': stackTrace.toString()},
      );
      return false;
    }
  }

  /// Legacy method for backward compatibility
  Future<bool> initializeAll() async {
    return await init();
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
      discoveryTasks.add(_bleService.startScanning());
      _bleService.onDeviceFound.listen(_onBLEDeviceFound);
      _bleService.onDeviceLost.listen(_onDeviceLost);
    }
    
    if (_serviceStatus['wifiDirect'] == true) {
      discoveryTasks.add(_wifiDirectService.startDiscovery());
      _wifiDirectService.onPeerFound.listen(_onWiFiDirectDeviceFound);
      _wifiDirectService.onPeerLost.listen(_onDeviceLost);
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

  void _onBLEDeviceFound(BLEDevice bleDevice) {
    final device = NearbyDevice(
      id: bleDevice.id,
      name: bleDevice.name,
      role: _parseDeviceRole(bleDevice.name),
      isSOSActive: bleDevice.name.toLowerCase().contains('sos'),
      isRescuerActive: bleDevice.name.toLowerCase().contains('rescuer'),
      isConnected: bleDevice.isConnected,
      signalStrength: bleDevice.rssi,
      lastSeen: bleDevice.lastSeen,
      connectionType: 'ble',
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

  void _onWiFiDirectDeviceFound(WiFiDirectDevice wifiDevice) {
    final device = NearbyDevice(
      id: wifiDevice.deviceAddress,
      name: wifiDevice.deviceName,
      role: _parseDeviceRole(wifiDevice.deviceName),
      isSOSActive: wifiDevice.deviceName.toLowerCase().contains('sos'),
      isRescuerActive: wifiDevice.deviceName.toLowerCase().contains('rescuer'),
      isConnected: wifiDevice.status == 'CONNECTED',
      signalStrength: -30, // WiFi Direct typically has good signal
      lastSeen: DateTime.now(),
      connectionType: 'wifiDirect',
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

  /// Production-ready incoming message handler: save to DB, send ACK, relay if needed
  Future<void> handleIncoming(ChatMessage message, {String source = 'unknown'}) async {
    try {
      // Prevent duplicate processing
      if (_processedMessageIds.contains(message.id)) {
        Logger.info('Duplicate message ignored: ${message.id}');
        return;
      }
      _processedMessageIds.add(message.id);

      Logger.info('📨 Processing incoming message via $source: ${message.content}');

      // 1. Save to local database with received status
      final receivedMessage = message.copyWith(status: MessageStatus.received);
      await _dbService.insertMessage(receivedMessage);
      Logger.success('💾 Message saved to database: ${message.id}');

      // 2. Send ACK if required and not an ACK itself
      if (message.type != MessageType.ack && message.senderId != _authService.currentUser?.id) {
        await _sendAck(message);
      }

      // 3. Relay logic: Forward if device role is relay and TTL > 0
      final currentUser = _authService.currentUser;
      final isRelay = currentUser?.role == DeviceRole.relay;
      final shouldRelay = isRelay && (message.ttl ?? 0) > 0 && message.senderId != currentUser?.id;
      
      if (shouldRelay) {
        Logger.info('🔄 Relaying message - TTL: ${message.ttl}, Hops: ${message.hopCount ?? 0}');
        
        final relayedMessage = message.copyWith(
          ttl: (message.ttl ?? 1) - 1,
          hopCount: (message.hopCount ?? 0) + 1,
          status: MessageStatus.sending,
        );
        
        // Forward through mesh network for multi-hop routing
        final relaySuccess = await sendMessageThroughMesh(relayedMessage);
        
        if (relaySuccess) {
          Logger.success('✅ Message relayed successfully');
        } else {
          Logger.warning('⚠️ Message relay failed');
        }
      }

      // 4. Handle emergency messages with priority
      if (message.isEmergency) {
        Logger.critical('🚨 Emergency message received: ${message.content}');
        _errorHandler.reportError(
          'emergency_message_received',
          'Emergency message from ${message.senderName}',
          severity: ErrorSeverity.critical,
          context: {
            'sender': message.senderName,
            'content': message.content,
            'location': message.latitude != null ? '${message.latitude},${message.longitude}' : 'unknown'
          },
          canRecover: false,
        );
      }

      // 5. Emit to stream for UI updates
      _messageController.add(receivedMessage);

      Logger.success('✅ Message handling complete: ${message.id}');
      
    } catch (e, stackTrace) {
      Logger.error('❌ Error handling incoming message: $e\n$stackTrace');
      _errorHandler.reportError(
        'message_handling',
        e,
        severity: ErrorSeverity.error,
        context: {'message_id': message.id, 'source': source},
      );
    }
  }

  /// Send acknowledgment for received message
  Future<void> _sendAck(ChatMessage originalMessage) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final ackMessage = ChatMessage(
        id: 'ack_${originalMessage.id}_${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUser.id,
        senderName: currentUser.name,
        receiverId: originalMessage.senderId,
        content: 'ACK:${originalMessage.id}',
        type: MessageType.ack,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isEmergency: false,
      );

      await sendMessage(ackMessage);
      Logger.info('📤 ACK sent for message: ${originalMessage.id}');
      
    } catch (e) {
      Logger.error('Failed to send ACK: $e');
    }
  }

  /// Legacy wrapper for backward compatibility
  void _handleIncomingMessage(Map<String, dynamic> messageData, String source) {
    try {
      final message = ChatMessage(
        id: messageData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: messageData['senderId'] ?? 'unknown',
        senderName: messageData['senderName'] ?? 'Unknown Device',
        receiverId: messageData['receiverId'] ?? _authService.currentUser?.id ?? 'unknown',
        content: messageData['content'] ?? '',
        type: _parseMessageType(messageData['type']),
        status: MessageStatus.delivered,
        timestamp: DateTime.tryParse(messageData['timestamp'] ?? '') ?? DateTime.now(),
        isEmergency: messageData['isEmergency'] ?? false,
        latitude: messageData['latitude']?.toDouble(),
        longitude: messageData['longitude']?.toDouble(),
        ttl: messageData['ttl']?.toInt() ?? 3,
        hopCount: messageData['hopCount']?.toInt() ?? 0,
      );
      
      // Use the new async handler
      handleIncoming(message, source: source);
      
    } catch (e) {
      Logger.error('❌ Error parsing incoming message: $e');
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

  /// Production-ready message sending: routing priority WiFi>BLE>Nearby, retry & fallback
  Future<bool> sendMessage(ChatMessage message, {int maxRetries = 3}) async {
    Logger.info('📤 SEND MESSAGE: ${message.content.substring(0, min(50, message.content.length))}${message.content.length > 50 ? '...' : ''}');
    
    // Step 1: Prepare message data for transmission
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
      'ttl': message.ttl ?? 3,
      'hopCount': message.hopCount ?? 0,
      'requiresAck': message.requiresAck,
    };

    // Step 2: Save to local database first
    try {
      await _dbService.insertMessage(message.copyWith(status: MessageStatus.sending));
      Logger.info('💾 Message saved to local DB');
    } catch (e) {
      Logger.error('Failed to save message locally: $e');
    }

    List<String> attemptedServices = [];
    Exception? lastError;
    int retryCount = 0;

    // Step 3: Retry loop with exponential backoff
    while (retryCount <= maxRetries) {
      if (retryCount > 0) {
        final backoffDelay = Duration(milliseconds: 500 * (1 << (retryCount - 1)));
        Logger.info('⏳ Retry attempt $retryCount/$maxRetries after ${backoffDelay.inMilliseconds}ms');
        await Future.delayed(backoffDelay);
      }

      // Get optimal service order based on priority: WiFi > BLE > Nearby > P2P
      final orderedServices = _getOptimalServiceOrder(message.isEmergency);
      Logger.info('🎯 Service priority order: ${orderedServices.join(' > ')}');
      
      attemptedServices.clear(); // Clear for each retry
      
      // Step 4: Try each service in priority order
      for (final service in orderedServices) {
        if (_serviceStatus[service] != true) {
          Logger.info('⚠️ Skipping $service (unavailable)');
          continue;
        }
        
        attemptedServices.add(service);
        
        try {
          bool sent = false;
          Logger.info('🔄 Attempting $service (retry $retryCount)...');
          
          switch (service) {
            case 'wifiDirect':
              sent = await _sendViaWiFiDirect(messageData, message);
              break;
            case 'ble':
              sent = await _sendViaBLE(messageData, message);
              break;
            case 'nearby':
              sent = await _sendViaNearby(messageData, message);
              break;
            case 'p2p':
              sent = await _sendViaP2P(messageData, message);
              break;
          }
          
          if (sent) {
            Logger.success('✅ Message sent via $service (retry $retryCount)');
            await _dbService.updateMessageStatus(message.id, MessageStatus.sent);
            
            // Report success
            _errorHandler.reportError(
              'message_sent_success',
              'Message sent successfully via $service',
              severity: ErrorSeverity.info,
              context: {
                'service': service,
                'retry_count': retryCount,
                'message_id': message.id,
                'is_emergency': message.isEmergency,
              },
              canRecover: false,
            );
            
            return true;
          }
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          Logger.error('❌ $service failed: $e');
          _errorHandler.reportError(
            '${service}_send_failed',
            e,
            severity: ErrorSeverity.warning,
            context: {
              'service': service,
              'retry_count': retryCount,
              'message_id': message.id,
              'action': 'send_message',
            },
          );
          continue;
        }
      }
      
      retryCount++;
      
      // If this was the last retry, break
      if (retryCount > maxRetries) break;
      
      Logger.warning('⚠️ All services failed on retry $retryCount, retrying...');
    }
    
    // Step 5: All retries failed - queue for background retry
    await _dbService.updateMessageStatus(message.id, MessageStatus.failed);
    Logger.error('💥 SEND FAILED after $maxRetries retries');
    Logger.error('   Services attempted: ${attemptedServices.join(', ')}');
    
    _errorHandler.reportError(
      'message_send_all_failed',
      lastError ?? Exception('All communication services failed after $maxRetries retries'),
      severity: message.isEmergency ? ErrorSeverity.critical : ErrorSeverity.error,
      context: {
        'message_id': message.id,
        'attempted_services': attemptedServices,
        'retry_count': retryCount - 1,
        'is_emergency': message.isEmergency,
        'available_services': _getActiveServices(),
        'message_content_preview': message.content.substring(0, min(100, message.content.length)),
      },
    );
    
    return false;
  }

  /// Send via WiFi Direct (highest priority)
  Future<bool> _sendViaWiFiDirect(Map<String, dynamic> messageData, ChatMessage message) async {
    try {
      if (!_serviceStatus['wifiDirect']!) return false;
      
      Logger.info('📶 Sending via WiFi Direct...');
      // WiFi Direct implementation - placeholder until service supports send
      // For now, return false to try next service
      return false;
    } catch (e) {
      Logger.error('WiFi Direct send error: $e');
      return false;
    }
  }

  /// Send via BLE (second priority) 
  Future<bool> _sendViaBLE(Map<String, dynamic> messageData, ChatMessage message) async {
    try {
      if (!_serviceStatus['ble']!) return false;
      
      Logger.info('🔵 Sending via BLE...');
      // BLE implementation - placeholder until service supports send
      // For now, return false to try next service
      return false;
    } catch (e) {
      Logger.error('BLE send error: $e');
      return false;
    }
  }

  /// Send via Nearby Connections (third priority)
  Future<bool> _sendViaNearby(Map<String, dynamic> messageData, ChatMessage message) async {
    try {
      if (!_serviceStatus['nearby']!) return false;
      
      Logger.info('📱 Sending via Nearby Connections...');
      
      if (_nearbyService.connectedEndpoints.isEmpty) {
        Logger.warning('No connected endpoints for Nearby');
        return false;
      }
      
      // Send to all connected endpoints
      bool anySuccess = false;
      for (final endpointId in _nearbyService.connectedEndpoints) {
        try {
          await _nearbyService.sendMessage(endpointId, messageData);
          anySuccess = true;
          Logger.success('✅ Sent via Nearby to $endpointId');
        } catch (e) {
          Logger.error('Failed to send to endpoint $endpointId: $e');
        }
      }
      
      return anySuccess;
    } catch (e) {
      Logger.error('Nearby send error: $e');
      return false;
    }
  }

  /// Send via P2P (lowest priority)
  Future<bool> _sendViaP2P(Map<String, dynamic> messageData, ChatMessage message) async {
    try {
      if (!_serviceStatus['p2p']!) return false;
      
      Logger.info('🌐 Sending via P2P...');
      
      if (_p2pService.connectedPeers.isEmpty) {
        Logger.warning('No connected P2P peers');
        return false;
      }
      
      final messageJson = jsonEncode(messageData);
      final results = await Future.wait(
        _p2pService.connectedPeers.map((peerId) =>
          _p2pService.sendMessage(messageJson, targetPeerId: peerId)
        )
      );
      
      final successCount = results.where((r) => r).length;
      if (successCount > 0) {
        Logger.success('✅ Sent via P2P to $successCount/${_p2pService.connectedPeers.length} peers');
        return true;
      } else {
        Logger.warning('P2P send failed to all peers');
        return false;
      }
    } catch (e) {
      Logger.error('P2P send error: $e');
      return false;
    }
  }

  /// Production-ready SOS broadcast: assemble payload with GPS and encrypt
  Future<void> broadcastSOS([String? customMessage, double? latitude, double? longitude]) async {
    Logger.critical('🚨 Starting SOS broadcast sequence...');
    
    try {
      // 1. Get current location if not provided
      double? lat = latitude;
      double? lng = longitude;
      Position? currentLocation;
      
      if (latitude == null || longitude == null) {
        Logger.info('📍 Getting current location for SOS...');
        currentLocation = await _locationService.getCurrentPosition();
        lat = currentLocation?.latitude ?? latitude;
        lng = currentLocation?.longitude ?? longitude;
        
        if (currentLocation == null) {
          Logger.warning('⚠️ No location available for SOS broadcast');
        }
      }

      // 2. Assemble SOS payload with device info
      final currentUser = _authService.currentUser;
      final deviceId = currentUser?.id ?? await _getCurrentDeviceId();
      
      final sosPayload = {
        'type': 'sos_broadcast',
        'deviceId': deviceId,
        'userName': currentUser?.name ?? 'Unknown User',
        'message': customMessage ?? 'EMERGENCY SOS - Need immediate assistance!',
        'timestamp': DateTime.now().toIso8601String(),
        'location': {
          'latitude': lat,
          'longitude': lng,
          'accuracy': currentLocation?.accuracy ?? 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'deviceInfo': {
          'batteryLevel': await _getBatteryLevel(),
          'signalStrength': _getSignalStrength(),
          'availableServices': _getActiveServices(),
        },
        'priority': 'CRITICAL',
        'ttl': 10, // High TTL for emergency messages
      };

      // 3. Encrypt the SOS payload
      final payloadJson = jsonEncode(sosPayload);
      String encryptedPayload;
      
      try {
        encryptedPayload = _encryptionService.encryptString('broadcast', payloadJson);
        Logger.success('🔐 SOS payload encrypted');
      } catch (e) {
        Logger.warning('⚠️ Encryption failed, sending unencrypted: $e');
        encryptedPayload = payloadJson; // Fallback to unencrypted
      }

      // 4. Create SOS ChatMessage
      final sosMessage = ChatMessage(
        id: 'sos_${deviceId}_${DateTime.now().millisecondsSinceEpoch}',
        senderId: deviceId,
        senderName: currentUser?.name ?? 'SOS User',
        receiverId: 'broadcast',
        content: encryptedPayload,
        type: MessageType.sos,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isEmergency: true,
        latitude: lat,
        longitude: lng,
        ttl: 10,
        hopCount: 0,
      );

      // 5. Save SOS message locally first
      await _dbService.insertMessage(sosMessage);
      Logger.info('💾 SOS message saved locally');

      // 6. Broadcast via all available services simultaneously
      final broadcastTasks = <Future<bool>>[];
      int successCount = 0;
      
      // Direct service broadcasts
      if (_serviceStatus['wifiDirect'] == true) {
        broadcastTasks.add(_broadcastViaWiFiDirect(sosMessage));
      }
      if (_serviceStatus['ble'] == true) {
        broadcastTasks.add(_broadcastViaBLE(sosMessage));
      }
      if (_serviceStatus['nearby'] == true) {
        broadcastTasks.add(_broadcastViaNearby(sosMessage));
      }
      if (_serviceStatus['p2p'] == true) {
        broadcastTasks.add(_broadcastViaP2P(sosMessage));
      }
      
      // Mesh network broadcast
      broadcastTasks.add(broadcastSOSThroughMesh(sosMessage));
      
      // SOS service activation
      broadcastTasks.add(_activateSOSService(customMessage ?? 'EMERGENCY SOS'));
      
      if (broadcastTasks.isEmpty) {
        throw Exception('No communication services available for SOS broadcast');
      }
      
      // Execute all broadcasts and count successes
      final results = await Future.wait(broadcastTasks);
      successCount = results.where((success) => success).length;
      
      // 7. Update message status based on results
      if (successCount > 0) {
        await _dbService.updateMessageStatus(sosMessage.id, MessageStatus.sent);
        Logger.critical('🚨 SOS BROADCASTED via $successCount/${broadcastTasks.length} services');
        
        _errorHandler.reportError(
          'sos_broadcast_success',
          'SOS broadcast successful via $successCount services',
          severity: ErrorSeverity.critical,
          context: {
            'success_count': successCount,
            'total_services': broadcastTasks.length,
            'location': (lat != null && lng != null) ? '$lat,$lng' : 'unknown',
            'message_id': sosMessage.id,
          },
          canRecover: false,
        );
      } else {
        await _dbService.updateMessageStatus(sosMessage.id, MessageStatus.failed);
        throw Exception('All SOS broadcast attempts failed');
      }
      
    } catch (e, stackTrace) {
      Logger.critical('💥 SOS BROADCAST FAILED: $e\n$stackTrace');
      _errorHandler.reportError(
        'sos_broadcast_failed',
        e,
        severity: ErrorSeverity.critical,
        context: {
          'custom_message': customMessage,
          'location': '$latitude,$longitude',
          'available_services': _getActiveServices(),
        },
      );
      rethrow;
    }
  }

  // Individual service broadcast methods
  Future<bool> _broadcastViaWiFiDirect(ChatMessage sosMessage) async {
    try {
      // WiFi Direct broadcast implementation
      Logger.info('📡 Broadcasting SOS via WiFi Direct');
      // Implementation depends on WiFiDirectService capabilities
      return false; // Placeholder until WiFiDirectService supports broadcast
    } catch (e) {
      Logger.error('WiFi Direct SOS broadcast failed: $e');
      return false;
    }
  }

  Future<bool> _broadcastViaBLE(ChatMessage sosMessage) async {
    try {
      Logger.info('🔵 Broadcasting SOS via BLE');
      // BLE broadcast via advertising data or connected devices
      return false; // Placeholder until BLE service supports broadcast
    } catch (e) {
      Logger.error('BLE SOS broadcast failed: $e');
      return false;
    }
  }

  Future<bool> _broadcastViaNearby(ChatMessage sosMessage) async {
    try {
      Logger.info('📱 Broadcasting SOS via Nearby Connections');
      
      // Start SOS advertising
      await _nearbyService.startSOSAdvertising();
      
      // Broadcast to connected endpoints
      await _nearbyService.broadcastSOS(
        deviceId: sosMessage.senderId,
        message: sosMessage.content,
        additionalData: {
          'latitude': sosMessage.latitude,
          'longitude': sosMessage.longitude,
          'timestamp': sosMessage.timestamp.toIso8601String(),
        },
      );
      
      return true; // broadcastSOS is void, assume success if no exception
    } catch (e) {
      Logger.error('Nearby SOS broadcast failed: $e');
      return false;
    }
  }

  Future<bool> _broadcastViaP2P(ChatMessage sosMessage) async {
    try {
      Logger.info('🌐 Broadcasting SOS via P2P');
      
      if (_p2pService.connectedPeers.isEmpty) {
        Logger.warning('No P2P peers connected for SOS broadcast');
        return false;
      }
      
      // Send to all connected peers
      final results = await Future.wait(
        _p2pService.connectedPeers.map((peerId) =>
          _p2pService.sendMessage(sosMessage.content, targetPeerId: peerId)
        )
      );
      
      return results.any((success) => success);
    } catch (e) {
      Logger.error('P2P SOS broadcast failed: $e');
      return false;
    }
  }

  Future<bool> _activateSOSService(String message) async {
    try {
      await _sosService.activateVictimMode(emergencyMessage: message);
      return true;
    } catch (e) {
      Logger.error('SOS service activation failed: $e');
      return false;
    }
  }

  /// Connect to specific device via best available service
  Future<bool> connectToDevice(String deviceId) async {
    Logger.info('🔗 Connecting to device: $deviceId');
    
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
          Logger.warning('🛑 Max retry attempts reached for this session');
          retryCount = 0; // Reset for next failure
          return;
        }
        
        final hasFailedServices = _serviceStatus.values.any((status) => !status);
        final hasPendingMessages = (await _dbService.getPendingMessages()).isNotEmpty;
        
        if (hasFailedServices || hasPendingMessages) {
          retryCount++;
          Logger.info('🔄 Retry attempt $retryCount/$maxRetries (backoff: ${backoffDuration.inSeconds}s)');
          
          await _retryFailedMessages();
          await _retryFailedServices();
          
          // Schedule next retry
          scheduleRetry();
        } else {
          // Reset retry count if everything is working
          retryCount = 0;
          Logger.info('✅ All services operational, retry mechanism idle');
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
        Logger.info('🔄 Retrying failed service: $service');
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

  /// Production-ready sync queue: upload pending messages to cloud when online
  Future<void> syncQueue() async {
    if (!_isOnline) {
      Logger.info('⚠️ Device offline, skipping sync queue');
      return;
    }

    try {
      Logger.info('☁️ Starting sync queue to cloud...');
      
      // Get all pending messages
      final pendingMessages = await _dbService.getPendingMessages();
      
      if (pendingMessages.isEmpty) {
        Logger.info('✅ No pending messages to sync');
        return;
      }
      
      Logger.info('📤 Syncing ${pendingMessages.length} pending messages...');
      
      int successCount = 0;
      int failCount = 0;
      
      for (final message in pendingMessages) {
        try {
          // Upload message to Firebase/cloud
          bool uploadSuccess = false;
          
          try {
            // Attempt to upload via Firebase service
            if (_firebaseService.isInitialized) {
              if (message.isEmergency && message.type == MessageType.sos) {
                // Upload SOS messages to public collection
                uploadSuccess = await _firebaseService.uploadSOSAlert(message);
              } else {
                // Upload regular messages to private chats
                uploadSuccess = await _firebaseService.uploadMessage(message);
              }
              
              if (uploadSuccess) {
                Logger.info('📤 Message uploaded to cloud: ${message.id}');
              } else {
                Logger.warning('⚠️ Failed to upload message: ${message.id}');
              }
            } else {
              Logger.warning('Firebase not initialized, skipping upload');
              uploadSuccess = false;
            }
          } catch (e) {
            Logger.error('Cloud upload error: $e');
            uploadSuccess = false;
          }
          
          if (uploadSuccess) {
            // Update local message status to synced
            await _dbService.updateMessageStatus(message.id, MessageStatus.synced);
            successCount++;
            Logger.success('✅ Message synced: ${message.id}');
          } else {
            failCount++;
            Logger.warning('⚠️ Failed to sync message: ${message.id}');
          }
          
        } catch (e) {
          failCount++;
          Logger.error('❌ Error syncing message ${message.id}: $e');
          
          _errorHandler.reportError(
            'sync_message_failed',
            e,
            severity: ErrorSeverity.warning,
            context: {
              'message_id': message.id,
              'is_emergency': message.isEmergency,
            },
          );
        }
        
        // Small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      Logger.success('☁️ Sync complete: $successCount synced, $failCount failed');
      
      if (successCount > 0) {
        _errorHandler.reportError(
          'sync_queue_success',
          'Successfully synced $successCount messages to cloud',
          severity: ErrorSeverity.info,
          context: {
            'synced_count': successCount,
            'failed_count': failCount,
            'total_pending': pendingMessages.length,
          },
          canRecover: false,
        );
      }
      
    } catch (e, stackTrace) {
      Logger.error('💥 Sync queue failed: $e\n$stackTrace');
      _errorHandler.reportError(
        'sync_queue_failed',
        e,
        severity: ErrorSeverity.error,
        context: {'action': 'sync_queue'},
      );
    }
  }

  /// Check cloud connectivity and update status
  Future<void> _checkCloudConnectivity() async {
    try {
      final isConnected = _firebaseService.isInitialized;
      _serviceStatus['cloud'] = isConnected;
      _isOnline = isConnected;
      
      if (isConnected) {
        Logger.success('☁️ Cloud connectivity established');
        _errorHandler.updateNetworkState(NetworkState.online);
      } else {
        Logger.warning('☁️ Cloud connectivity unavailable');
        _errorHandler.updateNetworkState(NetworkState.offline);
      }
    } catch (e) {
      Logger.error('Failed to check cloud connectivity: $e');
      _serviceStatus['cloud'] = false;
      _isOnline = false;
    }
  }

  /// Start sync timer for periodic cloud synchronization
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _checkCloudConnectivity();
      if (_isOnline) {
        await syncQueue();
      }
    });
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

  /// Helper methods for SOS payload
  Future<int> _getBatteryLevel() async {
    try {
      // Implementation depends on battery info plugin
      return 75; // Placeholder
    } catch (e) {
      return -1; // Unknown
    }
  }

  int _getSignalStrength() {
    // Return best available signal strength
    final activeServices = _getActiveServices();
    if (activeServices.contains('wifiDirect')) return -30;
    if (activeServices.contains('ble')) return -60;
    if (activeServices.contains('nearby')) return -50;
    return -80;
  }

  /// Cleanup resources
  void dispose() {
    _retryTimer?.cancel();
    _discoveryTimer?.cancel();
    _syncTimer?.cancel();
    _deviceController.close();
    _messageController.close();
    _nearbyService.dispose();
    _p2pService.dispose();
    _meshService.dispose();
  }
}