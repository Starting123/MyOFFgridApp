import '../models/enhanced_message_model.dart';
import '../data/enhanced_db.dart';
import '../services/encryption_service.dart';

/// Enhanced Message Service that handles encrypted message persistence and queuing
class MessageQueueService {
  static final MessageQueueService _instance = MessageQueueService._internal();
  static MessageQueueService get instance => _instance;
  
  final EnhancedAppDatabase _db;
  final EncryptionService _encryption;
  
  MessageQueueService._internal() 
    : _db = EnhancedAppDatabase(),
      _encryption = EncryptionService.instance;

  /// Insert a new message with pending status
  Future<int> insertPendingMessage(EnhancedMessageModel message) async {
    return await _db.insertPendingMessage(message);
  }

  /// Get all messages with proper decryption
  Future<List<EnhancedMessageModel>> getAllMessages() async {
    final messages = await _db.getAllMessages();
    return messages.map(_convertToEnhancedMessage).toList();
  }

  /// Get pending messages that need to be sent
  Future<List<EnhancedMessageModel>> getPendingMessages() async {
    final messages = await _db.getPendingMessages();
    return messages.map(_convertToEnhancedMessage).toList();
  }

  /// Mark message as sent
  Future<bool> markMessageSent(int messageId) async {
    return await _db.markMessageSent(messageId.toString());
  }

  /// Mark message as synced to cloud
  Future<bool> markMessageSynced(int messageId) async {
    return await _db.markMessageSynced(messageId.toString());
  }

  /// Convert database EnhancedMessage to EnhancedMessageModel
  EnhancedMessageModel _convertToEnhancedMessage(EnhancedMessage dbMessage) {
    // Decrypt content if needed
    String content = dbMessage.content;
    
    // Try to decrypt if encrypted
    try {
      if (dbMessage.isEncrypted && dbMessage.senderId != 'me' && dbMessage.senderId.isNotEmpty) {
        content = _encryption.decryptString(dbMessage.senderId, content);
      }
    } catch (e) {
      // If decryption fails, use original content
      print('Failed to decrypt message: $e');
    }

    return EnhancedMessageModel(
      id: dbMessage.messageId,
      senderId: dbMessage.senderId,
      receiverId: dbMessage.receiverId,
      content: content,
      timestamp: dbMessage.timestamp,
      type: dbMessage.type,
      status: dbMessage.status,
      isSOS: dbMessage.isSos,
      isEncrypted: dbMessage.isEncrypted,
      filePath: dbMessage.filePath,
      thumbnailPath: dbMessage.thumbnailPath,
      latitude: dbMessage.latitude,
      longitude: dbMessage.longitude,
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
    final stats = await _db.getMessageStats();
    final result = <MessageStatus, int>{};
    
    for (final status in MessageStatus.values) {
      result[status] = stats[status.toString()] ?? 0;
    }
    
    return result;
  }

  /// Clean old messages (keep last 500)
  Future<void> cleanOldMessages() async {
    await _db.cleanOldMessages();
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
  
  final EnhancedAppDatabase _db = EnhancedAppDatabase();
  
  DeviceRegistryService._internal();

  /// Register or update a nearby device
  Future<void> upsertDevice(String deviceId, String name, String deviceType, {String? publicKey}) async {
    await _db.upsertDevice(deviceId, name, deviceType, publicKey: publicKey);
  }

  /// Get all online devices
  Future<List<Device>> getOnlineDevices() async {
    return await _db.getOnlineDevices();
  }

  /// Mark device as offline
  Future<void> markDeviceOffline(String deviceId) async {
    await _db.markDeviceOffline(deviceId);
  }

  /// Get device public key for encryption
  Future<String?> getDevicePublicKey(String deviceId) async {
    final devices = await _db.getOnlineDevices();
    final device = devices.where((d) => d.id == deviceId).firstOrNull;
    return device?.publicKey;
  }

  /// Clean offline devices (older than 10 minutes)
  Future<void> cleanOfflineDevices() async {
    // This would need to be implemented in the database layer
    // For now, we'll let the database handle this through lastSeen timestamps
  }
}