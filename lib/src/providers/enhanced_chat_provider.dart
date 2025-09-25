import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_message_model.dart';
import '../services/nearby_service.dart';
import '../services/enhanced_message_queue_service.dart';
import '../services/encryption_service.dart';
import '../services/location_service.dart';

class EnhancedChatState {
  final List<EnhancedMessageModel> messages;
  final bool isLoading;
  final bool isConnected;
  final String? currentPeerName;
  final String? currentPeerId;
  final String? error;
  final Map<MessageStatus, int> messageStats;
  
  const EnhancedChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.currentPeerName,
    this.currentPeerId,
    this.error,
    this.messageStats = const {},
  });
  
  EnhancedChatState copyWith({
    List<EnhancedMessageModel>? messages,
    bool? isLoading,
    bool? isConnected,
    String? currentPeerName,
    String? currentPeerId,
    String? error,
    Map<MessageStatus, int>? messageStats,
  }) {
    return EnhancedChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      currentPeerName: currentPeerName ?? this.currentPeerName,
      currentPeerId: currentPeerId ?? this.currentPeerId,
      error: error ?? this.error,
      messageStats: messageStats ?? this.messageStats,
    );
  }
}

class EnhancedChatNotifier extends AsyncNotifier<EnhancedChatState> {
  final NearbyService _nearbyService = NearbyService.instance;
  final MessageQueueService _messageQueue = MessageQueueService.instance;
  final EncryptionService _encryption = EncryptionService.instance;
  final LocationService _location = LocationService.instance;
  
  StreamSubscription? _messageSubscription;
  Timer? _syncTimer;

  @override
  Future<EnhancedChatState> build() async {
    // Listen to incoming messages
    _messageSubscription = _nearbyService.onMessageReceived.listen(_handleIncomingMessage);
    
    // Setup periodic sync for message status updates
    _setupPeriodicSync();
    
    // Load existing messages from database
    await _loadMessages();
    
    // Check connection status
    final bool hasConnections = _nearbyService.connectedEndpoints.isNotEmpty;
    
    return EnhancedChatState(
      isConnected: hasConnections,
      currentPeerName: hasConnections ? 'Connected Device' : 'No Connection',
    );
  }

  void _setupPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _updateMessageStats();
      await _processPendingMessages();
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messageQueue.getAllMessages();
      final stats = await _messageQueue.getMessageStats();
      
      final currentState = state.value ?? const EnhancedChatState();
      state = AsyncValue.data(currentState.copyWith(
        messages: messages,
        messageStats: stats,
      ));
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _updateMessageStats() async {
    try {
      final stats = await _messageQueue.getMessageStats();
      final currentState = state.value ?? const EnhancedChatState();
      state = AsyncValue.data(currentState.copyWith(messageStats: stats));
    } catch (e) {
      print('Error updating message stats: $e');
    }
  }

  Future<void> _processPendingMessages() async {
    try {
      final pendingMessages = await _messageQueue.getPendingMessages();
      for (final message in pendingMessages) {
        if (_nearbyService.connectedEndpoints.isNotEmpty) {
          await _sendMessageToNearby(message);
        }
      }
    } catch (e) {
      print('Error processing pending messages: $e');
    }
  }

