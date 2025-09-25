import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/multimedia_chat_service.dart';
import '../services/local_database_service.dart';
import '../services/encryption_service.dart';
import '../services/enhanced_cloud_sync.dart';
import '../services/nearby_service.dart';
import '../services/p2p_service.dart';

// ============================================================================
// CORE SERVICE PROVIDERS - SINGLETONS
// ============================================================================

final databaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService.instance;
});

final cloudSyncServiceProvider = Provider<EnhancedCloudSync>((ref) {
  return EnhancedCloudSync.instance;
});

final nearbyServiceProvider = Provider<NearbyService>((ref) {
  return NearbyService.instance;
});

final p2pServiceProvider = Provider<P2PService>((ref) {
  return P2PService.instance;
});

final multimediaChatServiceProvider = Provider<MultimediaChatService>((ref) {
  return MultimediaChatService();
});

// ============================================================================
// GLOBAL STATE MANAGEMENT
// ============================================================================

class AppState {
  static bool _sosActive = false;
  static bool _rescuerActive = false;
  static DeviceRole _currentRole = DeviceRole.normal;
  static bool _connectionStatus = false;
  static String _connectionType = 'none';
  static List<NearbyDevice> _nearbyDevices = [];
  static List<ChatMessage> _messages = [];
  static String? _currentConversation;

  // State change notifier
  static final List<VoidCallback> _listeners = [];
  static void addListener(VoidCallback listener) => _listeners.add(listener);
  static void removeListener(VoidCallback listener) => _listeners.remove(listener);
  static void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('Error in state listener: $e');
      }
    }
  }

  // Getters
  static bool get sosActive => _sosActive;
  static bool get rescuerActive => _rescuerActive;
  static DeviceRole get currentRole => _currentRole;
  static bool get connectionStatus => _connectionStatus;
  static String get connectionType => _connectionType;
  static List<NearbyDevice> get nearbyDevices => List.unmodifiable(_nearbyDevices);
  static List<ChatMessage> get messages => List.unmodifiable(_messages);
  static String? get currentConversation => _currentConversation;
  static bool get emergencyMode => _sosActive || _rescuerActive;

  // State modifiers
  static void setSosActive(bool active) {
    _sosActive = active;
    if (active) {
      _currentRole = DeviceRole.sosUser;
    } else if (!_rescuerActive) {
      _currentRole = DeviceRole.normal;
    }
    _notifyListeners();
  }

  static void setRescuerActive(bool active) {
    _rescuerActive = active;
    if (active) {
      _currentRole = DeviceRole.rescuer;
    } else if (!_sosActive) {
      _currentRole = DeviceRole.normal;
    }
    _notifyListeners();
  }

  static void setConnectionStatus(bool status, [String? type]) {
    _connectionStatus = status;
    if (type != null) _connectionType = type;
    _notifyListeners();
  }

  static void setNearbyDevices(List<NearbyDevice> devices) {
    _nearbyDevices = devices;
    _notifyListeners();
  }

  static void addNearbyDevice(NearbyDevice device) {
    final existingIndex = _nearbyDevices.indexWhere((d) => d.id == device.id);
    if (existingIndex >= 0) {
      _nearbyDevices[existingIndex] = device;
    } else {
      _nearbyDevices.add(device);
    }
    _notifyListeners();
  }

  static void removeNearbyDevice(String deviceId) {
    _nearbyDevices.removeWhere((device) => device.id == deviceId);
    _notifyListeners();
  }

  static void addMessage(ChatMessage message) {
    _messages.add(message);
    _notifyListeners();
  }

  static void setMessages(List<ChatMessage> messages) {
    _messages = messages;
    _notifyListeners();
  }

  static void setCurrentConversation(String? conversationId) {
    _currentConversation = conversationId;
    _notifyListeners();
  }
}

// ============================================================================
// STATE NOTIFIER FOR PROVIDERS
// ============================================================================

class _StateChangeNotifier {
  static int _counter = 0;
  static final List<VoidCallback> _providerListeners = [];

  static void initialize() {
    AppState.addListener(() {
      _counter++;
      for (final listener in _providerListeners) {
        listener();
      }
    });
  }



  static int get counter => _counter;
}

