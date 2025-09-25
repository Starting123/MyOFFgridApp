import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Show a dialog explaining why permissions are needed
  static Future<void> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required List<Permission> permissions,
    VoidCallback? onSettingsPressed,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Row(
            children: [
              const Icon(
                Icons.security,
                color: Color(0xFF00D4FF),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'สิทธิ์ที่จำเป็น:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...permissions.map((permission) => _buildPermissionItem(permission)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ข้าม',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onSettingsPressed != null) {
                  onSettingsPressed();
                } else {
                  openAppSettings();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
              ),
              child: const Text(
                'เปิดการตั้งค่า',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildPermissionItem(Permission permission) {
    String name;
    String description;
    IconData icon;

    switch (permission) {
      case Permission.location:
        name = 'ตำแหน่งที่อยู่';
        description = 'ค้นหาอุปกรณ์ใกล้เคียงและส่งตำแหน่งใน SOS';
        icon = Icons.location_on;
        break;
      case Permission.locationAlways:
        name = 'ตำแหน่งในพื้นหลัง';
        description = 'ทำงานต่อเนื่องแม้แอปไม่ได้เปิด';
        icon = Icons.my_location;
        break;
      case Permission.storage:
        name = 'พื้นที่จัดเก็บ';
        description = 'บันทึกข้อความและไฟล์';
        icon = Icons.storage;
        break;
      case Permission.bluetoothConnect:
        name = 'Bluetooth';
        description = 'เชื่อมต่อกับอุปกรณ์ผ่าน Bluetooth';
        icon = Icons.bluetooth;
        break;
      default:
        name = permission.toString().split('.').last;
        description = 'จำเป็นสำหรับการทำงานของแอป';
        icon = Icons.security;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF00D4FF),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check if essential permissions are granted
  static Future<bool> checkEssentialPermissions() async {
    final essentialPermissions = [
      Permission.location,
      Permission.locationWhenInUse,
    ];

    for (final permission in essentialPermissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }

  /// Show permission status widget
  static Widget buildPermissionStatus(BuildContext context) {
    return FutureBuilder<Map<Permission, PermissionStatus>>(
      future: _getPermissionStatuses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final statuses = snapshot.data!;
        final grantedCount = statuses.values.where((s) => s.isGranted).length;
        final totalCount = statuses.length;

        Color statusColor;
        String statusText;
        
        if (grantedCount >= totalCount - 1) {
          statusColor = const Color(0xFF4CAF50);
          statusText = 'พร้อมใช้งาน';
        } else if (grantedCount >= totalCount / 2) {
          statusColor = const Color(0xFFFF9800);
          statusText = 'ใช้งานจำกัด';
        } else {
          statusColor = const Color(0xFFFF6B6B);
          statusText = 'ต้องการสิทธิ์';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: statusColor.withOpacity(0.2),
            border: Border.all(
              color: statusColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                size: 14,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' ($grantedCount/$totalCount)',
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<Map<Permission, PermissionStatus>> _getPermissionStatuses() async {
    final permissions = [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.locationAlways,
      Permission.storage,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ];

    final Map<Permission, PermissionStatus> result = {};
    for (final permission in permissions) {
      result[permission] = await permission.status;
    }
    return result;
  }
}