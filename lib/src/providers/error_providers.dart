import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/error_handler_service.dart';

/// Production-ready error handling providers
/// Provides comprehensive error management, user feedback, and recovery mechanisms

// Error handler service provider
final errorHandlerProvider = Provider<ErrorHandlerService>((ref) {
  return ErrorHandlerService.instance;
});

// Error stream provider for real-time error notifications
final errorStreamProvider = StreamProvider<AppError>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return errorHandler.errorStream;
});

// Network state provider
final networkStateProvider = StreamProvider<NetworkState>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return errorHandler.networkStateStream;
});

// Error statistics provider
final errorStatsProvider = Provider<ErrorStatistics>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return errorHandler.getErrorStatistics();
});

// Error display state for UI
final errorDisplayProvider = NotifierProvider<ErrorDisplayNotifier, ErrorDisplayState>(() {
  return ErrorDisplayNotifier();
});

class ErrorDisplayState {
  final List<AppError> visibleErrors;
  final bool showErrorDialog;
  final AppError? currentError;
  final bool autoHideEnabled;

  const ErrorDisplayState({
    this.visibleErrors = const [],
    this.showErrorDialog = false,
    this.currentError,
    this.autoHideEnabled = true,
  });

  ErrorDisplayState copyWith({
    List<AppError>? visibleErrors,
    bool? showErrorDialog,
    AppError? currentError,
    bool? autoHideEnabled,
  }) {
    return ErrorDisplayState(
      visibleErrors: visibleErrors ?? this.visibleErrors,
      showErrorDialog: showErrorDialog ?? this.showErrorDialog,
      currentError: currentError ?? this.currentError,
      autoHideEnabled: autoHideEnabled ?? this.autoHideEnabled,
    );
  }
}

class ErrorDisplayNotifier extends Notifier<ErrorDisplayState> {
  @override
  ErrorDisplayState build() {
    // Listen to error stream and update display state
    ref.listen(errorStreamProvider, (previous, next) {
      next.when(
        data: (error) => _handleNewError(error),
        loading: () => {},
        error: (err, stack) => {},
      );
    });

    return const ErrorDisplayState();
  }

  void _handleNewError(AppError error) {
    final currentState = state;
    
    // Add to visible errors if it's important enough
    if (error.severity == ErrorSeverity.error || error.severity == ErrorSeverity.critical) {
      final updatedErrors = [...currentState.visibleErrors, error];
      
      // Keep only last 5 errors visible
      final visibleErrors = updatedErrors.length > 5 
          ? updatedErrors.skip(updatedErrors.length - 5).toList()
          : updatedErrors;
      
      state = currentState.copyWith(
        visibleErrors: visibleErrors,
        showErrorDialog: error.severity == ErrorSeverity.critical,
        currentError: error,
      );

      // Auto-hide non-critical errors after delay
      if (error.severity != ErrorSeverity.critical && currentState.autoHideEnabled) {
        Future.delayed(const Duration(seconds: 5), () {
          hideError(error.id);
        });
      }
    }
  }

  void showErrorDialog(AppError error) {
    state = state.copyWith(
      showErrorDialog: true,
      currentError: error,
    );
  }

  void hideErrorDialog() {
    state = state.copyWith(
      showErrorDialog: false,
      currentError: null,
    );
  }

  void hideError(String errorId) {
    final updatedErrors = state.visibleErrors
        .where((error) => error.id != errorId)
        .toList();
    
    state = state.copyWith(visibleErrors: updatedErrors);
  }

  void clearAllErrors() {
    state = const ErrorDisplayState();
  }

  void toggleAutoHide() {
    state = state.copyWith(autoHideEnabled: !state.autoHideEnabled);
  }
}

// Recovery action provider
final recoveryActionProvider = Provider<RecoveryActionHandler>((ref) {
  return RecoveryActionHandler(ref.read(errorHandlerProvider));
});

class RecoveryActionHandler {
  final ErrorHandlerService _errorHandler;

  RecoveryActionHandler(this._errorHandler);

  Future<bool> executeRecovery(RecoveryAction action) async {
    return await _errorHandler.executeRecoveryAction(action);
  }

  void reportError(
    String source,
    dynamic error, {
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.warning,
    Map<String, dynamic>? context,
    bool canRecover = true,
  }) {
    _errorHandler.reportError(
      source,
      error,
      stackTrace: stackTrace,
      severity: severity,
      context: context,
      canRecover: canRecover,
    );
  }

  void updateNetworkState(NetworkState state) {
    _errorHandler.updateNetworkState(state);
  }
}

// Service health provider
final serviceHealthProvider = Provider<Map<String, ServiceHealth>>((ref) {
  // This would integrate with ServiceCoordinator to get actual service health
  return {
    'nearby': ServiceHealth.healthy,
    'p2p': ServiceHealth.degraded,
    'ble': ServiceHealth.unhealthy,
    'location': ServiceHealth.healthy,
    'database': ServiceHealth.healthy,
    'cloud': ServiceHealth.degraded,
  };
});

enum ServiceHealth {
  healthy,   // Service working normally
  degraded,  // Service working but with issues
  unhealthy, // Service not working
  unknown    // Service status unknown
}

// Global error boundary provider
final errorBoundaryProvider = NotifierProvider<ErrorBoundaryNotifier, ErrorBoundaryState>(() {
  return ErrorBoundaryNotifier();
});

class ErrorBoundaryState {
  final bool hasError;
  final String? errorMessage;
  final bool canRecover;
  final DateTime? errorTime;

  const ErrorBoundaryState({
    this.hasError = false,
    this.errorMessage,
    this.canRecover = true,
    this.errorTime,
  });

  ErrorBoundaryState copyWith({
    bool? hasError,
    String? errorMessage,
    bool? canRecover,
    DateTime? errorTime,
  }) {
    return ErrorBoundaryState(
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      canRecover: canRecover ?? this.canRecover,
      errorTime: errorTime ?? this.errorTime,
    );
  }
}

class ErrorBoundaryNotifier extends Notifier<ErrorBoundaryState> {
  @override
  ErrorBoundaryState build() {
    return const ErrorBoundaryState();
  }

  void catchError(dynamic error, StackTrace stackTrace) {
    final errorHandler = ref.read(errorHandlerProvider);
    
    errorHandler.reportError(
      'error_boundary',
      error,
      stackTrace: stackTrace,
      severity: ErrorSeverity.critical,
      canRecover: true,
    );

    state = state.copyWith(
      hasError: true,
      errorMessage: error.toString(),
      canRecover: true,
      errorTime: DateTime.now(),
    );
  }

  void recover() {
    state = const ErrorBoundaryState();
  }
}