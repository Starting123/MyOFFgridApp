import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/real_device_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(realSOSActiveProvider);
    final nearbyDevices = ref.watch(realNearbyDevicesProvider);

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
                // Emergency Status
                _buildEmergencyStatus(sosState),
                const SizedBox(height: 40),
                
                // SOS Button
                Expanded(
                  child: Center(
                    child: _buildEmergencyButton(sosState),
                  ),
                ),
                
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
        await ref.read(realSOSActiveProvider.notifier).toggle();
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

  Widget _buildDeviceStatus(List<RealNearbyDevice> devices) {
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
}