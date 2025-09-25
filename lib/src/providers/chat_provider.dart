import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/nearby_service.dart';

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isConnected;
  final String? currentPeerName;
  final String? error;
  
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.currentPeerName,
    this.error,
  });
  
  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isConnected,
    String? currentPeerName,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      currentPeerName: currentPeerName ?? this.currentPeerName,
      error: error ?? this.error,
    );
  }
}

class ChatNotifier extends AsyncNotifier<ChatState> {
  final NearbyService _nearbyService = NearbyService.instance;
  StreamSubscription? _messageSubscription;


  @override
  Future<ChatState> build() async {
    // Listen to incoming messages
    _messageSubscription = _nearbyService.onMessageReceived.listen(_handleIncomingMessage);
    
    // Check if there are connected endpoints
    final bool hasConnections = _nearbyService.connectedEndpoints.isNotEmpty;
    
    return ChatState(
      isConnected: hasConnections, 
      currentPeerName: hasConnections ? 'Connected Device' : 'No Connection'
    );
  }
  
  void _handleIncomingMessage(String message) {
    print('🔥 ChatProvider received message: $message');
    final currentState = state.value ?? const ChatState();
    
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'peer',
      content: message,
      timestamp: DateTime.now(),
      isSOS: message.toLowerCase().contains('sos'),
      isSynced: true,
    );
    
    print('🔥 Adding message to state: ${newMessage.content}');
    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, newMessage],
    ));
  }
  
  Future<void> sendMessage(String text, {bool isSOS = false}) async {
    if (text.trim().isEmpty) return;
    
    try {
      final currentState = state.value ?? const ChatState();
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      
      // Send message via NearbyService
      await _nearbyService.sendMessage(text, type: isSOS ? 'sos' : 'chat');
      
      final sentMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me',
        content: text,
        timestamp: DateTime.now(),
        isSOS: isSOS,
        isSynced: true,
      );
      
      state = AsyncValue.data(currentState.copyWith(
        messages: [...currentState.messages, sentMessage],
        isLoading: false,
      ));
      
      print('Message sent via NearbyService: $text');
      
    } catch (e) {
      print('Error sending message: $e');
      final currentState = state.value ?? const ChatState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send message: $e',
        isLoading: false,
      ));
    }
  }
  
  void clearMessages() {
    state = const AsyncValue.data(ChatState());
  }
  
  void clearError() {
    final currentState = state.value ?? const ChatState();
    state = AsyncValue.data(currentState.copyWith(error: null));
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}

final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
