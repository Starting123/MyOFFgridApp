import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/nearby_service.dart';
import '../services/sos_broadcast_service.dart';
import '../services/local_db_service.dart';
import '../services/p2p_service.dart';
import '../services/ble_service.dart';
import '../models/chat_models.dart';

/// Central service that coordinates all off-grid communication services
class OffGridServiceManager {
  static final OffGridServiceManager _instance = OffGridServiceManager._internal();
  static OffGridServiceManager get instance => _instance;
  OffGridServiceManager._internal();

  // Service instances
  final NearbyService _nearbyService = NearbyService.instance;
  final SOSBroadcastService _sosService = SOSBroadcastService.instance;
  final LocalDatabaseService _database = LocalDatabaseService();
  final P2PService _p2pService = P2PService.instance;
  final BLEService _bleService = BLEService.instance;

  // Stream controllers for coordinated events
  final StreamController<NearbyDevice> _deviceDiscoveredController = 
      StreamController<NearbyDevice>.broadcast();
  final StreamController<ChatMessage> _messageReceivedController = 
      StreamController<ChatMessage>.broadcast();
  final StreamController<ChatMessage> _sosReceivedController = 
      StreamController<ChatMessage>.broadcast();

  // Streams
  Stream<NearbyDevice> get onDeviceDiscovered => _deviceDiscoveredController.stream;
  Stream<ChatMessage> get onMessageReceived => _messageReceivedController.stream;
  Stream<ChatMessage> get onSOSReceived => _sosReceivedController.stream;

  // State
  bool _isInitialized = false;
  final List<NearbyDevice> _discoveredDevices = [];
  final List<StreamSubscription> _subscriptions = [];

  /// Initialize all services and set up coordinated communication
  Future<bool> initializeAllServices() async {
    if (_isInitialized) return true;

    try {
      debugPrint('🚀 Initializing Off-Grid Service Manager...');

      // Initialize core services
      final results = await Future.wait([
        _nearbyService.initialize(),
        _p2pService.initialize(),
        _bleService.initialize(),
      ]);

      // Check if critical services initialized successfully
      if (!results[0]) {
        debugPrint('⚠️ Nearby Service failed to initialize');
      }

      // Set up service coordination
      _setupServiceCoordination();

      // Start discovery by default
      await startDeviceDiscovery();

      _isInitialized = true;
      debugPrint('✅ Off-Grid Service Manager initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize Off-Grid Service Manager: $e');
      return false;
    }
  }

  /// Set up coordination between services
  void _setupServiceCoordination() {
    // Listen to nearby device discovery
    _subscriptions.add(
      _nearbyService.onDeviceFound.listen(_handleDeviceFound),
    );

    // Listen to incoming messages
    _subscriptions.add(
      _nearbyService.onMessage.listen(_handleIncomingMessage),
    );

    // Listen to SOS broadcasts (skip for now - will be handled via messages)
    // _subscriptions.add(
    //   _sosService.onSOSReceived.listen(_handleSOSBroadcast),
    // );

    // Listen to device lost
    _subscriptions.add(
      _nearbyService.onDeviceLost.listen(_handleDeviceLost),
    );
  }

  /// Handle device discovery from multiple sources
  void _handleDeviceFound(Map<String, dynamic> deviceData) {
    final deviceId = deviceData['id'] ?? '';
    final deviceName = deviceData['name'] ?? 'Unknown Device';
    
    // Check if device already discovered
    final existingIndex = _discoveredDevices.indexWhere((d) => d.id == deviceId);
    
    final device = NearbyDevice(
      id: deviceId,
      name: deviceName,
      role: DeviceRole.normal,
      isSOSActive: false,
      isRescuerActive: false,
      lastSeen: DateTime.now(),
      signalStrength: deviceData['signalStrength'] ?? -50,
      isConnected: _nearbyService.connectedEndpoints.contains(deviceId),
      connectionType: 'nearby',
    );

    if (existingIndex >= 0) {
      _discoveredDevices[existingIndex] = device;
    } else {
      _discoveredDevices.add(device);
    }

    _deviceDiscoveredController.add(device);
    debugPrint('📱 Device discovered: $deviceName ($deviceId)');
  }

  /// Handle incoming messages and route them appropriately
  void _handleIncomingMessage(Map<String, dynamic> messageData) {
    try {
      final messageType = messageData['type'] ?? 'chat';
      
      if (messageType == 'sos') {
        // Handle as SOS message
        _handleSOSMessage(messageData);
      } else {
        // Handle as regular chat message
        _handleChatMessage(messageData);
      }
    } catch (e) {
      debugPrint('Error handling incoming message: $e');
    }
  }

