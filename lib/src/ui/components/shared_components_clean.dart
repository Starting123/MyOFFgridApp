import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared UI components for consistent design across the Off-Grid SOS app
class SharedComponents {
  SharedComponents._(); // Private constructor
  
  /// Status indicator widget for connection, SOS, and other states
  static Widget statusIndicator({
    required String status,
    required String label,
    double size = 12,
    bool showLabel = true,
  }) {
    final color = AppTheme.connectionStatusColors[status] ?? 
                  const Color(0xFF757575);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// Connection status banner for top of screens
  static Widget connectionBanner({
    required BuildContext context,
    required int connectedDevices,
    required int nearbyDevices,
    required bool isSearching,
    VoidCallback? onRefresh,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: connectedDevices > 0 
            ? AppTheme.connectionStatusColors['connected']!.withOpacity(0.1)
            : AppTheme.connectionStatusColors['disconnected']!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connectedDevices > 0 
              ? AppTheme.connectionStatusColors['connected']!.withOpacity(0.3)
              : AppTheme.connectionStatusColors['disconnected']!.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          statusIndicator(
            status: connectedDevices > 0 ? 'connected' : 'disconnected',
            label: connectedDevices > 0 ? 'Connected' : 'Offline',
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$connectedDevices connected • $nearbyDevices nearby',
                  style: AppTheme.titleMedium,
                ),
                if (isSearching) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Searching for devices...',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  /// Loading indicator with message
  static Widget loadingIndicator({
    required BuildContext context,
    String message = 'Loading...',
    double size = 24,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Empty state with icon and message
  static Widget emptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodyMedium,
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
}