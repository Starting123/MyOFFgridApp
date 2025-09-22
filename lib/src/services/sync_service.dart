
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/db.dart';
import '../data/models/message_model.dart';
import '../data/models/queue_item.dart';
import '../data/models/sync_log.dart';
import '../utils/constants.dart';

class SyncService {
  final AppDatabase db;
  Timer? _queueTimer;
  bool _processing = false;
  static const _retryDelays = [1, 5, 15, 30, 60]; // Minutes

  SyncService(this.db) {
    // Start queue processing timer
    _queueTimer = Timer.periodic(Duration(minutes: 1), (_) => processQueue());
  }

  /// Add a message to the sync queue
  Future<void> queueMessage(MessageModel message, {int priority = 1}) async {
    final queueItem = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch,
      messageId: message.id,
      type: 'message',
      priority: priority,
      retryCount: 0,
      nextRetry: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await db.insertQueueItem(queueItem);
  }

  /// Process the sync queue based on priority and retry timing
  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;

    try {
      final items = await db.getQueueItemsDue();
      for (final item in items) {
        if (item.type == 'message') {
          final message = await db.getMessage(item.messageId);
          if (message == null) {
            await db.deleteQueueItem(item.id);
            continue;
          }

          bool success = false;
          try {
            // Try P2P delivery first
            success = await _attemptP2PDelivery(message);
            
            // Fall back to cloud if P2P fails
            if (!success) {
              success = await _attemptCloudDelivery(message);
            }
          } catch (e) {
            // Log sync error
            await db.insertSyncLog(SyncLog(
              id: DateTime.now().millisecondsSinceEpoch,
              type: 'error',
              itemId: item.id,
              details: e.toString(),
              createdAt: DateTime.now(),
            ));
          }

          if (success) {
            await db.deleteQueueItem(item.id);
            await db.updateMessage(message.copyWith(sent: true));
            
            // Log success
            await db.insertSyncLog(SyncLog(
              id: DateTime.now().millisecondsSinceEpoch,
              type: 'success',
              itemId: item.id,
              details: 'Message delivered successfully',
              createdAt: DateTime.now(),
            ));
          } else {
            // Update retry count and next retry time
            final retryIndex = item.retryCount.clamp(0, _retryDelays.length - 1);
            final nextRetry = DateTime.now().add(
              Duration(minutes: _retryDelays[retryIndex])
            );
            
            await db.updateQueueItem(item.copyWith(
              retryCount: item.retryCount + 1,
              nextRetry: nextRetry,
            ));
          }
        }
      }
    } finally {
      _processing = false;
    }
  }

  /// Attempt to deliver message via P2P
  Future<bool> _attemptP2PDelivery(MessageModel message) async {
    // TODO: Implement P2P message delivery using nearby_connections
    // This will involve:
    // 1. Discovering nearby peers
    // 2. Establishing connection
    // 3. Sending message
    // 4. Getting delivery confirmation
    return false; // Fall back to cloud delivery for now
  }

  /// Attempt to deliver message via cloud
  Future<bool> _attemptCloudDelivery(MessageModel message) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.cloudEndpoint}/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': message.id,
          'from': message.from,
          'to': message.to,
          'content': message.content,
          'contentType': message.contentType,
          'createdAt': message.createdAt.toIso8601String(),
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _queueTimer?.cancel();
  }
}



