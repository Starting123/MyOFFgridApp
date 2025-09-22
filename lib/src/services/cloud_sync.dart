import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../data/db.dart';
import '../utils/constants.dart';

class CloudSync {
  final AppDatabase db;
  final MessageDao _messageDao;
  final QueueDao _queueDao;
  final SyncLogDao _syncLogDao;
  final http.Client _client = http.Client();
  final String baseUrl;

  CloudSync(this.db, {this.baseUrl = Constants.cloudEndpoint})
      : _messageDao = db.messageDao,
        _queueDao = db.queueDao,
        _syncLogDao = db.syncLogDao;

  /// Push messages to cloud
  Future<void> pushMessages() async {
    try {
      // Get pending messages
      final messages = await _messageDao.getPendingMessages();

      for (final message in messages) {
        // Check if already queued
        final existingQueueItem = await _queueDao.getQueueItemForMessage(message.messageId);
        if (existingQueueItem != null) continue;

        // Queue for sync
        await _queueDao.insertQueueItem(QueueItemsCompanion.insert(
          messageId: message.messageId,
          targetId: 'cloud',
          nextAttempt: DateTime.now(),
          attempts: const Value(0),
          status: QueueStatus.pending,
        ));
      }

      // Process queue
      await _processQueue();
    } catch (e) {
      await _logSyncError('push_messages', e.toString());
    }
  }

  /// Pull new messages from cloud
  Future<void> pullMessages() async {
    try {
      final latestSync = await _syncLogDao.getLatestSyncLog('pull_messages');
      final since = latestSync?.timestamp ?? DateTime(2000);

      final response = await _client.get(
        Uri.parse('$baseUrl/messages?since=${since.toIso8601String()}'),
      );

      if (response.statusCode == 200) {
        final messages = (jsonDecode(response.body) as List)
            .map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList();

        for (final message in messages) {
          // Skip if we already have this message
          if (await _messageDao.messageExists(message.messageId)) continue;

          await _messageDao.insertMessage(MessagesCompanion.insert(
            messageId: message.messageId,
            fromId: message.fromId,
            toId: message.toId,
            type: message.type,
            body: message.body,
            filePath: Value(message.filePath),
            timestamp: message.timestamp,
            status: MessageStatus.synced,
            ttl: const Value(24),
            hopCount: const Value(0),
          ));
        }

        await _logSyncSuccess('pull_messages', 'Pulled ${messages.length} messages');
      } else {
        await _logSyncError('pull_messages', 'HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      await _logSyncError('pull_messages', e.toString());
    }
  }

  /// Process the sync queue
  Future<void> _processQueue() async {
    final items = await _queueDao.getQueueItemsDue();

    for (final item in items) {
      if (item.status == QueueStatus.processing) continue;

      try {
        // Mark as processing
        await _queueDao.updateQueueItem(QueueItemsCompanion(
          id: Value(item.id),
          messageId: Value(item.messageId),
          targetId: Value(item.targetId),
          nextAttempt: Value(item.nextAttempt),
          attempts: Value(item.attempts),
          status: Value(QueueStatus.processing),
        ));

        // Get the message
        final message = await _messageDao.getMessage(item.messageId);
        if (message == null) {
          await _queueDao.deleteQueueItem(item.id);
          continue;
        }

        // Send to cloud
        final response = await _client.post(
          Uri.parse('$baseUrl/messages'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': message.id,
            'from': message.fromId,
            'to': message.toId,
            'type': message.type,
            'content': message.body,
            'timestamp': message.timestamp.toIso8601String(),
          }),
        );

        if (response.statusCode == 200) {
          // Success - remove from queue and mark as synced
          await _queueDao.deleteQueueItem(item.id);
          await _messageDao.updateMessage(MessagesCompanion(
            id: Value(message.id),
            messageId: Value(message.messageId),
            fromId: Value(message.fromId),
            toId: Value(message.toId),
            type: Value(message.type),
            body: Value(message.body),
            filePath: Value(message.filePath),
            timestamp: Value(message.timestamp),
            status: Value(MessageStatus.synced),
            ttl: Value(message.ttl),
            hopCount: Value(message.hopCount),
          ));
          await _logSyncSuccess('sync_message', 'Message ${message.messageId} synced');
        } else {
          // Failed - increment retry count
          final retryDelays = [1, 5, 15, 30, 60]; // Minutes
          final nextRetry = DateTime.now().add(Duration(
            minutes: retryDelays[item.attempts.clamp(0, retryDelays.length - 1)],
          ));

          await _queueDao.updateQueueItem(QueueItemsCompanion(
            id: Value(item.id),
            messageId: Value(item.messageId),
            targetId: Value(item.targetId),
            nextAttempt: Value(nextRetry),
            attempts: Value(item.attempts + 1),
            status: Value(QueueStatus.failed),
          ));

          await _logSyncError(
            'sync_message',
            'HTTP ${response.statusCode} for message ${message.messageId}: ${response.body}',
          );
        }
      } catch (e) {
        await _logSyncError('process_queue', e.toString());

        // Mark as failed but allow retry
        await _queueDao.updateQueueItem(QueueItemsCompanion(
          id: Value(item.id),
          messageId: Value(item.messageId),
          targetId: Value(item.targetId),
          nextAttempt: Value(item.nextAttempt),
          attempts: Value(item.attempts),
          status: Value(QueueStatus.failed),
        ));
      }
    }
  }

  Future<void> _logSyncSuccess(String operation, String details) async {
    await _syncLogDao.insertSyncLog(SyncLogsCompanion.insert(
      messageId: '',
      operation: operation,
      timestamp: DateTime.now(),
      status: 'success',
    ));
  }

  Future<void> _logSyncError(String operation, String error) async {
    await _syncLogDao.insertSyncLog(SyncLogsCompanion.insert(
      messageId: '',
      operation: operation,
      timestamp: DateTime.now(),
      status: 'error',
      error: Value(error),
    ));
  }

  void dispose() {
    _client.close();
  }
}