  void _handleIncomingMessage(String messageContent) async {
    print('🔥 Enhanced ChatProvider received message: $messageContent');
    
    try {
      final currentState = state.value ?? const EnhancedChatState();
      
      // Create received message
      final receivedMessage = EnhancedMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentState.currentPeerId ?? 'peer',
        content: messageContent,
        timestamp: DateTime.now(),
        type: messageContent.toLowerCase().contains('sos') ? MessageType.sos : MessageType.text,
        status: MessageStatus.delivered,
        isSOS: messageContent.toLowerCase().contains('sos'),
        isEncrypted: false, // Already decrypted by NearbyService
      );
      
      // Save to database
      await _messageQueue.insertPendingMessage(receivedMessage);
      
      // Update UI
      await _loadMessages();
      
      print('🔥 Message processed and saved: ${receivedMessage.content}');
    } catch (e) {
      print('Error handling incoming message: $e');
    }
  }

  /// Send a text message
  Future<void> sendMessage(String text, {bool isSOS = false, bool encrypt = true}) async {
    if (text.trim().isEmpty) return;
    
    try {
      final currentState = state.value ?? const EnhancedChatState();
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      
      // Get current location if SOS
      double? latitude, longitude;
      if (isSOS) {
        try {
          final position = await _location.getCurrentPosition();
          if (position != null) {
            latitude = position.latitude;
            longitude = position.longitude;
          }
        } catch (e) {
          print('Failed to get location for SOS: $e');
        }
      }
      
      // Create message
      final message = EnhancedMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me',
        receiverId: currentState.currentPeerId,
        content: text,
        timestamp: DateTime.now(),
        type: isSOS ? MessageType.sos : MessageType.text,
        status: MessageStatus.pending,
        isSOS: isSOS,
        isEncrypted: encrypt && currentState.currentPeerId != null,
        latitude: latitude,
        longitude: longitude,
      );
      
      // Save to database
      await _messageQueue.insertPendingMessage(message);
      
      // Try to send immediately if connected
      if (_nearbyService.connectedEndpoints.isNotEmpty) {
        await _sendMessageToNearby(message);
      }
      
      // Reload messages to show updated state
      await _loadMessages();
      
      final updatedState = state.value ?? const EnhancedChatState();
      state = AsyncValue.data(updatedState.copyWith(isLoading: false));
      
      print('Message queued and sent: $text');
      
    } catch (e) {
      print('Error sending message: $e');
      final currentState = state.value ?? const EnhancedChatState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send message: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _sendMessageToNearby(EnhancedMessageModel message) async {
    try {
      String contentToSend = message.content;
      
      // Add location info for SOS messages
      if (message.type == MessageType.sos && message.latitude != null && message.longitude != null) {
        contentToSend = '🆘 SOS: ${message.content}\n📍 Location: ${message.latitude}, ${message.longitude}';
      }
      
      // Send via NearbyService
      await _nearbyService.sendMessage(
        contentToSend, 
        type: message.isSOS ? 'sos' : 'chat'
      );
      
      // Mark as sent in database
      await _messageQueue.markMessageSent(int.parse(message.id));
      
      print('Message sent to nearby devices: ${message.content}');
    } catch (e) {
      print('Failed to send message to nearby devices: $e');
      rethrow;
    }
  }

  /// Send SOS broadcast with current location
  Future<void> sendSOSBroadcast(String message) async {
    await sendMessage(message, isSOS: true, encrypt: false); // SOS messages are not encrypted for emergency
  }

  /// Send media message (placeholder for future implementation)
  Future<void> sendMediaMessage(String filePath, MessageType type) async {
    // TODO: Implement media message sending
    final message = EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      content: 'Media file shared',
      timestamp: DateTime.now(),
      type: type,
      status: MessageStatus.pending,
      filePath: filePath,
    );
    
    await _messageQueue.insertPendingMessage(message);
    await _loadMessages();
  }

  /// Clear error message
  void clearError() {
    final currentState = state.value ?? const EnhancedChatState();
    state = AsyncValue.data(currentState.copyWith(error: null));
  }

  /// Clear all messages
  Future<void> clearMessages() async {
    // TODO: Implement message clearing in database
    state = const AsyncValue.data(EnhancedChatState());
  }

  /// Set current peer for encryption
  void setCurrentPeer(String peerId, String peerName, {String? publicKey}) {
    if (publicKey != null) {
      _encryption.computeSharedSecret(peerId, publicKey);
    }
    
    final currentState = state.value ?? const EnhancedChatState();
    state = AsyncValue.data(currentState.copyWith(
      currentPeerId: peerId,
      currentPeerName: peerName,
      isConnected: true,
    ));
  }

  // Clean up resources when notifier is disposed
  void cleanup() {
    _messageSubscription?.cancel();
    _syncTimer?.cancel();
    _messageQueue.dispose();
  }
}

// Provider for the enhanced chat system
final enhancedChatProvider = AsyncNotifierProvider<EnhancedChatNotifier, EnhancedChatState>(() {
  return EnhancedChatNotifier();
});

// Provider for message statistics
final messageStatsProvider = Provider<Map<MessageStatus, int>>((ref) {
  final chatState = ref.watch(enhancedChatProvider);
  return chatState.when(
    data: (state) => state.messageStats,
    loading: () => {},
    error: (_, __) => {},
  );
});