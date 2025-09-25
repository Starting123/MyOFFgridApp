import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SharedComponents {
  /// Status indicator for connection/service status
  static Widget statusIndicator({
    required bool isConnected,
    required bool isSOSActive,
    required bool isRescuerActive,
  }) {
    String status = 'Offline';
    Color color = AppTheme.connectionStatusColors['disconnected']!;
    IconData icon = Icons.wifi_off;
    
    if (isSOSActive) {
      status = 'SOS Active';
      color = AppTheme.connectionStatusColors['sos_active']!;
      icon = Icons.emergency;
    } else if (isRescuerActive) {
      status = 'Rescuer Mode';
      color = AppTheme.connectionStatusColors['rescuer_active']!;
      icon = Icons.security;
    } else if (isConnected) {
      status = 'Connected';
      color = AppTheme.connectionStatusColors['connected']!;
      icon = Icons.wifi;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Connection banner for status display
  static Widget connectionBanner({
    required BuildContext context,
    required bool isConnected,
    required int deviceCount,
  }) {
    final backgroundColor = isConnected 
        ? AppTheme.connectionStatusColors['connected']!.withValues(alpha: 0.1)
        : AppTheme.connectionStatusColors['disconnected']!.withValues(alpha: 0.1);
    final textColor = isConnected 
        ? AppTheme.connectionStatusColors['connected']!
        : AppTheme.connectionStatusColors['disconnected']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected 
                  ? '$deviceCount device(s) connected'
                  : 'No devices connected',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loading indicator with message
  static Widget loadingIndicator({
    required String message,
    Color? color,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: color ?? AppTheme.connectionStatusColors['sos_active']!,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: color ?? AppTheme.connectionStatusColors['sos_active']!,
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state widget
  static Widget emptyState({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Device card for displaying nearby devices
  static Widget deviceCard({
    required BuildContext context,
    required String deviceName,
    required String deviceType,
    required String status,
    required VoidCallback onTap,
    String? lastSeen,
    int? signalStrength,
    bool isSOSActive = false,
    bool isRescuerActive = false,
    bool isConnected = false,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deviceName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  statusIndicator(
                    isConnected: isConnected,
                    isSOSActive: isSOSActive,
                    isRescuerActive: isRescuerActive,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                deviceType,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (lastSeen != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Last seen: $lastSeen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
              if (signalStrength != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Signal: ${signalStrength}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Emergency button with pulsing animation
  static Widget emergencyButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required Animation<double> animation,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? 1.0 + (animation.value * 0.1) : 1.0,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.emergencyGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.connectionStatusColors['sos_active']!.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}