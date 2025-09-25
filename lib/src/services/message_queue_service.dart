import 'package:drift/drift.dart';
import '../models/enhanced_message_model.dart';
import '../data/db.dart';
import '../services/encryption_service.dart';

/// Enhanced Message Service that handles encrypted message persistence and queuing
class MessageQueueService {
  static final MessageQueueService _instance = MessageQueueService._internal();
  static MessageQueueService get instance => _instance;
  
  final AppDatabase _db;
  final EncryptionService _encryption;
  
  MessageQueueService._internal() 
    : _db = AppDatabase(),
      _encryption = EncryptionService.instance;

  /// Insert a new message with pending status
  Future<int> insertPendingMessage(EnhancedMessageModel message) async {
    // Encrypt content if needed
    String content = message.content;
    if (message.isEncrypted && message.receiverId != null) {
      content = _encryption.encryptString(message.receiverId!, message.content);
    }

    final messageCompanion = MessageCompanion(
      content: Value(content),
      senderId: Value(message.senderId),
      receiverId: Value(message.receiverId),
      isSos: Value(message.isSOS),
      timestamp: Value(message.timestamp),
      isSynced: const Value(false), // Start as unsynced
    );

    return await _db.insertMessage(messageCompanion);
  }

  /// Get all messages with proper decryption
  Future<List<EnhancedMessageModel>> getAllMessages() async {
    final messages = await _db.getAllMessages();
    return messages.map(_convertToEnhancedMessage).toList();
  }

  /// Get pending messages that need to be sent
  Future<List<EnhancedMessageModel>> getPendingMessages() async {
    final messages = await _db.getUnsynedMessages(); // Reuse unsynced for pending
    return messages.map(_convertToEnhancedMessage).toList();
  }

  /// Mark message as sent
  Future<bool> markMessageSent(int messageId) async {
    return await _db.updateMessageSyncStatus(messageId, false); // Still not synced to cloud
  }

  /// Mark message as synced to cloud
  Future<bool> markMessageSynced(int messageId) async {
    return await _db.updateMessageSyncStatus(messageId, true);
  }

  /// Convert database Message to EnhancedMessageModel
  EnhancedMessageModel _convertToEnhancedMessage(Message dbMessage) {
    // Decrypt content if needed
    String content = dbMessage.content;
    bool isEncrypted = false;
    
    // Try to detect if content is encrypted (basic heuristic)
    try {
      if (content.contains('==') && content.length > 40) { // Base64 encrypted content
        if (dbMessage.senderId != 'me') {
          content = _encryption.decryptString(dbMessage.senderId, content);
          isEncrypted = true;
        }
      }
    } catch (e) {
      // If decryption fails, use original content
    }

    // Determine status based on sync status
    MessageStatus status = MessageStatus.pending;
    if (dbMessage.isSynced) {
      status = MessageStatus.synced;
    } else {
      status = MessageStatus.sent; // Assume sent if in database but not synced
    }

    return EnhancedMessageModel(
      id: dbMessage.id.toString(),
      senderId: dbMessage.senderId,
      receiverId: dbMessage.receiverId,
      content: content,
      timestamp: dbMessage.timestamp,
      type: dbMessage.isSos ? MessageType.sos : MessageType.text,
      status: status,
      isSOS: dbMessage.isSos,
      isEncrypted: isEncrypted,
    );
  }

  /// Create SOS message with location
  Future<EnhancedMessageModel> createSOSMessage({
    required String senderId,
    required String content,
    double? latitude,
    double? longitude,
  }) async {
    final sosMessage = EnhancedMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.sos,
      status: MessageStatus.pending,
      isSOS: true,
      latitude: latitude,
      longitude: longitude,
    );

    await insertPendingMessage(sosMessage);
    return sosMessage;
  }

  /// Get message statistics
  Future<Map<MessageStatus, int>> getMessageStats() async {
    final allMessages = await getAllMessages();
    final stats = <MessageStatus, int>{};
    
    for (final status in MessageStatus.values) {
      stats[status] = allMessages.where((m) => m.status == status).length;
    }
    
    return stats;
  }

  /// Clean old messages (keep last 500)
  Future<void> cleanOldMessages() async {
    final allMessages = await getAllMessages();
    if (allMessages.length > 500) {
      final sortedMessages = allMessages..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final toDelete = sortedMessages.skip(500);
      
      for (final message in toDelete) {
        // Note: AppDatabase doesn't have delete method exposed, 
        // would need to add this to the database class
        print('Would delete message: ${message.id}');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _db.close();
  }
}

/// Device registry service for managing nearby devices
class DeviceRegistryService {
  static final DeviceRegistryService _instance = DeviceRegistryService._internal();
  static DeviceRegistryService get instance => _instance;
  
  final Map<String, Map<String, dynamic>> _devices = {};
  
  DeviceRegistryService._internal();

  /// Register or update a nearby device
  void upsertDevice(String deviceId, String name, String deviceType, {String? publicKey}) {
    _devices[deviceId] = {
      'id': deviceId,
      'name': name,
      'deviceType': deviceType,
      'lastSeen': DateTime.now(),
      'isOnline': true,
      'publicKey': publicKey,
    };
  }

  /// Get all online devices
  List<Map<String, dynamic>> getOnlineDevices() {
    final now = DateTime.now();
    return _devices.values.where((device) {
      final lastSeen = device['lastSeen'] as DateTime;
      final isRecent = now.difference(lastSeen).inMinutes < 5; // 5 minutes timeout
      return device['isOnline'] == true && isRecent;
    }).toList();
  }

  /// Mark device as offline
  void markDeviceOffline(String deviceId) {
    if (_devices.containsKey(deviceId)) {
      _devices[deviceId]!['isOnline'] = false;
    }
  }

  /// Get device public key for encryption
  String? getDevicePublicKey(String deviceId) {
    return _devices[deviceId]?['publicKey'] as String?;
  }

  /// Clean offline devices (older than 10 minutes)
  void cleanOfflineDevices() {
    final now = DateTime.now();
    _devices.removeWhere((key, device) {
      final lastSeen = device['lastSeen'] as DateTime;
      return now.difference(lastSeen).inMinutes > 10;
    });
  }
}