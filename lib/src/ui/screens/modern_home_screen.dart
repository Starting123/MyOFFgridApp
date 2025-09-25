import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/real_device_providers.dart';
import '../../utils/permission_helper.dart';
import 'modern_settings_screen.dart';
import 'modern_devices_screen.dart';
import 'modern_chat_screen.dart';

class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(realSOSActiveProvider);
    final nearbyDevices = ref.watch(realNearbyDevicesProvider);
    final userInfo = ref.watch(userInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with user info and settings
                _buildHeader(userInfo),
                const SizedBox(height: 20),
                
                // Emergency SOS Button (Main Feature)
                _buildSOSButton(sosState),
                const SizedBox(height: 30),
                
                // Status Dashboard
                _buildStatusDashboard(nearbyDevices),
                const SizedBox(height: 20),
                
                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 20),
                
                // Recent Activity
                _buildRecentActivity(),
                const SizedBox(height: 20),
                
                // Footer
                _buildFooterInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue userInfo) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4FF).withOpacity(0.2),
                  const Color(0xFF5B86E5).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF00D4FF),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Off-Grid SOS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                userInfo.when(
                  data: (info) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สวัสดี, ${info['name']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PermissionHelper.buildPermissionStatus(context),
                    ],
                  ),
                  loading: () => Text(
                    'กำลังโหลด...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  error: (_, __) => Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Navigate to Settings screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModernSettingsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(bool sosState) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: sosState ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _handleSOSToggle,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: sosState
                      ? [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFFF5252),
                          const Color(0xFFD32F2F),
                        ]
                      : [
                          const Color(0xFF00D4FF),
                          const Color(0xFF5B86E5),
                          const Color(0xFF3F51B5),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: sosState
                        ? const Color(0xFFFF6B6B).withOpacity(0.4)
                        : const Color(0xFF00D4FF).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sosState ? Icons.warning_rounded : Icons.shield_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sosState ? 'SOS ACTIVE' : 'EMERGENCY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    sosState ? 'แตะเพื่อปิด' : 'แตะเพื่อขอความช่วยเหลือ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
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

  Widget _buildStatusDashboard(List<RealNearbyDevice> nearbyDevices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // First row - Connection Status
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'อุปกรณ์ใกล้เคียง',
                  '${nearbyDevices.length}',
                  Icons.devices_other_rounded,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'สถานะการเชื่อมต่อ',
                  nearbyDevices.any((d) => d.status == DeviceConnectionStatus.connected) ? 'เชื่อมต่อแล้ว' : 'ไม่ได้เชื่อมต่อ',
                  Icons.wifi_rounded,
                  nearbyDevices.any((d) => d.status == DeviceConnectionStatus.connected) 
                      ? const Color(0xFF4CAF50) 
                      : const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Second row - Message & Emergency Status
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'ข้อความรอส่ง',
                  '0', // TODO: Get from message queue
                  Icons.message_outlined,
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'โหมดฉุกเฉิน',
                  ref.watch(realSOSActiveProvider) ? 'เปิดใช้งาน' : 'ปิดใช้งาน',
                  Icons.emergency,
                  ref.watch(realSOSActiveProvider) ? const Color(0xFFFF6B6B) : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickAction(
        icon: Icons.message_rounded,
        label: 'ส่งข้อความ',
        color: const Color(0xFF4CAF50),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernChatScreen(),
            ),
          );
        },
      ),
      QuickAction(
        icon: Icons.search_rounded,
        label: 'ค้นหาอุปกรณ์',
        color: const Color(0xFF9C27B0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernDevicesScreen(),
            ),
          );
        },
      ),
      QuickAction(
        icon: Icons.settings_rounded,
        label: 'ตั้งค่า',
        color: const Color(0xFFFF9800),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernSettingsScreen(),
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions.map((action) => _buildQuickActionButton(action)).toList(),
      ),
    );
  }

  Widget _buildQuickActionButton(QuickAction action) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        action.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              action.color.withOpacity(0.2),
              action.color.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: action.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              action.icon,
              color: action.color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ระบบพร้อมใช้งาน',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: const Color(0xFF00D4FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'กิจกรรมล่าสุด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActivityItem('ระบบเริ่มทำงาน', 'เมื่อ 2 นาทีที่แล้ว', Icons.power_settings_new),
            _buildActivityItem('ค้นหาอุปกรณ์ใกล้เคียง', 'เมื่อ 1 นาทีที่แล้ว', Icons.search),
            _buildActivityItem('เชื่อมต่อสำเร็จ', 'เมื่อ 30 วินาทีที่แล้ว', Icons.check_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00D4FF).withOpacity(0.2),
            ),
            child: Icon(
              icon,
              size: 12,
              color: const Color(0xFF00D4FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSOSToggle() async {
    HapticFeedback.heavyImpact();
    try {
      await ref.read(realSOSActiveProvider.notifier).toggle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}