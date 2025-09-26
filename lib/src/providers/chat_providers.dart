import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/local_db_service.dart';
import '../services/chat_service.dart';
import '../services/service_coordinator.dart';

// Provider for accessing the local database service
final localDatabaseProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

// Provider for accessing the multimedia chat service
final multimediaChatProvider = Provider<MultimediaChatService>((ref) {
  return MultimediaChatService();
});

// Production-ready message stream provider using ServiceCoordinator
final realTimeMessageProvider = StreamProvider<ChatMessage>((ref) {
  final coordinator = ServiceCoordinator.instance;
  return coordinator.messageStream;
});

// Provider for chat messages for a specific participant 
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, participantId) async {
  final dbService = ref.watch(localDatabaseProvider);
  return await dbService.getMessagesForConversation(participantId);
});

// Provider for all messages (refreshes when new messages arrive)
final allMessagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final dbService = ref.watch(localDatabaseProvider);
  // Watch the real-time message provider to trigger refresh
  ref.watch(realTimeMessageProvider);
  return await dbService.getAllMessages();
});

// Provider for pending messages
final pendingMessagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final dbService = ref.watch(localDatabaseProvider);
  return await dbService.getPendingMessages();
});

// Enhanced connection status provider
final connectionStatusProvider = Provider<Map<String, bool>>((ref) {
  final coordinator = ServiceCoordinator.instance;
  return coordinator.getServiceStatus();
});

// Provider for message sending operations
final messageSendingProvider = NotifierProvider<MessageSendingNotifier, MessageSendingState>(() {
  return MessageSendingNotifier();
});

class MessageSendingState {
  final bool isSending;
  final String? error;
  final String? lastSentMessageId;

  const MessageSendingState({
    required this.isSending,
    this.error,
    this.lastSentMessageId,
  });

  MessageSendingState copyWith({
    bool? isSending,
    String? error,
    String? lastSentMessageId,
  }) {
    return MessageSendingState(
      isSending: isSending ?? this.isSending,
      error: error,
      lastSentMessageId: lastSentMessageId ?? this.lastSentMessageId,
    );
  }
}

class MessageSendingNotifier extends Notifier<MessageSendingState> {
  @override
  MessageSendingState build() {
    return const MessageSendingState(isSending: false);
  }
  
  final _coordinator = ServiceCoordinator.instance;
  final _dbService = LocalDatabaseService();
  
  Future<bool> sendMessage(ChatMessage message) async {
    state = state.copyWith(isSending: true, error: null);
    
    try {
      // Save to local database first
      await _dbService.insertMessage(message);
      
      // Send via ServiceCoordinator with fallback
      final success = await _coordinator.sendMessage(message);
      
      if (success) {
        state = state.copyWith(
          isSending: false,
          lastSentMessageId: message.id,
        );
        return true;
      } else {
        // Update status to failed but don't throw - it's queued for retry
        state = state.copyWith(
          isSending: false,
          error: 'Message queued for retry (no connection available)',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Failed to send message: $e',
      );
      return false;
    }
  }
  
  Future<void> broadcastSOS(String message, {double? latitude, double? longitude}) async {
    state = state.copyWith(isSending: true, error: null);
    
    try {
      await _coordinator.broadcastSOS(message, latitude: latitude, longitude: longitude);
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'SOS broadcast failed: $e',
      );
      rethrow;
    }
  }
}

// Provider for emergency message filtering
final emergencyMessagesProvider = Provider<AsyncValue<List<ChatMessage>>>((ref) {
  final messagesAsync = ref.watch(allMessagesProvider);
  return messagesAsync.when(
    data: (messages) => AsyncValue.data(
      messages.where((message) => message.isEmergency).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});