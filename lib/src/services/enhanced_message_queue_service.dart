// Simple message queue service for compatibility
import 'dart:async';
import '../models/enhanced_message_model.dart';

class MessageQueueService {
  static final MessageQueueService _instance = MessageQueueService._internal();
  static MessageQueueService get instance => _instance;
  MessageQueueService._internal();

  final List<ChatMessage> _messageQueue = [];
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;

  // Add message to queue
  void enqueueMessage(ChatMessage message) {
    _messageQueue.add(message);
    _messageController.add(message);
  }

  // Get next message from queue
  ChatMessage? dequeueMessage() {
    if (_messageQueue.isNotEmpty) {
      return _messageQueue.removeAt(0);
    }
    return null;
  }

  // Clear all messages
  void clearQueue() {
    _messageQueue.clear();
  }

  // Get queue size
  int get queueSize => _messageQueue.length;

  void dispose() {
    _messageController.close();
  }
}