import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/local_database_service.dart';
import '../services/multimedia_chat_service.dart';

// Provider for accessing the local database service
final localDatabaseProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

// Provider for accessing the multimedia chat service
final multimediaChatProvider = Provider<MultimediaChatService>((ref) {
  return MultimediaChatService();
});

// Provider for chat messages for a specific participant
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, participantId) async {
  final dbService = ref.watch(localDatabaseProvider);
  return await dbService.getMessagesForConversation(participantId);
});

// Provider for all messages
final allMessagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final dbService = ref.watch(localDatabaseProvider);
  return await dbService.getAllMessages();
});

// Provider for pending messages
final pendingMessagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final dbService = ref.watch(localDatabaseProvider);
  return await dbService.getPendingMessages();
});

// Provider for connection status
final connectionStatusProvider = Provider<bool>((ref) {
  return false; // Default to disconnected
});