// Initialize the notifier
final _initProvider = Provider<bool>((ref) {
  _StateChangeNotifier.initialize();
  return true;
});

// Counter provider that changes when state changes
final _stateCounterProvider = Provider<int>((ref) {
  ref.watch(_initProvider); // Ensure initialization
  return _StateChangeNotifier.counter;
});

// ============================================================================
// MAIN STATE PROVIDERS
// ============================================================================

final sosActiveModeProvider = Provider<bool>((ref) {
  ref.watch(_stateCounterProvider); // Listen to state changes
  return AppState.sosActive;
});

final rescuerActiveModeProvider = Provider<bool>((ref) {
  ref.watch(_stateCounterProvider);
  return AppState.rescuerActive;
});

final currentDeviceRoleProvider = Provider<DeviceRole>((ref) {
  ref.watch(_stateCounterProvider);
  return AppState.currentRole;
});

final connectionStatusProvider = Provider<bool>((ref) {
  ref.watch(_stateCounterProvider);
  return AppState.connectionStatus;
});

final connectionTypeProvider = Provider<String>((ref) {
  ref.watch(_stateCounterProvider);
  return AppState.connectionType;
});

final nearbyDevicesProvider = Provider<List<NearbyDevice>>((ref) {
  ref.watch(_stateCounterProvider);
  return AppState.nearbyDevices;
});

final messagesProvider = Provider<List<ChatMessage>>((ref) {
  ref.watch(_stateCounterProvider);
  return AppState.messages;
});

final currentConversationProvider = Provider<String?>((ref) {
  ref.watch(_stateCounterProvider);
  return AppState.currentConversation;
});

// ============================================================================
// COMPUTED PROVIDERS
// ============================================================================

final emergencyModeProvider = Provider<bool>((ref) {
  ref.watch(_stateCounterProvider);
  return AppState.emergencyMode;
});

final sosDevicesProvider = Provider<List<NearbyDevice>>((ref) {
  final nearbyDevices = ref.watch(nearbyDevicesProvider);
  return nearbyDevices.where((device) => device.isSOSActive).toList();
});

final rescuerDevicesProvider = Provider<List<NearbyDevice>>((ref) {
  final nearbyDevices = ref.watch(nearbyDevicesProvider);
  return nearbyDevices.where((device) => device.isRescuerActive).toList();
});

final connectedDevicesCountProvider = Provider<int>((ref) {
  final nearbyDevices = ref.watch(nearbyDevicesProvider);
  return nearbyDevices.where((device) => device.isConnected).length;
});

// ============================================================================
// ASYNC DATA PROVIDERS
// ============================================================================

final emergencyMessagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  return await dbService.getEmergencyMessages();
});

final pendingMessagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  return await dbService.getPendingMessages();
});

// ============================================================================
// COMPATIBILITY PROVIDERS (for existing screens)
// ============================================================================

// Legacy names for backward compatibility
final realConnectionStatusProvider = Provider<bool>((ref) => ref.watch(connectionStatusProvider));
final realConnectionTypeProvider = Provider<String>((ref) => ref.watch(connectionTypeProvider));
final realNearbyDevicesProvider = Provider<List<NearbyDevice>>((ref) => ref.watch(nearbyDevicesProvider));
final realSOSModeProvider = Provider<bool>((ref) => ref.watch(sosActiveModeProvider));
final realRescuerModeProvider = Provider<bool>((ref) => ref.watch(rescuerActiveModeProvider));

// Chat state for complex screens
final chatStateProvider = Provider<ChatState>((ref) {
  final messages = ref.watch(messagesProvider);
  final currentConversation = ref.watch(currentConversationProvider);
  final nearbyDevices = ref.watch(nearbyDevicesProvider);
  
  return ChatState(
    messages: messages,
    currentConversationId: currentConversation,
    nearbyDevices: nearbyDevices,
    isConnected: ref.watch(connectionStatusProvider),
    emergencyMode: ref.watch(emergencyModeProvider),
  );
});

class ChatState {
  final List<ChatMessage> messages;
  final String? currentConversationId;
  final List<NearbyDevice> nearbyDevices;
  final bool isConnected;
  final bool emergencyMode;

  const ChatState({
    required this.messages,
    this.currentConversationId,
    required this.nearbyDevices,
    required this.isConnected,
    required this.emergencyMode,
  });
}

