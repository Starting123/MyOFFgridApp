import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/db.dart';
import 'cloud_sync.dart';

class SyncService {
  final AppDatabase db;
  final CloudSync _cloudSync;
  Timer? _syncTimer;
  bool _processing = false;

  SyncService(this.db) : _cloudSync = CloudSync(db) {
    // Start sync timer - every 5 minutes
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) => syncToCloud());
  }

  /// Queue a message for syncing (simplified - just mark as unsynced)
  Future<void> queueMessage(int messageId) async {
    try {
      await db.updateMessageSyncStatus(messageId, false);
    } catch (e) {
      debugPrint('Error queuing message: $e');
    }
  }

  /// Process sync to cloud
  Future<void> syncToCloud() async {
    if (_processing) return;
    _processing = true;

    try {
      await _cloudSync.sync();
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _processing = false;
    }
  }

  /// Manual sync trigger
  Future<bool> forcePush() async {
    try {
      await _cloudSync.pushMessages();
      return true;
    } catch (e) {
      debugPrint('Force push error: $e');
      return false;
    }
  }

  /// Manual pull trigger
  Future<bool> forcePull() async {
    try {
      await _cloudSync.pullMessages();
      return true;
    } catch (e) {
      debugPrint('Force pull error: $e');
      return false;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _cloudSync.dispose();
  }
}