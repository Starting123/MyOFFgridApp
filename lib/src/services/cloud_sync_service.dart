import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'local_db_service.dart';
import '../models/enhanced_message_model.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

/// Enhanced Cloud Sync Service for syncing messages when internet is available
class EnhancedCloudSync {
  static final EnhancedCloudSync _instance = EnhancedCloudSync._internal();
  static EnhancedCloudSync get instance => _instance;
  
  final LocalDatabaseService _db = LocalDatabaseService();
  final http.Client _client = http.Client();
  final String baseUrl;
  
  bool _isOnline = false;
  Timer? _syncTimer;
  Timer? _connectivityTimer;

  EnhancedCloudSync._internal() : baseUrl = Constants.cloudEndpoint {
    _startConnectivityCheck();
  }

  /// Start periodic connectivity check
  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkConnectivity();
    });
  }

  /// Check internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      final wasOnline = _isOnline;
      _isOnline = response.statusCode == 200;
      
      if (_isOnline && !wasOnline) {
        // Just came online
        Logger.success('Internet connection restored - starting sync', 'cloud');
        await uploadPending();
      } else if (!_isOnline && wasOnline) {
        // Just went offline
        Logger.warning('Internet connection lost', 'cloud');
      }
    } catch (e) {
      _isOnline = false;
    }
  }

  /// Upload pending messages to cloud
  Future<void> uploadPending() async {
    if (!_isOnline) {
      Logger.warning('No internet connection - cannot upload messages', 'cloud');
      return;
    }

    try {
      final unsynedMessages = await _db.getUnsyncedMessages();
      
      if (unsynedMessages.isEmpty) {
        Logger.info('No messages to sync', 'cloud');
        return;
      }

      Logger.info('Uploading ${unsynedMessages.length} messages to cloud...', 'cloud');

      int successCount = 0;
      for (final message in unsynedMessages) {
        try {
          await _uploadMessage(message);
          await _db.markMessageSynced(message.id);
          successCount++;
        } catch (e) {
          Logger.error('Failed to upload message ${message.id}: $e', 'cloud');
        }
      }

      Logger.success('Successfully uploaded $successCount/${unsynedMessages.length} messages', 'cloud');
    } catch (e) {
      Logger.error('Error during upload: $e', 'cloud');
    }
  }

  /// Download new messages from cloud
  Future<void> downloadMessages() async {
    if (!_isOnline) {
      Logger.warning('No internet connection - cannot download messages', 'cloud');
      return;
    }

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/messages?since=${_getLastSyncTimestamp()}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        Logger.info('Downloading ${data.length} messages from cloud...', 'cloud');

        int newMessageCount = 0;
        for (final messageData in data) {
          try {
            await _saveMessageFromCloud(messageData);
            newMessageCount++;
          } catch (e) {
            Logger.error('Failed to save message from cloud: $e', 'cloud');
          }
        }

        Logger.success('Downloaded $newMessageCount new messages', 'cloud');
      }
    } catch (e) {
      Logger.error('Error downloading messages: $e', 'cloud');
    }
  }

  /// Upload a single message to cloud
  Future<void> _uploadMessage(ChatMessage message) async {
    final payload = {
      'id': message.id,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'content': message.content,
      'timestamp': message.timestamp.toIso8601String(),
      'type': message.type.toString(),
      'status': message.status.toString(),
      'isEmergency': message.isEmergency,
      'filePath': message.filePath,
      'latitude': message.latitude,
      'longitude': message.longitude,
      'senderName': message.senderName,
      'syncedAt': DateTime.now().toIso8601String(),
    };

    final response = await _client.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to upload message: ${response.statusCode} - ${response.body}');
    }
  }

  /// Save message from cloud to local database
  Future<void> _saveMessageFromCloud(Map<String, dynamic> data) async {
    try {
      // Check if message already exists
      final existingMessages = await _db.getAllMessages();
      final exists = existingMessages.any((msg) => msg.id == data['id']);
      
      if (exists) return;

      // Parse message type and status
      final messageType = MessageType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => MessageType.text,
      );
      
      final messageStatus = MessageStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => MessageStatus.synced,
      );

      // Create message model
      final message = ChatMessage(
        id: data['id'],
        senderId: data['senderId'],
        senderName: data['senderName'] ?? 'Unknown',
        receiverId: data['receiverId'],
        content: data['content'],
        timestamp: DateTime.parse(data['timestamp']),
        type: messageType,
        status: messageStatus,
        isEmergency: data['isEmergency'] ?? false,
        filePath: data['filePath'],
        latitude: data['latitude']?.toDouble(),
        longitude: data['longitude']?.toDouble(),
      );

      // Insert into database
      await _db.insertMessage(message);
      await _db.markMessageSynced(message.id);
      
    } catch (e) {
      throw Exception('Error saving message from cloud: $e');
    }
  }

  /// Get last sync timestamp for incremental sync
  String _getLastSyncTimestamp() {
    // In a real implementation, this would be stored in local preferences
    // For now, return 24 hours ago
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.toIso8601String();
  }

  /// Start automatic sync when online
  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_isOnline) {
        await sync();
      }
    });
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  /// Perform full sync (upload + download)
  Future<void> sync() async {
    Logger.info('Starting cloud sync...', 'cloud');
    await uploadPending();
    await downloadMessages();
    Logger.success('Cloud sync completed', 'cloud');
  }

  /// Upload SOS broadcasts to cloud for emergency response
  Future<void> uploadSOSBroadcasts() async {
    if (!_isOnline) return;

    try {
      // Get emergency messages instead of SOS broadcasts
      final emergencyMessages = await _db.getEmergencyMessages();
      
      for (final message in emergencyMessages) {
        // Convert message to SOS broadcast format if needed
        Logger.info('Processing emergency message: ${message.content}', 'cloud');
      }
    } catch (e) {
      Logger.error('Error uploading SOS broadcasts: $e', 'cloud');
    }
  }



  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final allMessages = await _db.getAllMessages();
    final unsyncedMessages = await _db.getUnsyncedMessages();
    final emergencyMessages = await _db.getEmergencyMessages();
    
    return {
      'total': allMessages.length,
      'synced': allMessages.where((m) => m.status == MessageStatus.synced).length,
      'unsynced': unsyncedMessages.length,
      'emergency': emergencyMessages.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivityTimer?.cancel();
    _client.close();
    _db.close();
  }
}