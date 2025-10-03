import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/local_db_service.dart';
import '../services/encryption_service.dart';
import '../services/nearby_service_fixed.dart';
import '../services/p2p_service.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../services/service_coordinator.dart';
import '../services/sos_broadcast_service.dart';
import '../utils/logger.dart';
import 'real_data_providers.dart';

// ============================================================================
// CORE SERVICE PROVIDERS - SINGLETONS
// ============================================================================

final databaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService.instance;
});

final nearbyServiceProvider = Provider<NearbyService>((ref) {
  return NearbyService.instance;
});

final p2pServiceProvider = Provider<P2PService>((ref) {
  return P2PService.instance;
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

final multimediaChatServiceProvider = Provider<MultimediaChatService>((ref) {
  return MultimediaChatService();
});

// NEW: Real service providers (replacing static AppState)
final serviceCoordinatorProvider = Provider<ServiceCoordinator>((ref) {
  return ServiceCoordinator.instance;
});

final sosBroadcastServiceProvider = Provider<SOSBroadcastService>((ref) {
  return SOSBroadcastService.instance;
});

// ============================================================================
// STREAM-BASED STATE MANAGEMENT (Replacing Static AppState)
// ============================================================================

/* COMMENTED OUT: OLD STATIC APPSTATE APPROACH
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

  // COMMENTED OUT: OLD STATIC STATE MODIFIERS
  // State modifiers
  static void setSosActive(bool active) { ... }
  static void setRescuerActive(bool active) { ... }
  static void setConnectionStatus(bool status, [String? type]) { ... }
  static void setNearbyDevices(List<NearbyDevice> devices) { ... }
  static void addNearbyDevice(NearbyDevice device) { ... }
  static void removeNearbyDevice(String deviceId) { ... }
  static void addMessage(ChatMessage message) { ... }
  static void setMessages(List<ChatMessage> messages) { ... }
  static void setCurrentConversation(String? conversationId) { ... }
}
*/

// ============================================================================
// NEW: REAL STREAM-BASED PROVIDERS
// ============================================================================

// SOS Status from real SOSBroadcastService
final sosActiveModeProvider = StreamProvider<bool>((ref) async* {
  final sosService = ref.read(sosBroadcastServiceProvider);
  yield sosService.currentMode == SOSMode.victim;
  yield* sosService.onModeChanged.map((mode) => mode == SOSMode.victim);
});

final rescuerActiveModeProvider = StreamProvider<bool>((ref) async* {
  final sosService = ref.read(sosBroadcastServiceProvider);
  yield sosService.currentMode == SOSMode.rescuer;
  yield* sosService.onModeChanged.map((mode) => mode == SOSMode.rescuer);
});

// Device Role from SOS status
final currentRoleProvider = Provider<DeviceRole>((ref) {
  final sosAsync = ref.watch(sosActiveModeProvider);
  final rescuerAsync = ref.watch(rescuerActiveModeProvider);
  
  final sosActive = sosAsync.value ?? false;
  final rescuerActive = rescuerAsync.value ?? false;
  
  if (sosActive) return DeviceRole.sosUser;
  if (rescuerActive) return DeviceRole.rescuer;
  return DeviceRole.normal;
});

// Connection Status from ServiceCoordinator
final connectionStatusProvider = StreamProvider<bool>((ref) async* {
  final coordinator = ref.read(serviceCoordinatorProvider);
  if (!coordinator.isInitialized) {
    await coordinator.initializeAll();
  }
  
  yield* Stream.periodic(const Duration(seconds: 2), (_) {
    final serviceStatus = coordinator.getServiceStatus();
    return serviceStatus.values.any((isActive) => isActive);
  });
});

final connectionTypeProvider = StreamProvider<String>((ref) async* {
  final coordinator = ref.read(serviceCoordinatorProvider);
  if (!coordinator.isInitialized) {
    await coordinator.initializeAll();
  }
  
  yield* Stream.periodic(const Duration(seconds: 2), (_) {
    final serviceStatus = coordinator.getServiceStatus();
    if (serviceStatus['wifiDirect'] == true) return 'wifiDirect';
    if (serviceStatus['nearby'] == true) return 'nearby';
    if (serviceStatus['p2p'] == true) return 'p2p';
    if (serviceStatus['ble'] == true) return 'ble';
    return 'none';
  });
});

// Device lists from real streams (using real_data_providers.dart)
final nearbyDevicesProvider = Provider<AsyncValue<List<NearbyDevice>>>((ref) {
  return ref.watch(realNearbyDevicesStreamProvider);
});

final messagesProvider = Provider<AsyncValue<List<ChatMessage>>>((ref) {
  return ref.watch(realAllMessagesStreamProvider);
});

// Current conversation state
class CurrentConversationNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void setCurrentConversation(String? conversationId) {
    state = conversationId;
  }
}

final currentConversationProvider = NotifierProvider<CurrentConversationNotifier, String?>(
  () => CurrentConversationNotifier(),
);

// ============================================================================
// COMPUTED PROVIDERS
// ============================================================================

final emergencyModeProvider = Provider<bool>((ref) {
  final sosAsync = ref.watch(sosActiveModeProvider);
  final rescuerAsync = ref.watch(rescuerActiveModeProvider);
  
  final sosActive = sosAsync.value ?? false;
  final rescuerActive = rescuerAsync.value ?? false;
  
  return sosActive || rescuerActive;
});

final sosDevicesProvider = Provider<List<NearbyDevice>>((ref) {
  final nearbyDevicesAsync = ref.watch(nearbyDevicesProvider);
  return nearbyDevicesAsync.when(
    data: (devices) => devices.where((device) => device.isSOSActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final rescuerDevicesProvider = Provider<List<NearbyDevice>>((ref) {
  final nearbyDevicesAsync = ref.watch(nearbyDevicesProvider);
  return nearbyDevicesAsync.when(
    data: (devices) => devices.where((device) => device.isRescuerActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final connectedDevicesCountProvider = Provider<int>((ref) {
  final nearbyDevicesAsync = ref.watch(nearbyDevicesProvider);
  return nearbyDevicesAsync.when(
    data: (devices) => devices.where((device) => device.isConnected).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
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
final realConnectionStatusProvider = Provider<AsyncValue<bool>>((ref) => ref.watch(connectionStatusProvider));
final realConnectionTypeProvider = Provider<AsyncValue<String>>((ref) => ref.watch(connectionTypeProvider));
final realNearbyDevicesProvider = Provider<List<NearbyDevice>>((ref) {
  final nearbyDevicesAsync = ref.watch(nearbyDevicesProvider);
  return nearbyDevicesAsync.when(
    data: (devices) => devices,
    loading: () => [],
    error: (_, __) => [],
  );
});
final realSOSModeProvider = Provider<bool>((ref) {
  final sosAsync = ref.watch(sosActiveModeProvider);
  return sosAsync.value ?? false;
});
final realRescuerModeProvider = Provider<bool>((ref) {
  final rescuerAsync = ref.watch(rescuerActiveModeProvider);
  return rescuerAsync.value ?? false;
});

// Chat state for complex screens
final chatStateProvider = Provider<ChatState>((ref) {
  final messagesAsync = ref.watch(messagesProvider);
  final currentConversation = ref.watch(currentConversationProvider);
  final nearbyDevicesAsync = ref.watch(nearbyDevicesProvider);
  final connectionAsync = ref.watch(connectionStatusProvider);
  
  final messages = messagesAsync.when(
    data: (msgs) => msgs,
    loading: () => <ChatMessage>[],
    error: (_, __) => <ChatMessage>[],
  );
  
  final nearbyDevices = nearbyDevicesAsync.when(
    data: (devices) => devices,
    loading: () => <NearbyDevice>[],
    error: (_, __) => <NearbyDevice>[],
  );
  
  final isConnected = connectionAsync.value ?? false;
  
  return ChatState(
    messages: messages,
    currentConversationId: currentConversation,
    nearbyDevices: nearbyDevices,
    isConnected: isConnected,
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
// NEW: REAL ACTION CLASSES (replacing static AppState methods)
// ============================================================================

class AppActions {
  // SOS Actions using real services
  static Future<void> activateSOS(WidgetRef ref) async {
    try {
      final sosService = ref.read(sosBroadcastServiceProvider);
      await sosService.activateVictimMode(emergencyMessage: 'EMERGENCY SOS: Immediate assistance required!');
      Logger.info('🚨 SOS Mode Activated via SOSBroadcastService');
    } catch (e) {
      Logger.error('Failed to activate SOS: $e');
    }
  }

  static Future<void> deactivateSOS(WidgetRef ref) async {
    try {
      final sosService = ref.read(sosBroadcastServiceProvider);
      sosService.disableSOSMode();
      Logger.info('✅ SOS Mode Deactivated');
    } catch (e) {
      Logger.error('Failed to deactivate SOS: $e');
    }
  }

  // Rescuer Actions
  static Future<void> activateRescuer(WidgetRef ref) async {
    try {
      final sosService = ref.read(sosBroadcastServiceProvider);
      await sosService.activateRescuerMode();
      Logger.info('🛡️ Rescuer Mode Activated');
    } catch (e) {
      Logger.error('Failed to activate rescuer mode: $e');
    }
  }

  static Future<void> deactivateRescuer(WidgetRef ref) async {
    try {
      final sosService = ref.read(sosBroadcastServiceProvider);
      sosService.disableSOSMode();
      Logger.info('✅ Rescuer Mode Deactivated');
    } catch (e) {
      Logger.error('Failed to deactivate rescuer mode: $e');
    }
  }

  // Device Discovery Actions
  static Future<void> startDiscovery(WidgetRef ref) async {
    try {
      final coordinator = ref.read(serviceCoordinatorProvider);
      await coordinator.initializeAll();
      Logger.info('🔍 Device discovery started');
    } catch (e) {
      Logger.error('Failed to start discovery: $e');
    }
  }

  static Future<void> stopDiscovery(WidgetRef ref) async {
    try {
      // ServiceCoordinator handles stopping discovery automatically
      Logger.info('⏹️ Discovery stopped successfully');
    } catch (e) {
      Logger.error('❌ Error stopping discovery: $e');
    }
  }

  // Message Actions using real services
  static Future<void> broadcastSOS(WidgetRef ref, {
    String emergencyType = 'general',
    String emergencyMessage = 'SOS EMERGENCY - Need immediate help!',
    double? latitude,
    double? longitude,
  }) async {
    try {
      final coordinator = ref.read(serviceCoordinatorProvider);
      await coordinator.broadcastSOS(emergencyMessage, latitude: latitude, longitude: longitude);
      Logger.info('🚨 SOS broadcast sent via ServiceCoordinator');
    } catch (e) {
      Logger.error('Failed to broadcast SOS: $e');
    }
  }

  static Future<void> sendMessage(WidgetRef ref, String deviceId, String content) async {
    try {
      final coordinator = ref.read(serviceCoordinatorProvider);
      
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_device',
        senderName: 'Me',
        receiverId: deviceId,
        content: content,
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isEmergency: false,
      );

      await coordinator.sendMessage(message);
      Logger.info('📤 Message sent via ServiceCoordinator');
    } catch (e) {
      Logger.error('Failed to send message: $e');
    }
  }

  // Connection Actions
  static Future<void> connectToDevice(WidgetRef ref, String deviceId) async {
    try {
      final coordinator = ref.read(serviceCoordinatorProvider);
      await coordinator.connectToDevice(deviceId);
      Logger.info('🔗 Connected to device: $deviceId');
    } catch (e) {
      Logger.error('Failed to connect to device: $e');
    }
  }
}

/* COMMENTED OUT: OLD STATIC APPSTATE METHODS
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
    debugPrint('🛡️ Rescuer Mode Activated');
  }

  static void deactivateRescuer(WidgetRef ref) {
    AppState.setRescuerActive(false);
    debugPrint('✅ Rescuer Mode Deactivated');
  }

  // Device Discovery Actions
  static Future<void> startDiscovery(WidgetRef ref) async {
    // ... old implementation
  }

  static Future<void> stopDiscovery(WidgetRef ref) async {
    // ... old implementation
  }

  static Future<void> broadcastSOS(WidgetRef ref, {...}) async {
    // ... old implementation using static lists
  }

  static Future<void> sendMessage(WidgetRef ref, String deviceId, String content) async {
    // ... old implementation using static lists
  }

  static Future<void> connectToDevice(WidgetRef ref, String deviceId) async {
    // ... old implementation
  }
}
*/