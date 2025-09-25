import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/main_providers.dart';
import '../../models/chat_models.dart';
import '../../services/location_service.dart';

class ModernSOSScreen extends ConsumerStatefulWidget {
  const ModernSOSScreen({super.key});

  @override
  ConsumerState<ModernSOSScreen> createState() => _ModernSOSScreenState();
}

class _ModernSOSScreenState extends ConsumerState<ModernSOSScreen>
    with TickerProviderStateMixin {
  late AnimationController _emergencyController;
  late Animation<double> _emergencyAnimation;

  @override
  void initState() {
    super.initState();
    _emergencyController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _emergencyAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _emergencyController,
      curve: Curves.easeInOut,
    ));
    _emergencyController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _showCustomSOSDialog() async {
    final TextEditingController messageController = TextEditingController();
    String emergencyType = 'general';
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('🚨 Emergency SOS'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select emergency type:'),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: emergencyType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('🚨 General Emergency')),
                        DropdownMenuItem(value: 'medical', child: Text('🏥 Medical Emergency')),
                        DropdownMenuItem(value: 'fire', child: Text('🔥 Fire Emergency')),
                        DropdownMenuItem(value: 'accident', child: Text('🚗 Accident')),
                        DropdownMenuItem(value: 'natural', child: Text('🌪️ Natural Disaster')),
                        DropdownMenuItem(value: 'security', child: Text('🔒 Security Emergency')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            emergencyType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Message (Optional)',
                        hintText: 'Describe your emergency...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🚨 SEND SOS'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    
                    // Get current location
                    Position? position;
                    try {
                      position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                        timeLimit: const Duration(seconds: 10),
                      );
                    } catch (e) {
                      debugPrint('Location error: $e');
                    }

                    // Broadcast SOS
                    try {
                      await AppActions.broadcastSOS(
                        ref,
                        emergencyType: emergencyType,
                        emergencyMessage: messageController.text.isNotEmpty 
                          ? messageController.text 
                          : 'Emergency help needed! SOS activated.',
                        latitude: position?.latitude,
                        longitude: position?.longitude,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🚨 SOS broadcasted to nearby devices'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('SOS broadcast error: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to broadcast SOS: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosActiveModeProvider);
    final nearbyDevices = ref.watch(nearbyDevicesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Emergency SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Mode Selection
                _buildModeSelection(),
                const SizedBox(height: 30),
                
                // Emergency Status
                _buildEmergencyStatus(sosState),
                const SizedBox(height: 40),
                
                // SOS Button
                Expanded(
                  child: Center(
                    child: _buildEmergencyButton(sosState),
                  ),
                ),
                
                // Instructions
                _buildInstructions(sosState),
                const SizedBox(height: 20),
                
                // Device Status
                _buildDeviceStatus(nearbyDevices),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyStatus(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  const Color(0xFFFF6B6B).withOpacity(0.2),
                  const Color(0xFFFF3838).withOpacity(0.1),
                ]
              : [
                  const Color(0xFF4A4A4A).withOpacity(0.2),
                  const Color(0xFF2A2A2A).withOpacity(0.1),
                ],
        ),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFF3838).withOpacity(0.3)
              : const Color(0xFF4A4A4A).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? const Color(0xFFFF3838)
                  : const Color(0xFF4A4A4A),
            ),
            child: Icon(
              isActive ? Icons.warning : Icons.emergency,
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
                  isActive ? 'EMERGENCY ACTIVE' : 'EMERGENCY STANDBY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFFFF3838)
                        : Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Broadcasting SOS signal to nearby devices'
                      : 'Tap the emergency button when you need help',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(bool isActive) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.heavyImpact();
        final isCurrentlyActive = ref.read(sosActiveModeProvider);
        if (isCurrentlyActive) {
          // Deactivate SOS
          AppActions.deactivateSOS(ref);
        } else {
          // Activate SOS with custom message
          AppActions.activateSOS(ref);
          // Show custom SOS dialog
          await _showCustomSOSDialog();
        }
      },
      child: AnimatedBuilder(
        animation: _emergencyAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _emergencyAnimation.value : 1.0,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isActive
                      ? [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFFF3838),
                          const Color(0xFFDC143C),
                        ]
                      : [
                          const Color(0xFF4A4A4A),
                          const Color(0xFF2A2A2A),
                          const Color(0xFF1A1A1A),
                        ],
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: const Color(0xFFFF3838).withOpacity(0.6),
                      blurRadius: 40,
                      spreadRadius: 15,
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? Icons.warning : Icons.emergency,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isActive ? 'STOP SOS' : 'EMERGENCY',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isActive ? 'Tap to stop' : 'Tap for help',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceStatus(List<NearbyDevice> devices) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withOpacity(0.2),
            const Color(0xFF1976D2).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.devices,
                color: Color(0xFF2196F3),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Nearby Devices (${devices.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (devices.isEmpty)
            const Text(
              'No nearby devices found',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            )
          else
            Column(
              children: devices.take(3).map((device) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Text(
                        'Connected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[300],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    final rescuerMode = ref.watch(rescuerActiveModeProvider);
    
    return Container(
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
          const Text(
            'เลือกโหมด',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  'VICTIM (RED)',
                  'ขอความช่วยเหลือ',
                  Icons.warning,
                  const Color(0xFFFF6B6B),
                  !rescuerMode,
                  () {
                    final isCurrentlyActive = ref.read(rescuerActiveModeProvider);
                    if (isCurrentlyActive) {
                      AppActions.deactivateRescuer(ref);
                    } else {
                      AppActions.activateRescuer(ref);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModeButton(
                  'RESCUER (BLUE)',
                  'ให้ความช่วยเหลือ',
                  Icons.healing,
                  const Color(0xFF2196F3),
                  rescuerMode,
                  () {
                    final isCurrentlyActive = ref.read(rescuerActiveModeProvider);
                    if (isCurrentlyActive) {
                      AppActions.deactivateRescuer(ref);
                    } else {
                      AppActions.activateRescuer(ref);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title, String subtitle, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isSelected
                ? [color.withOpacity(0.3), color.withOpacity(0.1)]
                : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
          ),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color.withOpacity(0.8) : Colors.white38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(bool isActive) {
    final rescuerMode = ref.watch(rescuerActiveModeProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF00D4FF),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            rescuerMode 
                ? (isActive ? 'กำลังค้นหาสัญญาณ SOS ใกล้เคียง' : 'พร้อมรับสัญญาณ SOS')
                : (isActive ? 'กำลังส่งสัญญาณ SOS' : 'กดปุ่มด้านบนเพื่อส่งสัญญาณขอความช่วยเหลือ'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          if (!rescuerMode && !isActive) ...[
            const SizedBox(height: 8),
            const Text(
              'ในกรณีฉุกเฉิน ระบบจะส่งตำแหน่งและข้อมูลติดต่อไปยังอุปกรณ์ใกล้เคียง',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