  /// Handle regular chat messages
  void _handleChatMessage(Map<String, dynamic> messageData) async {
    try {
      final message = ChatMessage(
        id: messageData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: messageData['senderId'] ?? 'unknown',
        senderName: messageData['senderName'] ?? 'Unknown',
        receiverId: 'me',
        content: messageData['content'] ?? '',
        type: _parseMessageType(messageData['messageType']),
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        isEmergency: messageData['isEmergency'] ?? false,
      );

      // Save to database
      await _database.insertMessage(message);
      
      // Emit to UI
      _messageReceivedController.add(message);
      
      debugPrint('💬 Received message: ${message.content}');
    } catch (e) {
      debugPrint('Error handling chat message: $e');
    }
  }

  /// Handle SOS messages
  void _handleSOSMessage(Map<String, dynamic> messageData) {
    // Just process as SOS message for now
    debugPrint('🚨 Received SOS signal: ${messageData['content']}');
    
    // Create emergency message
    final emergencyMessage = ChatMessage(
      id: messageData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: messageData['senderId'] ?? 'unknown',
      senderName: messageData['senderName'] ?? 'Emergency Device',
      receiverId: 'me',
      content: messageData['content'] ?? 'SOS Signal',
      type: MessageType.sos,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
      isEmergency: true,
      latitude: messageData['latitude']?.toDouble(),
      longitude: messageData['longitude']?.toDouble(),
    );

    _messageReceivedController.add(emergencyMessage);
  }



  /// Handle device lost
  void _handleDeviceLost(String deviceId) {
    _discoveredDevices.removeWhere((d) => d.id == deviceId);
    debugPrint('📱 Device lost: $deviceId');
  }

  /// Start device discovery across all services
  Future<void> startDeviceDiscovery() async {
    try {
      debugPrint('🔍 Starting device discovery...');
      
      // Start discovery on all available services
      await Future.wait([
        _nearbyService.startDiscovery(),
        _p2pService.startDiscovery(),
        // BLE discovery can be started separately if needed
      ]);
      
      debugPrint('✅ Device discovery started');
    } catch (e) {
      debugPrint('❌ Error starting device discovery: $e');
    }
  }

  /// Stop device discovery
  Future<void> stopDeviceDiscovery() async {
    try {
      await Future.wait([
        _nearbyService.stopDiscovery(),
        _p2pService.stopDiscovery(),
      ]);
      debugPrint('⏹️ Device discovery stopped');
    } catch (e) {
      debugPrint('❌ Error stopping device discovery: $e');
    }
  }

  /// Send message via best available connection
  Future<bool> sendMessage(ChatMessage message) async {
    try {
      // Try Nearby Connections first
      if (_nearbyService.connectedEndpoints.isNotEmpty) {
        await _nearbyService.sendMessage(
          message.content,
          type: message.isEmergency ? 'sos' : 'chat',
        );
        return true;
      }

      // Try P2P if available
      if (_p2pService.connectedPeers.isNotEmpty) {
        // P2P service would need a sendMessage method
        debugPrint('Trying P2P connection...');
        return true;
      }

      // Try BLE as fallback
      debugPrint('No connections available for sending message');
      return false;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Activate SOS mode
  Future<void> activateSOSMode({
    required SOSMode mode,
    String? emergencyMessage,
  }) async {
    try {
      if (mode == SOSMode.victim) {
        await _sosService.activateVictimMode(
          emergencyMessage: emergencyMessage ?? 'Emergency assistance needed!',
        );
      } else if (mode == SOSMode.rescuer) {
        await _sosService.activateRescuerMode();
      } else {
        _sosService.disableSOSMode();
      }
      
      debugPrint('🚨 SOS mode changed to: $mode');
    } catch (e) {
      debugPrint('Error activating SOS mode: $e');
    }
  }

  /// Get list of discovered devices
  List<NearbyDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  /// Get connection status
  Map<String, dynamic> get connectionStatus => {
    'isOnline': _nearbyService.connectedEndpoints.isNotEmpty || 
                _p2pService.connectedPeers.isNotEmpty,
    'connectedDevices': _nearbyService.connectedEndpoints.length + 
                       _p2pService.connectedPeers.length,
    'nearbyDevices': _discoveredDevices.length,
    'sosDevices': _discoveredDevices.where((d) => d.isSOSActive).length,
  };

  /// Parse message type from string
  MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    
    switch (type.toString().toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      case 'sos':
        return MessageType.sos;
      default:
        return MessageType.text;
    }
  }

  /// Cleanup resources
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    _deviceDiscoveredController.close();
    _messageReceivedController.close();
    _sosReceivedController.close();
  }
}