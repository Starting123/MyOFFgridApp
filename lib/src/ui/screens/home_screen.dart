import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_settings_screen.dart';
import 'real_device_list_screen.dart';
import '../../providers/real_device_providers.dart';

// Legacy model for nearby devices (kept for compatibility)
class NearbyDevice {
  final String id;
  final String name;
  final String type; // 'sos' or 'rescuer'

  NearbyDevice({required this.id, required this.name, required this.type});
}

// User info provider (kept as is)
final userInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'name': prefs.getString('user_name') ?? 'ไม่ได้ระบุชื่อ',
    'phone': prefs.getString('user_phone') ?? '',
    'deviceType': prefs.getString('device_type') ?? 'SOS',
  };
});

// Use real providers instead of mock ones
final sosActiveProvider = realSOSActiveProvider;
final rescuerModeProvider = realRescuerModeProvider;
final nearbyDevicesProvider = Provider<List<NearbyDevice>>((ref) {
  // Convert RealNearbyDevice to legacy NearbyDevice for UI compatibility
  final realDevices = ref.watch(realNearbyDevicesProvider);
  return realDevices.map((device) => NearbyDevice(
    id: device.id,
    name: device.name,
    type: device.type,
  )).toList();
});

// Old state notifiers removed - now using real providers from real_device_providers.dart

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosActive = ref.watch(sosActiveProvider);
    final rescuerMode = ref.watch(rescuerModeProvider);
    final nearbyDevices = ref.watch(nearbyDevicesProvider);
    final userInfoAsync = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: userInfoAsync.when(
          data: (userInfo) => Text('สวัสดี ${userInfo['name']}'),
          loading: () => const Text('Off-Grid SOS'),
          error: (_, __) => const Text('Off-Grid SOS'),
        ),
        backgroundColor: sosActive ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Device List Button
          IconButton(
            icon: const Icon(Icons.devices),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RealDeviceListScreen(),
                ),
              );
            },
            tooltip: 'อุปกรณ์ใกล้เคียง',
          ),
          // Settings Button  
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSettingsScreen(),
                ),
              ).then((_) {
                // Refresh user info after returning from settings
                ref.invalidate(userInfoProvider);
              });
            },
            tooltip: 'ตั้งค่า',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Status Card
            userInfoAsync.when(
              data: (userInfo) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getDeviceTypeColor(userInfo['deviceType']!),
                        child: Icon(
                          _getDeviceTypeIcon(userInfo['deviceType']!),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userInfo['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${userInfo['deviceType']} - ${userInfo['phone']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sosActive ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sosActive ? '🆘 SOS' : '✅ ปกติ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // SOS Button
            Expanded(
              flex: 2,
              child: Center(
                child: GestureDetector(
                  onTap: () async => await ref.read(sosActiveProvider.notifier).toggle(),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sosActive ? Colors.red : Colors.grey,
                      boxShadow: [
                        BoxShadow(
                          color: sosActive ? Colors.red.withValues(alpha: 0.3) : Colors.black12,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sosActive ? '🆘' : '🛡️',
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sosActive ? 'SOS' : 'SAFE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (sosActive)
                            const Text(
                              'แตะเพื่อหยุด',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Rescuer Mode Switch
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: rescuerMode ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rescuerMode ? Colors.blue : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_hospital,
                    color: rescuerMode ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'โหมดผู้ช่วยเหลือ',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: rescuerMode,
                    onChanged: (value) async => await ref.read(rescuerModeProvider.notifier).toggle(),
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),

            // Status and Instructions
            if (sosActive || rescuerMode)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sosActive 
                          ? '📱 กดปุ่ม "อุปกรณ์" ด้านบนเพื่อดูรายการผู้ช่วยเหลือ และเข้าแชท'
                          : '📱 กดปุ่ม "อุปกรณ์" ด้านบนเพื่อดูรายการผู้ขอความช่วยเหลือ',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RealDeviceListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.devices),
                    label: const Text('อุปกรณ์ใกล้เคียง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เปิดแผนที่...')),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('แผนที่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Nearby Devices Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.signal_cellular_4_bar, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'พบอุปกรณ์ ${nearbyDevices.length} เครื่อง',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RealDeviceListScreen(),
                        ),
                      );
                    },
                    child: const Text('ดูทั้งหมด'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDeviceTypeColor(String deviceType) {
    switch (deviceType) {
      case 'SOS':
        return Colors.red.shade600;
      case 'Rescuer':
        return Colors.blue.shade600;
      case 'Relay':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getDeviceTypeIcon(String deviceType) {
    switch (deviceType) {
      case 'SOS':
        return Icons.emergency;
      case 'Rescuer':
        return Icons.local_hospital;
      case 'Relay':
        return Icons.router;
      default:
        return Icons.device_unknown;
    }
  }
}