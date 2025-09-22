import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/db.dart';

/// Represents the current sync state
enum SyncState {
  idle,
  syncing,
  error,
  retrying,
  noConnection
}

/// Sync state change event
class SyncEvent {
  final SyncState state;
  final String operation;
  final String? message;
  final DateTime timestamp;

  SyncEvent({
    required this.state,
    required this.operation,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service for managing and monitoring sync state
class SyncStateManager with ChangeNotifier {
  final SyncLogDao _syncLogDao;
  final StreamController<SyncEvent> _eventController = StreamController<SyncEvent>.broadcast();
  
  SyncState _currentState = SyncState.idle;
  String? _lastError;
  DateTime? _lastSyncAttempt;
  Timer? _monitoringTimer;
  
  Stream<SyncEvent> get events => _eventController.stream;
  SyncState get currentState => _currentState;
  String? get lastError => _lastError;
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  bool get isSyncing => _currentState == SyncState.syncing;

  SyncStateManager(AppDatabase db) : _syncLogDao = db.syncLogDao {
    // Start monitoring sync health
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSyncHealth(),
    );
  }

  /// Record the start of a sync operation
  void recordSyncStart(String operation) {
    _lastSyncAttempt = DateTime.now();
    _setState(SyncState.syncing, operation);
  }

  /// Record a successful sync operation
  void recordSyncSuccess(String operation) {
    _setState(SyncState.idle, operation);
    _lastError = null;
  }

  /// Record a sync error
  void recordSyncError(String operation, String error) {
    _lastError = error;
    _setState(SyncState.error, operation, error);
  }

  /// Record a connection state change
  void recordConnectionState(bool connected) {
    if (!connected && _currentState != SyncState.noConnection) {
      _setState(SyncState.noConnection, 'connection', 'No network connection');
    } else if (connected && _currentState == SyncState.noConnection) {
      _setState(SyncState.idle, 'connection', 'Connection restored');
    }
  }

  /// Check sync health periodically
  Future<void> _checkSyncHealth() async {
    try {
      final lastLog = await _syncLogDao.getLatestSyncLog('health_check');
      if (lastLog != null) {
        final timeSinceLastSync = DateTime.now().difference(lastLog.timestamp);
        
        // If last sync was over 15 minutes ago and we're not in an error state
        if (timeSinceLastSync > const Duration(minutes: 15) &&
            _currentState != SyncState.error &&
            _currentState != SyncState.noConnection) {
          _setState(
            SyncState.retrying,
            'health_check',
            'Sync overdue - last sync was ${timeSinceLastSync.inMinutes} minutes ago',
          );
        }
      }
    } catch (e) {
      print('Error checking sync health: $e');
    }
  }

  /// Update the current state and notify listeners
  void _setState(SyncState state, String operation, [String? message]) {
    _currentState = state;
    notifyListeners();
    
    _eventController.add(SyncEvent(
      state: state,
      operation: operation,
      message: message,
    ));
  }

  /// Get sync stats for the last N hours
  Future<Map<String, int>> getSyncStats(int hours) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(hours: hours));
    
    // Query logs since the specified time
    final logs = await _syncLogDao.getLogsSince(since);
    
    // Count stats
    final stats = {
      'total': logs.length,
      'success': logs.where((l) => l.status == 'success').length,
      'error': logs.where((l) => l.status == 'error').length,
    };
    
    return stats;
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _eventController.close();
    super.dispose();
  }
}