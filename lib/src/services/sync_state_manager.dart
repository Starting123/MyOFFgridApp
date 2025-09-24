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

  SyncStateManager(AppDatabase db) {
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
      // Simplified health check without sync logs
      final timeSinceLastSync = _lastSyncAttempt != null 
          ? DateTime.now().difference(_lastSyncAttempt!)
          : Duration(hours: 24);
        
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
    } catch (e) {
      debugPrint('Error checking sync health: $e');
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
    // Simplified stats without sync logs
    return {
      'total': 0,
      'success': 0,
      'error': 0,
    };
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _eventController.close();
    super.dispose();
  }
}