// ============================================================================
// ACTION CLASSES
// ============================================================================

class AppActions {
  // SOS Actions
  static void activateSOS(WidgetRef ref) {
    AppState.setSosActive(true);
    debugPrint('🚨 SOS Mode Activated');
  }

  static void deactivateSOS(WidgetRef ref) {
    AppState.setSosActive(false);
    debugPrint('✅ SOS Mode Deactivated');
  }

  // Rescuer Actions
  static void activateRescuer(WidgetRef ref) {
    AppState.setRescuerActive(true);
    debugPrint('🚑 Rescuer Mode Activated');
  }

  static void deactivateRescuer(WidgetRef ref) {
    AppState.setRescuerActive(false);
    debugPrint('✅ Rescuer Mode Deactivated');
  }

  // Device Management
  static void updateNearbyDevices(WidgetRef ref, List<NearbyDevice> devices) {
    AppState.setNearbyDevices(devices);
  }

  static void addNearbyDevice(WidgetRef ref, NearbyDevice device) {
    AppState.addNearbyDevice(device);
  }

  static void removeNearbyDevice(WidgetRef ref, String deviceId) {
    AppState.removeNearbyDevice(deviceId);
  }

  // Connection Management
  static void updateConnectionStatus(WidgetRef ref, {bool? isConnected, String? connectionType}) {
    if (isConnected != null) {
      AppState.setConnectionStatus(isConnected, connectionType);
    }
  }

  // Message Management
  static void addMessage(WidgetRef ref, ChatMessage message) {
    AppState.addMessage(message);
  }

  static void setCurrentConversation(WidgetRef ref, String? conversationId) {
    AppState.setCurrentConversation(conversationId);
  }

  // Discovery and Communication
  static Future<void> startDiscovery(WidgetRef ref) async {
    try {
      final nearbyService = ref.read(nearbyServiceProvider);
      final p2pService = ref.read(p2pServiceProvider);

      await nearbyService.initialize();
      await p2pService.initialize();

      await nearbyService.startDiscovery();
      await p2pService.startDiscovery();

      updateConnectionStatus(ref, isConnected: true, connectionType: 'discovering');
      debugPrint('🔍 Discovery started successfully');
    } catch (e) {
      debugPrint('❌ Error starting discovery: $e');
      updateConnectionStatus(ref, isConnected: false, connectionType: 'error');
    }
  }

  static Future<void> stopDiscovery(WidgetRef ref) async {
    try {
      final nearbyService = ref.read(nearbyServiceProvider);
      final p2pService = ref.read(p2pServiceProvider);

      await nearbyService.stopDiscovery();
      await p2pService.stopDiscovery();

      updateConnectionStatus(ref, isConnected: false, connectionType: 'none');
      debugPrint('⏹️ Discovery stopped successfully');
    } catch (e) {
      debugPrint('❌ Error stopping discovery: $e');
    }
  }

  static Future<void> broadcastSOS(WidgetRef ref, {
    String emergencyType = 'general',
    String emergencyMessage = 'SOS EMERGENCY - Need immediate help!',
    double? latitude,
    double? longitude,
  }) async {
    // Create SOS message for local storage
    final sosMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_device',
      senderName: 'Emergency User',
      receiverId: 'broadcast',
      content: 'SOS EMERGENCY: $emergencyType - $emergencyMessage',
      type: MessageType.sos,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      isEmergency: true,
    );

