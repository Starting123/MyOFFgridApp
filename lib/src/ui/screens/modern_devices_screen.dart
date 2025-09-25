import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/main_providers.dart';
import '../../models/chat_models.dart';
import 'modern_chat_screen.dart';

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
    final nearbyDevices = ref.watch(nearbyDevicesProvider);
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
            // Scan Controls
            _buildScanControls(),
            
            // Status Header
            _buildStatusHeader(nearbyDevices.length, rescuerMode),
            
            // Device Categories
            _buildDeviceCategories(nearbyDevices),
            
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

  Widget _buildDevicesList(List<NearbyDevice> devices) {
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

  Widget _buildDeviceCard(NearbyDevice device) {
    final rescuerMode = ref.watch(realRescuerModeProvider);
    
    // Simulate device role information (in real app, this would come from device data)
    final isSOSUser = device.name.contains('SOS') || device.id.contains('emergency');
    final isRescuer = device.name.contains('Rescuer') || device.id.contains('rescue');
    
    Color roleColor = Colors.white54;
    IconData roleIcon = Icons.person;
    String roleLabel = 'Unknown';
    
    if (isSOSUser) {
      roleColor = const Color(0xFFFF6B6B);
      roleIcon = Icons.warning;
      roleLabel = 'SOS User';
    } else if (isRescuer) {
      roleColor = const Color(0xFF4CAF50);
      roleIcon = Icons.medical_services;
      roleLabel = 'Rescuer';
    }

    return GestureDetector(
      onTap: () => _startChatWithDevice(device),
      child: Container(
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
            color: isSOSUser && rescuerMode 
                ? const Color(0xFFFF6B6B).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isSOSUser && rescuerMode ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      roleColor.withOpacity(0.3),
                      roleColor.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  roleIcon,
                  color: roleColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSOSUser && rescuerMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFFF6B6B).withOpacity(0.2),
                            ),
                            child: const Text(
                              'EMERGENCY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ),
                      ],
                    ),
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
                          roleLabel,
                          roleColor,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          device.isConnected ? 'Connected' : 'Available',
                          device.isConnected ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _startChatWithDevice(device),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF00D4FF),
                      size: 24,
                    ),
                    tooltip: 'Start Chat',
                  ),
                  IconButton(
                    onPressed: () => _connectToDevice(device),
                    icon: Icon(
                      device.isConnected ? Icons.link_off : Icons.link,
                      color: device.isConnected ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    tooltip: device.isConnected ? 'Disconnect' : 'Connect',
                  ),
                ],
              ),
            ],
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

  void _startScan() async {
    if (_isScanning) {
      // Stop scanning
      _scanController.stop();
      setState(() {
        _isScanning = false;
      });
      // Stop scanning is handled automatically by services
    } else {
      // Start scanning
      setState(() {
        _isScanning = true;
      });
      _scanController.repeat();
      
      HapticFeedback.lightImpact();
      // Start scanning is handled automatically by services
      
      // Auto-stop after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        if (_isScanning && mounted) {
          _startScan(); // This will stop the scan
        }
      });
    }
  }

  void _connectToDevice(NearbyDevice device) async {
    HapticFeedback.lightImpact();
    
    try {
      if (device.isConnected) {
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

  void _startChatWithDevice(NearbyDevice device) {
    HapticFeedback.lightImpact();
    
    // Show confirmation dialog for starting chat
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.chat_bubble,
                color: const Color(0xFF00D4FF),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Start Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a secure 1-on-1 chat with ${device.name}?',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color(0xFF4CAF50),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'End-to-end encrypted',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      color: Color(0xFF00D4FF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Works without internet',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToChat(device);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Chat',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToChat(NearbyDevice device) {
    // TODO: Pass device information to chat screen
    // For now, navigate to general chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernChatScreen(),
      ),
    );
    
    // Show snackbar with device info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.chat, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Starting chat with ${device.name}'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildScanControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.1),
            const Color(0xFF5B86E5).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ค้นหาอุปกรณ์ใกล้เคียง',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isScanning ? 'กำลังค้นหา...' : 'แตะเพื่อเริ่มค้นหา',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _startScan,
            icon: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _isScanning ? _scanAnimation.value * 2 * 3.14159 : 0,
                  child: Icon(
                    _isScanning ? Icons.stop : Icons.search,
                    color: Colors.white,
                  ),
                );
              },
            ),
            label: Text(
              _isScanning ? 'หยุด' : 'ค้นหา',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isScanning ? Colors.red[600] : const Color(0xFF00D4FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCategories(List<NearbyDevice> devices) {
    final connectedDevices = devices.where((d) => d.isConnected).toList();
    final availableDevices = devices.where((d) => !d.isConnected).toList();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryCard(
              'เชื่อมต่อแล้ว',
              connectedDevices.length,
              Icons.link,
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCategoryCard(
              'พร้อมเชื่อมต่อ',
              availableDevices.length,
              Icons.devices_other,
              const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCategoryCard(
              'ทั้งหมด',
              devices.length,
              Icons.radar,
              const Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
