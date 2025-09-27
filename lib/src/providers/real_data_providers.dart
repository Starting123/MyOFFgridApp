import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../models/user_model.dart';
import '../services/service_coordinator.dart';
import '../services/local_db_service.dart';
import '../services/auth_service.dart';
import '../services/sos_broadcast_service.dart';
import '../utils/logger.dart';

// ============================================================================
// REAL STREAM-BASED PROVIDERS (replacing static AppState)
// ============================================================================

/// Real nearby devices stream from ServiceCoordinator
final realNearbyDevicesStreamProvider = StreamProvider<List<NearbyDevice>>((ref) {
  final coordinator = ServiceCoordinator.instance;
  
  // Initialize if not already done
  if (!coordinator.isInitialized) {
    coordinator.initializeAll().catchError((e) {
      Logger.error('Failed to initialize ServiceCoordinator: $e');
      return false;
    });
  }
  
  return coordinator.deviceStream;
});

/// Real message stream from ServiceCoordinator
final realMessageStreamProvider = StreamProvider<ChatMessage>((ref) {
  final coordinator = ServiceCoordinator.instance;
  
  if (!coordinator.isInitialized) {
    coordinator.initializeAll().catchError((e) {
      Logger.error('Failed to initialize ServiceCoordinator: $e');
      return false;
    });
  }
  
  return coordinator.messageStream;
});

/// Real all messages stream from SQLite database
final realAllMessagesStreamProvider = StreamProvider<List<ChatMessage>>((ref) async* {
  final dbService = LocalDatabaseService();
  
  // Listen to new messages and refresh the list
  ref.listen(realMessageStreamProvider, (previous, next) {
    next.whenData((message) {
      Logger.info('New message received, refreshing all messages');
    });
  });
  
  // Initial load
  yield await dbService.getAllMessages();
  
  // Create a stream that emits periodically to check for new messages
  final controller = StreamController<List<ChatMessage>>();
  Timer? timer;
  
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  
  // Check for new messages every 5 seconds
  timer = Timer.periodic(const Duration(seconds: 5), (t) async {
    try {
      final messages = await dbService.getAllMessages();
      if (!controller.isClosed) {
        controller.add(messages);
      }
    } catch (e) {
      Logger.error('Error refreshing messages: $e');
    }
  });
  
  yield* controller.stream;
});

/// Real SOS status stream from SOSBroadcastService
final realSOSStatusStreamProvider = StreamProvider<bool>((ref) async* {
  final sosService = SOSBroadcastService.instance;
  
  // Initial status based on current mode
  yield sosService.currentMode == SOSMode.victim;
  
  // Listen to mode changes and emit status
  yield* sosService.onModeChanged.map((mode) => mode == SOSMode.victim);
});

/// Real user authentication stream
final realUserStreamProvider = StreamProvider<UserModel?>((ref) {
  return AuthService.instance.userStream;
});

/// Real connection status stream
final realConnectionStatusStreamProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final coordinator = ServiceCoordinator.instance;
  
  if (!coordinator.isInitialized) {
    yield {
      'isConnected': false,
      'connectionType': 'none',
      'activeServices': <String, bool>{},
    };
    
    await coordinator.initializeAll();
  }
  
  // Emit status periodically
  yield* Stream.periodic(const Duration(seconds: 3), (_) {
    final serviceStatus = coordinator.getServiceStatus();
    final hasActiveConnection = serviceStatus.values.any((isActive) => isActive);
    
    return {
      'isConnected': hasActiveConnection,
      'connectionType': _determineConnectionType(serviceStatus),
      'activeServices': serviceStatus,
    };
  });
});

String _determineConnectionType(Map<String, bool> serviceStatus) {
  if (serviceStatus['nearby'] == true) return 'nearby';
  if (serviceStatus['p2p'] == true) return 'p2p';
  if (serviceStatus['ble'] == true) return 'ble';
  if (serviceStatus['mesh'] == true) return 'mesh';
  return 'none';
}

// ============================================================================
// COMPUTED PROVIDERS FROM REAL STREAMS
// ============================================================================

/// SOS devices from real nearby devices stream
final realSOSDevicesProvider = Provider<AsyncValue<List<NearbyDevice>>>((ref) {
  return ref.watch(realNearbyDevicesStreamProvider).whenData(
    (devices) => devices.where((device) => device.isSOSActive).toList(),
  );
});