    try {
      // Activate SOS mode
      activateSOS(ref);
      
      // Add to local message state
      addMessage(ref, sosMessage);
      
      // Save to database with pending status
      final dbService = ref.read(databaseServiceProvider);
      await dbService.insertPendingMessage(sosMessage);

      // Create serialized SOS payload
      final sosPayload = {
        'type': 'sos_broadcast',
        'id': sosMessage.id,
        'emergencyType': emergencyType,
        'message': emergencyMessage,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': 'current_device',
        'batteryLevel': 85, // Mock battery level
      };

      // Serialize payload to JSON string
      final serializedPayload = jsonEncode(sosPayload);

      // Start services
      final nearbyService = ref.read(nearbyServiceProvider);
      final p2pService = ref.read(p2pServiceProvider);
      
      await nearbyService.initialize();
      await p2pService.initialize();
      
      // Start advertising as emergency device
      await nearbyService.startAdvertising('SOS_EMERGENCY');
      
      // Broadcast SOS via multiple channels
      await Future.wait([
        nearbyService.broadcastSOS(
          deviceId: 'current_device',
          message: serializedPayload,
          additionalData: sosPayload,
        ),
        nearbyService.sendMessage(serializedPayload, type: 'sos_broadcast'),
      ]);

      // Start discovery to find rescuers
      await startDiscovery(ref);

      // Mark message as sent
      await dbService.updateMessageStatus(sosMessage.id, MessageStatus.sent);

      debugPrint('🚨 SOS broadcasted successfully with payload:');
      debugPrint('📡 $serializedPayload');
      debugPrint('🔍 Discovery started to find rescuers');
      
    } catch (e) {
      debugPrint('❌ Error broadcasting SOS: $e');
      // Mark message as failed in database
      final dbService = ref.read(databaseServiceProvider);
      await dbService.updateMessageStatus(sosMessage.id, MessageStatus.failed);
      
      final failedMessage = sosMessage.copyWith(status: MessageStatus.failed);
      addMessage(ref, failedMessage);
    }
  }

  static Future<void> sendTextMessage(WidgetRef ref, String conversationId, String content) async {
    try {
      // Check if message should be encrypted
      final encryptionService = ref.read(encryptionServiceProvider);
      String finalContent = content;
      bool isEncrypted = false;

      // Only encrypt if not in emergency mode and we have encryption key for recipient
      if (!AppState.emergencyMode && encryptionService.canEncryptForPeer(conversationId)) {
        finalContent = encryptionService.encryptMessage(content, conversationId);
        isEncrypted = true;
      }

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_device',
        senderName: 'Me',
        receiverId: conversationId,
        content: finalContent,
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isEmergency: AppState.emergencyMode,
        metadata: isEncrypted ? {'encrypted': true} : null,
      );

      addMessage(ref, message);

      // Save to database as pending
      final dbService = ref.read(databaseServiceProvider);
      await dbService.insertPendingMessage(message);

      // Send via nearby service
      final nearbyService = ref.read(nearbyServiceProvider);
      final messagePayload = {
        'type': 'text_message',
        'id': message.id,
        'content': finalContent,
        'senderId': 'current_device',
        'timestamp': DateTime.now().toIso8601String(),
        'isEmergency': AppState.emergencyMode,
        'isEncrypted': isEncrypted,
      };

      await nearbyService.sendMessage(jsonEncode(messagePayload), type: 'chat');

      // Mark as sent
      await dbService.updateMessageStatus(message.id, MessageStatus.sent);

      debugPrint('📤 Text message sent successfully (encrypted: $isEncrypted)');
    } catch (e) {
      debugPrint('❌ Error sending text message: $e');
    }
  }

  static Future<void> syncToCloud(WidgetRef ref) async {
    try {
      final cloudSync = ref.read(cloudSyncServiceProvider);
      await cloudSync.uploadPending();
      debugPrint('☁️ Cloud sync completed successfully');
    } catch (e) {
      debugPrint('❌ Error syncing to cloud: $e');
    }
  }

  // Device Discovery and Connection
  static Future<List<NearbyDevice>> discoverDevices(WidgetRef ref) async {
    try {
      final nearbyService = ref.read(nearbyServiceProvider);
      final p2pService = ref.read(p2pServiceProvider);

      // Initialize services if not already done
      await nearbyService.initialize();
      await p2pService.initialize();

      // Start discovery
      await nearbyService.startDiscovery();
      await p2pService.startDiscovery();

      updateConnectionStatus(ref, isConnected: true, connectionType: 'discovering');

      // Return current nearby devices (will be updated via streams)
      return AppState.nearbyDevices;
    } catch (e) {
      debugPrint('❌ Error discovering devices: $e');
      updateConnectionStatus(ref, isConnected: false, connectionType: 'error');
      return [];
    }
  }

  static Future<bool> connectToDevice(WidgetRef ref, String deviceId, {String? deviceName}) async {
    try {
      final nearbyService = ref.read(nearbyServiceProvider);
      
      // Find the device in nearby devices
      final device = AppState.nearbyDevices.firstWhere(
        (device) => device.id == deviceId,
        orElse: () => NearbyDevice(
          id: deviceId,
          name: deviceName ?? 'Unknown Device',
          role: DeviceRole.normal,
          isSOSActive: false,
          isRescuerActive: false,
          lastSeen: DateTime.now(),
          signalStrength: 0,
          isConnected: false,
          connectionType: 'nearby',
        ),
      );

      // Attempt connection via Nearby Connections
      final connectionSuccess = await nearbyService.connectToEndpoint(deviceId);
      
      if (connectionSuccess) {
        // Update device as connected
        final connectedDevice = device.copyWith(
          isConnected: true,
          connectionType: 'nearby_connected',
          lastSeen: DateTime.now(),
        );
        
        // Update devices list
        final updatedDevices = AppState.nearbyDevices.map((d) => 
          d.id == deviceId ? connectedDevice : d
        ).toList();
        
        updateNearbyDevices(ref, updatedDevices);
        updateConnectionStatus(ref, isConnected: true, connectionType: 'nearby_connected');
        
        debugPrint('✅ Connected to device: $deviceId');
        return true;
      } else {
        debugPrint('❌ Failed to connect to device: $deviceId');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error connecting to device $deviceId: $e');
      return false;
    }
  }

  static Future<void> disconnectFromDevice(WidgetRef ref, String deviceId) async {
    try {
      final nearbyService = ref.read(nearbyServiceProvider);
      
      // Disconnect via Nearby Connections
      await nearbyService.disconnectFromEndpoint(deviceId);
      
      // Update device as disconnected
      final updatedDevices = AppState.nearbyDevices.map((device) {
        if (device.id == deviceId) {
          return device.copyWith(
            isConnected: false,
            connectionType: 'nearby',
          );
        }
        return device;
      }).toList();
      
      updateNearbyDevices(ref, updatedDevices);
      
      // Check if any devices are still connected
      final hasConnectedDevices = updatedDevices.any((device) => device.isConnected);
      if (!hasConnectedDevices) {
        updateConnectionStatus(ref, isConnected: false, connectionType: 'none');
      }
      
      debugPrint('🔌 Disconnected from device: $deviceId');
    } catch (e) {
      debugPrint('❌ Error disconnecting from device $deviceId: $e');
    }
  }

  static Future<void> initializeApp(WidgetRef ref) async {
    try {
      final nearbyService = ref.read(nearbyServiceProvider);
      final p2pService = ref.read(p2pServiceProvider);
      
      await Future.wait([
        nearbyService.initialize(),
        p2pService.initialize(),
      ]);

      debugPrint('🚀 App initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing app: $e');
    }
  }
}

