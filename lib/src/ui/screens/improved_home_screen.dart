import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/real_device_providers.dart';
import '../../providers/enhanced_chat_provider.dart';
import 'real_device_list_screen.dart';
import 'user_settings_screen.dart';
import 'chat_screen.dart';
import 'enhanced_sos_screen.dart';

class ImprovedHomeScreen extends ConsumerStatefulWidget {
  const ImprovedHomeScreen({super.key});

  @override
  ConsumerState<ImprovedHomeScreen> createState() => _ImprovedHomeScreenState();
}

class _ImprovedHomeScreenState extends ConsumerState<ImprovedHomeScreen> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(realSOSActiveProvider);
    final userInfo = ref.watch(userInfoProvider);
    final nearbyDevices = ref.watch(realNearbyDevicesProvider);
    final rescuerMode = ref.watch(realRescuerModeProvider);
    final chatState = ref.watch(enhancedChatProvider);

    final isSOSActive = sosState;
    final isRescuerActive = rescuerMode;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: isSOSActive ? Colors.red[700] : isRescuerActive ? Colors.blue[700] : Colors.indigo[700],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isSOSActive ? '🆘 SOS MODE' : isRescuerActive ? '🚑 RESCUER MODE' : '📡 OFF-GRID SOS',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSOSActive 
                        ? [Colors.red[700]!, Colors.red[900]!]
                        : isRescuerActive 
                            ? [Colors.blue[700]!, Colors.blue[900]!]
                            : [Colors.indigo[700]!, Colors.indigo[900]!],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      if (isSOSActive || isRescuerActive)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Icon(
                                isSOSActive ? Icons.sos : Icons.medical_services,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      else
                        const Icon(
                          Icons.wifi_tethering,
                          size: 60,
                          color: Colors.white,
                        ),
                      const SizedBox(height: 8),
                      userInfo.when(
                        data: (info) => Text(
                          'สวัสดี ${info['name']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        loading: () => const Text(
                          'กำลังโหลด...',
                          style: TextStyle(color: Colors.white),
                        ),
                        error: (_, __) => const Text(
                          'ผู้ใช้ไม่ระบุ',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.devices, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RealDeviceListScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
                ),
              ),
            ],
          ),
          
          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Status Cards Row
                  Row(
                    children: [
                      // Connection Status
                      Expanded(
                        child: _buildStatusCard(
                          title: 'เชื่อมต่อ',
                          value: '${nearbyDevices.length}',
                          subtitle: 'อุปกรณ์',
                          icon: Icons.devices,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Messages Status
                      Expanded(
                        child: _buildStatusCard(
                          title: 'ข้อความ',
                          value: chatState.when(
                            data: (state) => '${state.messages.length}',
                            loading: () => '...',
                            error: (_, __) => '0',
                          ),
                          subtitle: 'รายการ',
                          icon: Icons.message,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // SOS Control Panel
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emergency,
                                color: Colors.red[700],
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'ระบบช่วยเหลือฉุกเฉิน',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // SOS Victim Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EnhancedSOSScreen(),
                                ),
                              ),
                              icon: Icon(
                                isSOSActive ? Icons.stop : Icons.sos,
                                size: 28,
                              ),
                              label: Text(
                                isSOSActive ? 'หยุด SOS (ผู้ประสบภัย)' : 'เรียกความช่วยเหลือ (SOS)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSOSActive ? Colors.red[700] : Colors.red[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Rescuer Mode Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await ref.read(realRescuerModeProvider.notifier).toggle();
                              },
                              icon: Icon(
                                isRescuerActive ? Icons.stop : Icons.medical_services,
                                size: 28,
                              ),
                              label: Text(
                                isRescuerActive ? 'หยุดโหมดกู้ภัย' : 'เปิดโหมดหน่วยกู้ภัย',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isRescuerActive ? Colors.blue[700] : Colors.blue[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'การทำงานหลัก',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildQuickAction(
                                icon: Icons.chat,
                                label: 'แชท',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChatScreen(),
                                  ),
                                ),
                              ),
                              _buildQuickAction(
                                icon: Icons.device_hub,
                                label: 'อุปกรณ์',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RealDeviceListScreen(),
                                  ),
                                ),
                              ),
                              _buildQuickAction(
                                icon: Icons.settings,
                                label: 'ตั้งค่า',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const UserSettingsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Status Information
                  _buildStatusInfo(context, isSOSActive, nearbyDevices.length),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.indigo[700]),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(
    BuildContext context,
    bool isSOSActive,
    int deviceCount,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สถานะระบบ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'โหมด SOS:', 
              isSOSActive ? 'ผู้ประสบภัย (RED)' : 'ปกติ',
              isSOSActive ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'อุปกรณ์ใกล้เคียง:', 
              '$deviceCount อุปกรณ์',
              deviceCount > 0 ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}