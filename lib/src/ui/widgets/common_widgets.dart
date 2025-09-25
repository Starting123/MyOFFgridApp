import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Common UI widgets for the Off-Grid SOS app
/// These widgets ensure consistency across all screens

/// Connection status indicator widget
class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;
  final int connectedDevices;
  final VoidCallback? onTap;

  const ConnectionStatusWidget({
    super.key,
    required this.isConnected,
    this.connectedDevices = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isConnected
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isConnected ? Colors.green : Colors.orange).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Connected' : 'Offline Mode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected 
                        ? '$connectedDevices devices nearby'
                        : 'Tap to scan for devices',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stats card widget for displaying numerical data
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = color ?? colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: cardColor,
                  size: 28,
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colorScheme.onSurface.withOpacity(0.4),
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cardColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action button widget for navigation and actions
class ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;
  final String? badge;

  const ActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buttonColor = color ?? colorScheme.primary;
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: buttonColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: buttonColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: buttonColor,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: buttonColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// SOS toggle widget for emergency mode
class SOSToggleWidget extends StatefulWidget {
  final String currentMode; // 'inactive', 'victim', 'rescuer'
  final ValueChanged<String> onModeChanged;
  final bool isAnimating;

  const SOSToggleWidget({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.isAnimating = false,
  });

  @override
  State<SOSToggleWidget> createState() => _SOSToggleWidgetState();
}

class _SOSToggleWidgetState extends State<SOSToggleWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SOSToggleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isAnimating && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            'Victim',
            Icons.emergency,
            Colors.red,
            'victim',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildToggleButton(
            'Rescuer',
            Icons.medical_services,
            Colors.blue,
            'rescuer',
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, IconData icon, Color color, String mode) {
    final isActive = widget.currentMode == mode;
    final isAnimating = isActive && widget.isAnimating;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isAnimating ? _pulseAnimation.value : 1.0,
          child: InkWell(
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onModeChanged(isActive ? 'inactive' : mode);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Message bubble component for chat interface
class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String status; // 'sending', 'sent', 'delivered', 'read'
  final String? senderName;
  final Color? senderColor;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.status,
    this.senderName,
    this.senderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: senderColor ?? colorScheme.primary,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe 
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(status),
                    size: 16,
                    color: _getStatusColor(status),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return Icons.access_time;
      case 'sent':
        return Icons.check;
      case 'delivered':
        return Icons.done_all;
      case 'read':
        return Icons.done_all;
      default:
        return Icons.error;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sending':
        return Colors.grey;
      case 'sent':
        return Colors.grey;
      case 'delivered':
        return Colors.blue;
      case 'read':
        return Colors.green;
      default:
        return Colors.red;
    }
  }
}

/// Device list tile for nearby devices screen
class DeviceListTile extends StatelessWidget {
  final String deviceName;
  final String deviceId;
  final String deviceType; // 'phone', 'tablet', 'unknown'
  final String role; // 'victim', 'rescuer', 'neutral'
  final String connectionStatus; // 'connected', 'connecting', 'disconnected'
  final int signalStrength; // 0-100
  final int? batteryLevel; // 0-100, null if unknown
  final bool isEncrypted;
  final DateTime lastSeen;
  final VoidCallback? onTap;
  final VoidCallback? onConnect;

  const DeviceListTile({
    super.key,
    required this.deviceName,
    required this.deviceId,
    required this.deviceType,
    required this.role,
    required this.connectionStatus,
    required this.signalStrength,
    required this.lastSeen,
    this.batteryLevel,
    this.isEncrypted = true,
    this.onTap,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: connectionStatus == 'connected'
            ? Border.all(color: Colors.green.withOpacity(0.5), width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getRoleColor(role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRoleColor(role).withOpacity(0.3),
                ),
              ),
              child: Icon(
                _getDeviceIcon(deviceType),
                color: _getRoleColor(role),
                size: 24,
              ),
            ),
            if (connectionStatus == 'connected')
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                deviceName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildRoleBadge(role),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getSignalIcon(signalStrength),
                  size: 16,
                  color: _getSignalColor(signalStrength),
                ),
                const SizedBox(width: 4),
                Text(
                  '${signalStrength}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSignalColor(signalStrength),
                  ),
                ),
                const SizedBox(width: 12),
                if (batteryLevel != null) ...[
                  Icon(
                    _getBatteryIcon(batteryLevel!),
                    size: 16,
                    color: _getBatteryColor(batteryLevel!),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${batteryLevel}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getBatteryColor(batteryLevel!),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  isEncrypted ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: isEncrypted ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getLastSeenText(lastSeen),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: connectionStatus == 'connected'
            ? null
            : ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(80, 36),
                ),
                child: Text(
                  connectionStatus == 'connecting' ? 'Connecting...' : 'Connect',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRoleColor(role).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(role),
            size: 12,
            color: _getRoleColor(role),
          ),
          const SizedBox(width: 4),
          Text(
            role.capitalize(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getRoleColor(role),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'victim':
        return Colors.red;
      case 'rescuer':
        return Colors.blue;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'victim':
        return Icons.emergency;
      case 'rescuer':
        return Icons.medical_services;
      case 'neutral':
      default:
        return Icons.person;
    }
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType) {
      case 'phone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'unknown':
      default:
        return Icons.device_unknown;
    }
  }

  IconData _getSignalIcon(int strength) {
    if (strength >= 75) return Icons.signal_cellular_4_bar;
    if (strength >= 50) return Icons.signal_cellular_alt;
    if (strength >= 25) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  Color _getSignalColor(int strength) {
    if (strength >= 75) return Colors.green;
    if (strength >= 50) return Colors.yellow;
    if (strength >= 25) return Colors.orange;
    return Colors.red;
  }

  IconData _getBatteryIcon(int level) {
    if (level >= 90) return Icons.battery_full;
    if (level >= 60) return Icons.battery_5_bar;
    if (level >= 30) return Icons.battery_3_bar;
    if (level >= 15) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(int level) {
    if (level >= 30) return Colors.green;
    if (level >= 15) return Colors.orange;
    return Colors.red;
  }

  String _getLastSeenText(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Status indicator widget for various states
class StatusIndicator extends StatelessWidget {
  final String status;
  final String label;
  final IconData? icon;
  final Color? color;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.label,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? _getStatusColor(status);
    final indicatorIcon = icon ?? _getStatusIcon(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            indicatorIcon,
            size: 16,
            color: indicatorColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'connected':
      case 'active':
        return Colors.green;
      case 'offline':
      case 'disconnected':
      case 'inactive':
        return Colors.grey;
      case 'connecting':
      case 'pending':
        return Colors.orange;
      case 'error':
      case 'failed':
        return Colors.red;
      case 'warning':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'connected':
      case 'active':
        return Icons.check_circle;
      case 'offline':
      case 'disconnected':
      case 'inactive':
        return Icons.offline_bolt;
      case 'connecting':
      case 'pending':
        return Icons.access_time;
      case 'error':
      case 'failed':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}

/// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}