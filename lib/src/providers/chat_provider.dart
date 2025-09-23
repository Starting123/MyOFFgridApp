import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/p2p_service.dart';

@immutable
class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;
  final bool isConnected;
  final String? currentPeerId;
  final String? currentPeerName;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isConnected = false,
    this.currentPeerId,
    this.currentPeerName,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    bool? isConnected,
    String? currentPeerId,
    String? currentPeerName,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isConnected: isConnected ?? this.isConnected,
      currentPeerId: currentPeerId ?? this.currentPeerId,
      currentPeerName: currentPeerName ?? this.currentPeerName,
    );
  }
}

final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(() => ChatNotifier());

class ChatNotifier extends AsyncNotifier<ChatState> {
  final _p2pService = P2PService.instance;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _peerFoundSubscription;
  StreamSubscription? _peerLostSubscription;

  @override
  Future<ChatState> build() async {
    final initialized = await _p2pService.initialize();
    if (!initialized) {
      return const ChatState(
        messages: [],
        isLoading: false,
        error: 'Failed to initialize P2P service',
        isConnected: false,
        currentPeerId: null,
        currentPeerName: null,
      );
    }

    // Listen for incoming data
    _dataSubscription = _p2pService.onDataReceived.listen(_handleIncomingData);
    _peerFoundSubscription = _p2pService.onPeerFound.listen(_handlePeerFound);
    _peerLostSubscription = _p2pService.onPeerLost.listen(_handlePeerLost);

    // Start discovery and advertising
    await _p2pService.startDiscovery();
    await _p2pService.startAdvertising('User Device'); // TODO: Get actual device name

    ref.onDispose(() {
      _dataSubscription?.cancel();
      _peerFoundSubscription?.cancel();
      _peerLostSubscription?.cancel();
      _p2pService.dispose();
    });

    return const ChatState(
      messages: [],
      isLoading: false,
      error: null,
      isConnected: false,
      currentPeerId: null,
      currentPeerName: null,
    );
  }

  void _handleIncomingData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final message = data['message'] as String?;
    final timestamp = DateTime.tryParse(data['timestamp'] as String? ?? '');

    if (type != null && message != null && timestamp != null) {
      final messageModel = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: data['senderId'] as String? ?? 'unknown',
        content: message,
        timestamp: timestamp,
        isSOS: type == 'sos',
      );
      addMessage(messageModel);
    }
  }

  void _handlePeerFound(String peerId) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(
      isConnected: _p2pService.connectedPeers.isNotEmpty,
      currentPeerId: peerId,
    ));
  }

  void _handlePeerLost(String peerId) {
    final currentState = state.value;
    if (currentState == null) return;

    if (peerId == currentState.currentPeerId) {
      state = AsyncValue.data(currentState.copyWith(
        currentPeerId: null,
        currentPeerName: null,
      ));
    }
    state = AsyncValue.data(currentState.copyWith(
      isConnected: _p2pService.connectedPeers.isNotEmpty,
    ));
  }

  void addMessage(MessageModel message) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, message],
    ));
  }

  Future<void> sendMessage(String content, {bool isSOS = false}) async {
    if (content.trim().isEmpty) return;

    try {
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_user_id', // TODO: Replace with actual user ID
        content: content,
        timestamp: DateTime.now(),
        isSOS: isSOS,
      );

      bool success;
      final currentState = state.value;
      if (currentState == null) return;

      if (isSOS) {
        success = await _p2pService.sendSOS(content);
      } else if (currentState.currentPeerId != null) {
        success = await _p2pService.sendMessage(
          content,
          targetPeerId: currentState.currentPeerId,
        );
      } else {
        success = await _p2pService.sendMessage(content);
      }

      if (success) {
        addMessage(message);
      } else {
        state = AsyncValue.data(currentState.copyWith(
          error: 'Failed to send message',
        ));
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clearError() {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(error: null));
  }
}