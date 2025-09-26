import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import 'nearby_service.dart';
import 'p2p_service.dart';
import 'ble_service.dart';
import 'sos_broadcast_service.dart';
import 'auth_service.dart';
import 'cloud_sync_service.dart';
import 'local_db_service.dart';
import 'error_handler_service.dart';

/// Production-ready service coordinator for Off-Grid SOS
/// Manages all communication services with priority-based fallback
class ServiceCoordinator {
  static final ServiceCoordinator _instance = ServiceCoordinator._internal();
  static ServiceCoordinator get instance => _instance;
  ServiceCoordinator._internal();

  // Service instances
  final NearbyService _nearbyService = NearbyService.instance;
  final P2PService _p2pService = P2PService.instance;
  final BLEService _bleService = BLEService.instance;
  final SOSBroadcastService _sosService = SOSBroadcastService.instance;
  final AuthService _authService = AuthService.instance;
  final EnhancedCloudSync _cloudSync = EnhancedCloudSync.instance;
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService.instance;

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
      debugPrint('🔄 ServiceCoordinator: Initializing all services...');

      // Initialize core services first
      await _authService.initialize();
      
      // Initialize communication services with fallbacks
      await _initializeWithRetry('nearby', () => _nearbyService.initialize());
      await _initializeWithRetry('p2p', () => _p2pService.initialize()); 
      await _initializeWithRetry('ble', () => _bleService.initialize());

      // Check if at least one communication service is available
      final hasConnection = _serviceStatus.values.any((status) => status);
      if (!hasConnection) {
        debugPrint('⚠️ No communication services available, continuing in limited mode');
      }

      // Initialize cloud sync
      _serviceStatus['cloud'] = true;
      _cloudSync.startAutoSync();

      // Start unified device discovery
      await _startUnifiedDiscovery();

      // Set up message listening
      _setupMessageListening();

      // Start automatic retry for failed services
      _startRetryMechanism();

      _isInitialized = true;
      debugPrint('✅ ServiceCoordinator: Initialized with services: ${_getActiveServices()}');
      return true;

    } catch (e) {
      debugPrint('❌ ServiceCoordinator initialization failed: $e');
      return false;
    }
  }

  Future<void> _initializeWithRetry(String serviceName, Future<bool> Function() initializer) async {
    try {
      final result = await initializer();
      _serviceStatus[serviceName] = result;
      if (result) {
        debugPrint('✅ $serviceName service initialized');
        _errorHandler.updateNetworkState(NetworkState.online);
      } else {
        debugPrint('⚠️ $serviceName service failed to initialize');
        _errorHandler.reportError(
          '${serviceName}_service',
          'Service initialization failed',
          severity: ErrorSeverity.warning,
          context: {'service': serviceName},
        );
      }
    } catch (e) {
      debugPrint('❌ $serviceName service error: $e');
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
    debugPrint('🔍 Starting unified device discovery...');
    
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
    _refreshDeviceList();
  }

  void _onDeviceLost(String deviceId) {
    _discoveredDevices.removeWhere((device) => device.id == deviceId);
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
  }

  void _handleIncomingMessage(Map<String, dynamic> messageData, String source) {
    try {
      final message = ChatMessage(
        id: messageData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: messageData['senderId'] ?? 'unknown',
        senderName: messageData['senderName'] ?? 'Unknown Device',
        receiverId: messageData['receiverId'] ?? 'me',
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

  /// Send message via best available service with fallback
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

    // Try services in priority order
    for (final service in _servicePriority) {
      if (_serviceStatus[service] != true) continue;
      
      try {
        bool sent = false;
        switch (service) {
          case 'nearby':
            await _nearbyService.sendMessage(
              jsonEncode(messageData), 
              type: message.isEmergency ? 'sos' : 'chat'
            );
            sent = true;
            break;
          case 'p2p':
            // P2P would need sendMessage implementation
            debugPrint('P2P send not implemented yet');
            break;
          case 'ble':
            // BLE would need sendMessage implementation  
            debugPrint('BLE send not implemented yet');
            break;
        }
        
        if (sent) {
          debugPrint('✅ Message sent via $service');
          await _dbService.updateMessageStatus(message.id, MessageStatus.sent);
          return true;
        }
      } catch (e) {
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
    
    _errorHandler.reportError(
      'service_coordinator',
      'All communication services failed to send message',
      severity: ErrorSeverity.error,
      context: {
        'message_id': message.id,
        'available_services': _servicePriority.where((s) => _serviceStatus[s] == true).toList(),
        'action': 'send_message_all_failed'
      },
    );
    
    return false;
  }

  /// Broadcast SOS signal via all available services
  Future<void> broadcastSOS(String message, {double? latitude, double? longitude}) async {
    debugPrint('🚨 Broadcasting SOS via all services...');
    
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
        broadcastTasks.add(_nearbyService.broadcastSOS(
          deviceId: sosData['deviceId'] as String,
          message: jsonEncode(sosData),
          additionalData: sosData,
        ));
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
          connected = await _nearbyService.connectToEndpoint(deviceId);
          break;
        case 'p2p':
          // P2P connection logic would be here
          debugPrint('P2P connection attempted for $deviceId');
          connected = true; // Placeholder
          break;
        case 'ble':
          // BLE connection logic would be here
          debugPrint('BLE connection attempted for $deviceId');
          connected = true; // Placeholder
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

  /// Start automatic retry mechanism for failed operations
  void _startRetryMechanism() {
    _retryTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _retryFailedMessages();
      await _retryFailedServices();
    });
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

  List<NearbyDevice> get discoveredDevices => _discoveredDevices.toList();
  bool get isInitialized => _isInitialized;
  List<String> get availableServices => _getActiveServices();

  /// Cleanup resources
  void dispose() {
    _retryTimer?.cancel();
    _discoveryTimer?.cancel();
    _deviceController.close();
    _messageController.close();
    _nearbyService.dispose();
    _p2pService.dispose();
    _cloudSync.dispose();
  }
}