// Legacy compatibility
class AppProviders extends AppActions {}

// Chat actions provider
final chatActionsProvider = Provider<ChatActions>((ref) => ChatActions());

class ChatActions {
  Future<void> sendTextMessage(String conversationId, String content) async {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_device',
      senderName: 'Me',
      receiverId: conversationId,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      isEmergency: AppState.emergencyMode,
    );

    AppState.addMessage(message);
    debugPrint('📤 Message added to state');
  }

  Future<void> sendImageMessage(String conversationId, String imagePath) async {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_device',
      senderName: 'Me',
      receiverId: conversationId,
      content: 'Image',
      type: MessageType.image,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      filePath: imagePath,
      isEmergency: AppState.emergencyMode,
    );

    AppState.addMessage(message);
    debugPrint('📤 Image message added to state');
  }

  Future<void> sendLocationMessage(String conversationId, double lat, double lng) async {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_device',
      senderName: 'Me',
      receiverId: conversationId,
      content: 'Location shared',
      type: MessageType.location,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      latitude: lat,
      longitude: lng,
      isEmergency: AppState.emergencyMode,
    );

    AppState.addMessage(message);
    debugPrint('📤 Location message added to state');
  }

  Future<void> sendSOSMessage(String conversationId) async {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_device',
      senderName: 'Emergency User',
      receiverId: conversationId,
      content: 'SOS EMERGENCY!',
      type: MessageType.sos,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      isEmergency: true,
    );

    AppState.addMessage(message);
    debugPrint('🚨 SOS message added to state');
  }
}