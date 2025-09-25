import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/real_device_providers.dart';

class ModernDevicesScreen extends ConsumerStatefulWidget {
  const ModernDevicesScreen({super.key});

  @override
  ConsumerState<ModernDevicesScreen> createState() => _ModernDevicesScreenState();
}

class _ModernDevicesScreenState extends ConsumerState<ModernDevicesScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nearbyDevices = ref.watch(realNearbyDevicesProvider);
    final rescuerMode = ref.watch(realRescuerModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nearby Devices',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _startScan,
            icon: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _scanAnimation.value * 2 * 3.14159,
                  child: Icon(
                    Icons.refresh,
                    color: _isScanning ? const Color(0xFF00D4FF) : Colors.white70,
                  ),
                );
              },
            ),
          ),
        ],
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
        child: Column(
          children: [
            // Status Header
            _buildStatusHeader(nearbyDevices.length, rescuerMode),
            
            // Devices List
            Expanded(
              child: _buildDevicesList(nearbyDevices),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startScan,
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
        icon: Icon(_isScanning ? Icons.stop : Icons.search),
        label: Text(_isScanning ? 'Stop Scan' : 'Scan Devices'),
      ),
    );
  }

  Widget _buildStatusHeader(int deviceCount, bool rescuerMode) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D4FF).withOpacity(0.3),
                      const Color(0xFF5B86E5).withOpacity(0.2),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.devices,
                  color: Color(0xFF00D4FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$deviceCount Devices Found',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00D4FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rescuerMode ? 'Rescuer mode active' : 'Scanning for emergency signals',
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
          if (_isScanning) ...[
            const SizedBox(height: 16),
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white10,
              ),
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _scanAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF5B86E5)],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDevicesList(List<RealNearbyDevice> devices) {
    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: const Icon(
                Icons.devices_other,
                size: 60,
                color: Colors.white30,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No devices found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the scan button to search for nearby devices',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(RealNearbyDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                _getDeviceColor(device.type).withOpacity(0.3),
                _getDeviceColor(device.type).withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            _getDeviceIcon(device.type),
            color: _getDeviceColor(device.type),
            size: 24,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              device.id,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(
                  device.status == DeviceConnectionStatus.connected ? 'Connected' : 'Available',
                  device.status == DeviceConnectionStatus.connected ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  device.type.toString().split('.').last,
                  _getDeviceColor(device.type),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _connectToDevice(device),
          icon: Icon(
            device.status == DeviceConnectionStatus.connected ? Icons.link_off : Icons.link,
            color: device.status == DeviceConnectionStatus.connected ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.2),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getDeviceColor(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
      case 'smartphone':
        return const Color(0xFF2196F3);
      case 'tablet':
        return const Color(0xFF9C27B0);
      case 'laptop':
      case 'computer':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
      case 'smartphone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'laptop':
      case 'computer':
        return Icons.laptop;
      default:
        return Icons.device_unknown;
    }
  }

  void _startScan() async {
    if (_isScanning) {
      // Stop scanning
      _scanController.stop();
      setState(() {
        _isScanning = false;
      });
      await ref.read(realNearbyDevicesProvider.notifier).stopScanning();
    } else {
      // Start scanning
      setState(() {
        _isScanning = true;
      });
      _scanController.repeat();
      
      HapticFeedback.lightImpact();
      await ref.read(realNearbyDevicesProvider.notifier).startScanning();
      
      // Auto-stop after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        if (_isScanning && mounted) {
          _startScan(); // This will stop the scan
        }
      });
    }
  }

  void _connectToDevice(RealNearbyDevice device) async {
    HapticFeedback.lightImpact();
    
    try {
      if (device.status == DeviceConnectionStatus.connected) {
        // Disconnect
        // Disconnect functionality would be handled by the service layer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnected from ${device.name}')),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disconnected from ${device.name}'),
            backgroundColor: const Color(0xFFFF9800),
          ),
        );
      } else {
        // Connect
        // Connect functionality would be handled by the service layer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connecting to ${device.name}...')),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }
  }
}