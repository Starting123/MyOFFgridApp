import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/error_providers.dart';
import '../../services/error_handler_service.dart';

/// Production-ready error display widgets
/// Provides user-friendly error notifications and recovery options

class ErrorBoundaryWidget extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorBoundaryState = ref.watch(errorBoundaryProvider);

    if (errorBoundaryState.hasError) {
      return fallback ?? _buildErrorFallback(context, ref);
    }

    return child;
  }

  Widget _buildErrorFallback(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Something went wrong'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The app encountered an unexpected error. Please try restarting.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(errorBoundaryProvider.notifier).recover();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorNotificationOverlay extends ConsumerWidget {
  const ErrorNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorDisplayState = ref.watch(errorDisplayProvider);
    final networkState = ref.watch(networkStateProvider);

    return Stack(
      children: [
        // Network status indicator
        networkState.when(
          data: (state) => _buildNetworkIndicator(context, state),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        // Error notifications
        if (errorDisplayState.visibleErrors.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: Column(
              children: errorDisplayState.visibleErrors
                  .map((error) => _buildErrorNotification(context, ref, error))
                  .toList(),
            ),
          ),
        
        // Critical error dialog
        if (errorDisplayState.showErrorDialog && errorDisplayState.currentError != null)
          _buildErrorDialog(context, ref, errorDisplayState.currentError!),
      ],
    );
  }

  Widget _buildNetworkIndicator(BuildContext context, NetworkState state) {
    if (state == NetworkState.online) {
      return const SizedBox.shrink();
    }

    Color color;
    String message;
    IconData icon;

    switch (state) {
      case NetworkState.offline:
        color = Colors.red;
        message = 'No connection';
        icon = Icons.wifi_off;
        break;
      case NetworkState.limited:
        color = Colors.orange;
        message = 'Limited connection';
        icon = Icons.wifi_1_bar;
        break;
      case NetworkState.unknown:
        color = Colors.grey;
        message = 'Connection status unknown';
        icon = Icons.help_outline;
        break;
      case NetworkState.online:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: color,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorNotification(BuildContext context, WidgetRef ref, AppError error) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (error.severity) {
      case ErrorSeverity.info:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.info_outline;
        break;
      case ErrorSeverity.warning:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.warning_outlined;
        break;
      case ErrorSeverity.error:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.error_outline;
        break;
      case ErrorSeverity.critical:
        backgroundColor = Colors.red[200]!;
        textColor = Colors.red[900]!;
        icon = Icons.dangerous_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error.source.toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      error.message,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                    if (error.recoveryActions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          children: error.recoveryActions
                              .take(2) // Show max 2 actions
                              .map((action) => _buildRecoveryButton(context, ref, action))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(errorDisplayProvider.notifier).hideError(error.id);
                },
                icon: Icon(Icons.close, color: textColor, size: 20),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryButton(BuildContext context, WidgetRef ref, RecoveryAction action) {
    return ElevatedButton(
      onPressed: () async {
        final recoveryHandler = ref.read(recoveryActionProvider);
        final success = await recoveryHandler.executeRecovery(action);
        
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recovery action completed: ${action.description}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 28),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(action.description),
    );
  }

  Widget _buildErrorDialog(BuildContext context, WidgetRef ref, AppError error) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dangerous,
                size: 48,
                color: Colors.red[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Critical Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (error.recoveryActions.isNotEmpty) ...[
                Text(
                  'Available recovery options:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...error.recoveryActions.map((action) => 
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        final recoveryHandler = ref.read(recoveryActionProvider);
                        await recoveryHandler.executeRecovery(action);
                        ref.read(errorDisplayProvider.notifier).hideErrorDialog();
                      },
                      child: Text(action.description),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                onPressed: () {
                  ref.read(errorDisplayProvider.notifier).hideErrorDialog();
                },
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Service health indicator widget
class ServiceHealthIndicator extends ConsumerWidget {
  const ServiceHealthIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceHealth = ref.watch(serviceHealthProvider);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...serviceHealth.entries.map((entry) =>
              _buildServiceRow(context, entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(BuildContext context, String serviceName, ServiceHealth health) {
    Color color;
    IconData icon;
    String status;

    switch (health) {
      case ServiceHealth.healthy:
        color = Colors.green;
        icon = Icons.check_circle;
        status = 'Healthy';
        break;
      case ServiceHealth.degraded:
        color = Colors.orange;
        icon = Icons.warning;
        status = 'Degraded';
        break;
      case ServiceHealth.unhealthy:
        color = Colors.red;
        icon = Icons.error;
        status = 'Unhealthy';
        break;
      case ServiceHealth.unknown:
        color = Colors.grey;
        icon = Icons.help;
        status = 'Unknown';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              serviceName.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}