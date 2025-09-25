import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../data/enhanced_db.dart';
import '../models/enhanced_message_model.dart';
import '../utils/constants.dart';

/// Enhanced Cloud Sync Service for syncing messages when internet is available
class EnhancedCloudSync {
  static final EnhancedCloudSync _instance = EnhancedCloudSync._internal();
  static EnhancedCloudSync get instance => _instance;
  
  final EnhancedAppDatabase _db = EnhancedAppDatabase();
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
        print('🌐 Internet connection restored - starting sync');
        await uploadPending();
      } else if (!_isOnline && wasOnline) {
        // Just went offline
        print('📴 Internet connection lost');
      }
    } catch (e) {
      _isOnline = false;
    }
  }

  /// Upload pending messages to cloud
  Future<void> uploadPending() async {
    if (!_isOnline) {
      print('🔴 No internet connection - cannot upload messages');
      return;
    }

    try {
      final unsynedMessages = await _db.getUnsyncedMessages();
      
      if (unsynedMessages.isEmpty) {
        print('✅ No messages to sync');
        return;
      }

      print('📤 Uploading ${unsynedMessages.length} messages to cloud...');

      int successCount = 0;
      for (final message in unsynedMessages) {
        try {
          await _uploadMessage(message);
          await _db.markMessageSynced(message.messageId);
          successCount++;
        } catch (e) {
          print('❌ Failed to upload message ${message.messageId}: $e');
        }
      }

      print('✅ Successfully uploaded $successCount/${unsynedMessages.length} messages');
    } catch (e) {
      print('❌ Error during upload: $e');
    }
  }

  /// Download new messages from cloud
  Future<void> downloadMessages() async {
    if (!_isOnline) {
      print('🔴 No internet connection - cannot download messages');
      return;
    }

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/messages?since=${_getLastSyncTimestamp()}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        print('📥 Downloading ${data.length} messages from cloud...');

        int newMessageCount = 0;
        for (final messageData in data) {
          try {
            await _saveMessageFromCloud(messageData);
            newMessageCount++;
          } catch (e) {
            print('❌ Failed to save message from cloud: $e');
          }
        }

        print('✅ Downloaded $newMessageCount new messages');
      }
    } catch (e) {
      print('❌ Error downloading messages: $e');
    }
  }

  /// Upload a single message to cloud
  Future<void> _uploadMessage(EnhancedMessage message) async {
    final payload = {
      'id': message.messageId,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'content': message.content,
      'timestamp': message.timestamp.toIso8601String(),
      'type': message.type.toString(),
      'status': message.status.toString(),
      'isSos': message.isSos,
      'isEncrypted': message.isEncrypted,
      'filePath': message.filePath,
      'thumbnailPath': message.thumbnailPath,
      'latitude': message.latitude,
      'longitude': message.longitude,
      'deliveredAt': message.deliveredAt?.toIso8601String(),
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
      final exists = existingMessages.any((msg) => msg.messageId == data['id']);
      
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
      final message = EnhancedMessageModel(
        id: data['id'],
        senderId: data['senderId'],
        receiverId: data['receiverId'],
        content: data['content'],
        timestamp: DateTime.parse(data['timestamp']),
        type: messageType,
        status: messageStatus,
        isSOS: data['isSos'] ?? false,
        isEncrypted: data['isEncrypted'] ?? false,
        filePath: data['filePath'],
        thumbnailPath: data['thumbnailPath'],
        latitude: data['latitude']?.toDouble(),
        longitude: data['longitude']?.toDouble(),
      );

      // Insert into database
      await _db.insertPendingMessage(message);
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
    print('🔄 Starting cloud sync...');
    await uploadPending();
    await downloadMessages();
    print('✅ Cloud sync completed');
  }

  /// Upload SOS broadcasts to cloud for emergency response
  Future<void> uploadSOSBroadcasts() async {
    if (!_isOnline) return;

    try {
      final sosBroadcasts = await _db.getActiveSosBroadcasts();
      
      for (final sos in sosBroadcasts) {
        await _uploadSOSBroadcast(sos);
      }
    } catch (e) {
      print('❌ Error uploading SOS broadcasts: $e');
    }
  }

  /// Upload a single SOS broadcast to emergency services
  Future<void> _uploadSOSBroadcast(SosBroadcast sos) async {
    final payload = {
      'sosId': sos.sosId,
      'deviceId': sos.deviceId,
      'deviceName': sos.deviceName,
      'message': sos.message,
      'latitude': sos.latitude,
      'longitude': sos.longitude,
      'timestamp': sos.timestamp.toIso8601String(),
      'isActive': sos.isActive,
      'priority': 'EMERGENCY',
    };

    final response = await _client.post(
      Uri.parse('$baseUrl/emergency/sos'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('🚨 SOS broadcast uploaded to emergency services: ${sos.sosId}');
    }
  }

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final allMessages = await _db.getAllMessages();
    final stats = await _db.getMessageStats();
    
    return {
      'total': allMessages.length,
      'synced': stats['MessageStatus.synced'] ?? 0,
      'pending': stats['MessageStatus.pending'] ?? 0,
      'failed': stats['MessageStatus.failed'] ?? 0,
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