/// Rescuer devices from real nearby devices stream
final realRescuerDevicesProvider = Provider<AsyncValue<List<NearbyDevice>>>((ref) {
  return ref.watch(realNearbyDevicesStreamProvider).whenData(
    (devices) => devices.where((device) => device.isRescuerActive).toList(),
  );
});

/// Connected devices count from real stream
final realConnectedDevicesCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(realNearbyDevicesStreamProvider).whenData(
    (devices) => devices.where((device) => device.isConnected).length,
  );
});

/// Emergency mode status (derived from SOS or rescuer active)
final realEmergencyModeProvider = Provider<bool>((ref) {
  final sosStatus = ref.watch(realSOSStatusStreamProvider);
  final nearbyDevices = ref.watch(realNearbyDevicesStreamProvider);
  
  final isSosActive = sosStatus.value ?? false;
  final hasRescuerDevices = (nearbyDevices.value ?? [])
      .any((device) => device.isRescuerActive);
  
  return isSosActive || hasRescuerDevices;
});

// ============================================================================
// MESSAGE-SPECIFIC PROVIDERS
// ============================================================================

/// Real emergency messages from SQLite
final realEmergencyMessagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final dbService = LocalDatabaseService();
  
  // Refresh when new messages arrive
  ref.watch(realMessageStreamProvider);
  
  return await dbService.getEmergencyMessages();
});

/// Real pending messages from SQLite
final realPendingMessagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final dbService = LocalDatabaseService();
  
  // Refresh when new messages arrive
  ref.watch(realMessageStreamProvider);
  
  return await dbService.getPendingMessages();
});

/// Real conversation messages for a specific participant
final realConversationMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, participantId) async {
  final dbService = LocalDatabaseService();
  
  // Refresh when new messages arrive
  ref.watch(realMessageStreamProvider);
  
  return await dbService.getMessagesForConversation(participantId);
});

// ============================================================================
// ACTIONS AND UTILITIES
// ============================================================================

/// Provider for real message sending actions
final realMessageActionsProvider = Provider<RealMessageActions>((ref) {
  return RealMessageActions();
});

class RealMessageActions {
  final _coordinator = ServiceCoordinator.instance;
  final _dbService = LocalDatabaseService();
  
  /// Send a text message through real services
  Future<bool> sendTextMessage({
    required String receiverId,
    required String receiverName,
    required String content,
    bool isEmergency = false,
  }) async {
    try {
      // Get current user from AuthService
      final currentUser = AuthService.instance.currentUser;
      final senderId = currentUser?.id ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
      final senderName = currentUser?.name ?? 'Anonymous User';
      
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        content: content,
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isEmergency: isEmergency,
      );
      
      // Store in local database first
      await _dbService.insertMessage(message);
      
      // Send through service coordinator
      final success = await _coordinator.sendMessage(message);
      
      // Update status based on result
      final updatedMessage = message.copyWith(
        status: success ? MessageStatus.sent : MessageStatus.failed,
      );
      await _dbService.insertMessage(updatedMessage);
      
      return success;
    } catch (e) {
      Logger.error('Failed to send message: $e');
      return false;
    }
  }
  
  /// Broadcast SOS signal through real services
  Future<void> broadcastSOS({
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _coordinator.broadcastSOS(
        message,
        latitude: latitude,
        longitude: longitude,
      );
      Logger.info('SOS broadcast sent successfully');
    } catch (e) {
      Logger.error('Failed to broadcast SOS: $e');
      rethrow;
    }
  }
  
  /// Connect to a device through real services
  Future<bool> connectToDevice(String deviceId) async {
    try {
      return await _coordinator.connectToDevice(deviceId);
    } catch (e) {
      Logger.error('Failed to connect to device $deviceId: $e');
      return false;
    }
  }
}

// ============================================================================
// COMPATIBILITY LAYER (for easy migration)
// ============================================================================

/// Compatibility providers that map old names to new implementations
final nearbyDevicesProvider = Provider<AsyncValue<List<NearbyDevice>>>((ref) {
  return ref.watch(realNearbyDevicesStreamProvider);
});

final messagesProvider = Provider<AsyncValue<List<ChatMessage>>>((ref) {
  return ref.watch(realAllMessagesStreamProvider);
});

final connectionStatusProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(realConnectionStatusStreamProvider).whenData(
    (status) => status['isConnected'] as bool,
  );
});

final sosActiveModeProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(realSOSStatusStreamProvider);
});