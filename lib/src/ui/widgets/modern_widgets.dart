import 'package:flutter/material.dart';
import '../../models/chat_models.dart';

/// Modern reusable widgets for the Off-Grid SOS app
class ModernWidgets {
  
  /// Large SOS Toggle Button
  static Widget sosToggleButton({
    required bool isVictim,
    required bool isActive,
    required VoidCallback onPressed,
    double size = 200,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isVictim ? Colors.red : Colors.blue).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: isActive ? 10 : 0,
          ),
        ],
      ),
      child: Material(
        color: isActive 
          ? (isVictim ? Colors.red.shade600 : Colors.blue.shade600)
          : Colors.grey.shade300,
        shape: const CircleBorder(),
        elevation: isActive ? 8 : 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isVictim ? Icons.emergency : Icons.local_hospital,
                size: size * 0.3,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                isVictim ? 'SOS' : 'RESCUE',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isVictim ? 'VICTIM' : 'AVAILABLE',
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.grey.shade500,
                  fontSize: size * 0.05,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Message Bubble with Status
  static Widget messageBubble({
    required ChatMessage message,
    required bool isMe,
    VoidCallback? onTap,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe 
              ? message.isEmergency 
                ? Colors.red.shade400
                : Colors.blue.shade500
              : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isEmergency) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency, 
                      color: Colors.white, 
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EMERGENCY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(message.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Device List Tile with Role Indicator
  static Widget deviceListTile({
    required String deviceName,
    required DeviceRole role,
    required bool isConnected,
    required VoidCallback onConnect,
    String? lastSeen,
    double? distance,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getRoleColor(role).withOpacity(0.1),
            border: Border.all(
              color: _getRoleColor(role),
              width: 2,
            ),
          ),
          child: Icon(
            _getRoleIcon(role),
            color: _getRoleColor(role),
            size: 24,
          ),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getRoleText(role),
              style: TextStyle(
                color: _getRoleColor(role),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (distance != null)
              Text(
                '~${distance.toStringAsFixed(0)}m away',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            if (lastSeen != null)
              Text(
                'Last seen: $lastSeen',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isConnected ? 'Connected' : 'Connect',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: onConnect,
      ),
    );
  }

  /// Status Card for Home Screen
  static Widget statusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Connection Status Indicator
  static Widget connectionStatusBanner({
    required bool isOnline,
    required int connectedDevices,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.shade500 : Colors.orange.shade500,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOnline 
                ? 'Online • $connectedDevices devices nearby'
                : 'Offline • $connectedDevices devices connected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  static String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  static Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.schedule, color: Colors.white70, size: 14);
      case MessageStatus.sent:
        return Icon(Icons.check, color: Colors.white70, size: 14);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, color: Colors.white70, size: 14);
      case MessageStatus.read:
        return Icon(Icons.done_all, color: Colors.white, size: 14);
      case MessageStatus.synced:
        return Icon(Icons.cloud_done, color: Colors.white70, size: 14);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, color: Colors.red.shade200, size: 14);
    }
  }

  static Color _getRoleColor(DeviceRole role) {
    switch (role) {
      case DeviceRole.sosUser:
        return Colors.red.shade600;
      case DeviceRole.rescuer:
        return Colors.blue.shade600;
      case DeviceRole.normal:
        return Colors.green.shade600;
    }
  }

  static IconData _getRoleIcon(DeviceRole role) {
    switch (role) {
      case DeviceRole.sosUser:
        return Icons.emergency;
      case DeviceRole.rescuer:
        return Icons.local_hospital;
      case DeviceRole.normal:
        return Icons.person;
    }
  }

  static String _getRoleText(DeviceRole role) {
    switch (role) {
      case DeviceRole.sosUser:
        return 'NEEDS HELP';
      case DeviceRole.rescuer:
        return 'RESCUER';
      case DeviceRole.normal:
        return 'Available';
    }
  }
}