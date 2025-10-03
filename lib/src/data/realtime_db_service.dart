import 'dart:async';
import '../models/chat_models.dart';
import 'db.dart';

/// Enhanced database service with real-time watch streams
class RealtimeDatabaseService extends LocalDatabaseService {
  final Map<String, StreamController<List<ChatMessage>>> _chatStreams = {};
  final Map<String, List<ChatMessage>> _chatCache = {};
  Timer? _pollTimer;

  /// Get or create a watch stream for a specific chat
  @override
  Stream<List<ChatMessage>> watchMessagesForChat(String chatId) {
    if (!_chatStreams.containsKey(chatId)) {
      _chatStreams[chatId] = StreamController<List<ChatMessage>>.broadcast(
        onListen: () => _startWatchingChat(chatId),
        onCancel: () => _stopWatchingChat(chatId),
      );
    }
    
    return _chatStreams[chatId]!.stream;
  }

  /// Start watching a specific chat for changes
  void _startWatchingChat(String chatId) {
    // Load initial data
    _loadChatMessages(chatId);
    
    // Start polling for changes if not already started
    _pollTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
      _checkAllChatsForUpdates();
    });
  }

  /// Stop watching a specific chat
  void _stopWatchingChat(String chatId) {
    _chatStreams[chatId]?.close();
    _chatStreams.remove(chatId);
    _chatCache.remove(chatId);
    
    // Stop polling if no active streams
    if (_chatStreams.isEmpty) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Load chat messages and update stream
  Future<void> _loadChatMessages(String chatId) async {
    try {
      final messages = await getMessagesForConversation(chatId);
      _chatCache[chatId] = messages;
      _chatStreams[chatId]?.add(messages);
    } catch (e) {
      _chatStreams[chatId]?.addError(e);
    }
  }

  /// Check all active chats for updates
  Future<void> _checkAllChatsForUpdates() async {
    for (final chatId in _chatStreams.keys) {
      await _checkChatForUpdates(chatId);
    }
  }

  /// Check a specific chat for updates
  Future<void> _checkChatForUpdates(String chatId) async {
    try {
      final currentMessages = await getMessagesForConversation(chatId);
      final cachedMessages = _chatCache[chatId] ?? [];
      
      // Simple comparison - in production you'd use more sophisticated change detection
      if (_hasMessagesChanged(cachedMessages, currentMessages)) {
        _chatCache[chatId] = currentMessages;
        _chatStreams[chatId]?.add(currentMessages);
      }
    } catch (e) {
      _chatStreams[chatId]?.addError(e);
    }
  }

  /// Check if messages have changed
  bool _hasMessagesChanged(List<ChatMessage> cached, List<ChatMessage> current) {
    if (cached.length != current.length) return true;
    
    for (int i = 0; i < cached.length; i++) {
      if (cached[i].id != current[i].id || 
          cached[i].status != current[i].status ||
          cached[i].content != current[i].content) {
        return true;
      }
    }
    
    return false;
  }

  /// Override insertMessage to trigger stream updates
  @override
  Future<void> insertMessage(ChatMessage message) async {
    await super.insertMessage(message);
    
    // Update relevant chat stream
    final chatId = message.receiverId;
    if (_chatStreams.containsKey(chatId)) {
      await _checkChatForUpdates(chatId);
    }
  }

  /// Override updateMessageStatus to trigger stream updates
  @override
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    await super.updateMessageStatus(messageId, status);
    
    // Find and update relevant chat streams by getting all messages and checking which chat they belong to
    for (final chatId in _chatStreams.keys) {
      await _checkChatForUpdates(chatId);
    }
  }

  /// Watch emergency messages
  Stream<List<ChatMessage>> watchEmergencyMessages() async* {
    while (true) {
      try {
        final messages = await getEmergencyMessages();
        yield messages;
      } catch (e) {
        yield [];
      }
      
      await Future.delayed(const Duration(seconds: 1)); // More frequent for emergencies
    }
  }

  /// Watch nearby devices for changes
  Stream<List<NearbyDevice>> watchNearbyDevices() async* {
    while (true) {
      try {
        final devices = await getNearbyDevices();
        yield devices;
      } catch (e) {
        yield [];
      }
      
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Watch SOS devices specifically
  Stream<List<NearbyDevice>> watchSOSDevices() async* {
    await for (final devices in watchNearbyDevices()) {
      yield devices.where((device) => device.isSOSActive).toList();
    }
  }

  /// Watch rescuer devices specifically
  Stream<List<NearbyDevice>> watchRescuerDevices() async* {
    await for (final devices in watchNearbyDevices()) {
      yield devices.where((device) => device.isRescuerActive).toList();
    }
  }

  /// Watch unsynced messages for cloud sync
  Stream<List<ChatMessage>> watchUnsyncedMessages() async* {
    while (true) {
      try {
        final messages = await getUnsyncedMessages();
        yield messages;
      } catch (e) {
        yield [];
      }
      
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Watch conversations using basic Map conversion
  Stream<List<Map<String, dynamic>>> watchConversations() async* {
    while (true) {
      try {
        final conversations = await getConversations();
        yield conversations;
      } catch (e) {
        yield [];
      }
      
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// Watch pending queue items using basic Map conversion
  Stream<List<Map<String, dynamic>>> watchPendingQueueItems() async* {
    while (true) {
      try {
        final queueItems = await getPendingQueueItems();
        yield queueItems;
      } catch (e) {
        yield [];
      }
      
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// Watch failed sync logs using basic Map conversion
  Stream<List<Map<String, dynamic>>> watchFailedSyncLogs() async* {
    while (true) {
      try {
        final syncLogs = await getFailedSyncLogs();
        yield syncLogs;
      } catch (e) {
        yield [];
      }
      
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  /// Dispose all streams and timers
  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    
    for (final controller in _chatStreams.values) {
      await controller.close();
    }
    _chatStreams.clear();
    _chatCache.clear();
    
    await super.close();
  }
}

/// Singleton instance for global access
class DatabaseService {
  static RealtimeDatabaseService? _instance;
  
  static RealtimeDatabaseService get instance {
    _instance ??= RealtimeDatabaseService();
    return _instance!;
  }
  
  /// Initialize database service
  static Future<void> initialize() async {
    final service = instance;
    await service.database; // Initialize database
  }
  
  /// Close database service
  static Future<void> dispose() async {
    await _instance?.close();
    _instance = null;
  }
}