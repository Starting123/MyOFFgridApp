import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class DeviceListScreen extends ConsumerStatefulWidget {
  const DeviceListScreen({super.key});

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  bool _isScanning = false;
  Timer? _scanTimer;
  List<DetectedDevice> _detectedDevices = [];

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _detectedDevices.clear();
    });

    // Simulate device discovery
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateDeviceDiscovery();
    });

    // Stop scanning after 30 seconds
    Timer(const Duration(seconds: 30), () {
      _stopScanning();
    });
  }

  void _stopScanning() {
    setState(() => _isScanning = false);
    _scanTimer?.cancel();
  }

  void _simulateDeviceDiscovery() {
    // This is a simulation - in real app, this would connect to actual services
    final mockDevices = [
      DetectedDevice(
        id: 'device_001',
        name: 'SOS Device - สมชาย',
        deviceType: 'SOS',
        distance: 25.0,
        signalStrength: -45,
        batteryLevel: 78,
        lastSeen: DateTime.now(),
        status: DeviceStatus.active,
      ),
      DetectedDevice(
        id: 'device_002', 
        name: 'Rescuer Team Alpha',
        deviceType: 'Rescuer',
        distance: 150.0,
        signalStrength: -65,
        batteryLevel: 92,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
        status: DeviceStatus.connected,
      ),
      DetectedDevice(
        id: 'device_003',
        name: 'Relay Station 1',
        deviceType: 'Relay',
        distance: 85.0,
        signalStrength: -55,
        batteryLevel: 45,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
        status: DeviceStatus.inactive,
      ),
    ];

    if (_detectedDevices.length < 3) {
      setState(() {
        _detectedDevices.add(mockDevices[_detectedDevices.length]);
      });
    }
  }

  Widget _buildDeviceCard(DetectedDevice device) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (device.status) {
      case DeviceStatus.active:
        statusColor = Colors.red;
        statusIcon = Icons.emergency;
        statusText = 'ขอความช่วยเหลือ';
        break;
      case DeviceStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.link;
        statusText = 'เชื่อมต่อแล้ว';
        break;
      case DeviceStatus.inactive:
        statusColor = Colors.grey;
        statusIcon = Icons.device_hub;
        statusText = 'รอเชื่อมต่อ';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: _getDeviceTypeColor(device.deviceType),
              child: Icon(
                _getDeviceTypeIcon(device.deviceType),
                color: Colors.white,
                size: 24,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 4),
                Text(statusText, style: TextStyle(color: statusColor)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${device.distance.toStringAsFixed(0)}m'),
                const SizedBox(width: 16),
                Icon(Icons.signal_cellular_4_bar, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${device.signalStrength}dBm'),
                const SizedBox(width: 16),
                Icon(Icons.battery_std, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${device.batteryLevel}%'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'เห็นล่าสุด: ${_formatLastSeen(device.lastSeen)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleDeviceAction(device, value),
          itemBuilder: (context) => [
            if (device.status != DeviceStatus.connected)
              const PopupMenuItem(
                value: 'connect',
                child: Row(
                  children: [
                    Icon(Icons.link),
                    SizedBox(width: 8),
                    Text('เชื่อมต่อ'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'chat',
              child: Row(
                children: [
                  Icon(Icons.chat),
                  SizedBox(width: 8),
                  Text('แชท'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'location',
              child: Row(
                children: [
                  Icon(Icons.location_on),
                  SizedBox(width: 8),
                  Text('ดูตำแหน่ง'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8),
                  Text('รายละเอียด'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _connectToDevice(device),
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

  String _formatLastSeen(DateTime lastSeen) {
    final difference = DateTime.now().difference(lastSeen);
    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    }
  }

  void _connectToDevice(DetectedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เชื่อมต่อกับ ${device.name}'),
        content: const Text('คุณต้องการเชื่อมต่อกับอุปกรณ์นี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performConnection(device);
            },
            child: const Text('เชื่อมต่อ'),
          ),
        ],
      ),
    );
  }

  void _performConnection(DetectedDevice device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กำลังเชื่อมต่อกับ ${device.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate connection
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          device.status = DeviceStatus.connected;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ เชื่อมต่อกับ ${device.name} สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _handleDeviceAction(DetectedDevice device, String action) {
    switch (action) {
      case 'connect':
        _connectToDevice(device);
        break;
      case 'chat':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เปิดหน้าแชท...')),
        );
        break;
      case 'location':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แสดงตำแหน่งบนแผนที่...')),
        );
        break;
      case 'info':
        _showDeviceInfo(device);
        break;
    }
  }

  void _showDeviceInfo(DetectedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('ID:', device.id),
            _buildInfoRow('ประเภท:', device.deviceType),
            _buildInfoRow('ระยะทาง:', '${device.distance.toStringAsFixed(1)} เมตร'),
            _buildInfoRow('สัญญาณ:', '${device.signalStrength} dBm'),
            _buildInfoRow('แบตเตอรี่:', '${device.batteryLevel}%'),
            _buildInfoRow('เห็นล่าสุด:', _formatLastSeen(device.lastSeen)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📡 อุปกรณ์ใกล้เคียง'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? _stopScanning : _startScanning,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanning Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isScanning ? Colors.blue.shade50 : Colors.grey.shade50,
            child: Row(
              children: [
                if (_isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.search_off,
                    color: Colors.grey.shade600,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isScanning 
                      ? '🔍 กำลังค้นหาอุปกรณ์ใกล้เคียง...'
                      : '⏸️ หยุดการค้นหาแล้ว',
                    style: TextStyle(
                      color: _isScanning ? Colors.blue.shade700 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'พบ ${_detectedDevices.length} เครื่อง',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Device List
          Expanded(
            child: _detectedDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning 
                            ? 'กำลังค้นหาอุปกรณ์...' 
                            : 'ไม่พบอุปกรณ์ใกล้เคียง',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!_isScanning) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _startScanning,
                            icon: const Icon(Icons.refresh),
                            label: const Text('ค้นหาใหม่'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _detectedDevices.length,
                    itemBuilder: (context, index) => 
                        _buildDeviceCard(_detectedDevices[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? _stopScanning : _startScanning,
        backgroundColor: _isScanning ? Colors.red : Colors.blue.shade600,
        child: Icon(
          _isScanning ? Icons.stop : Icons.search,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }
}

// Data Models
class DetectedDevice {
  String id;
  String name;
  String deviceType;
  double distance;
  int signalStrength;
  int batteryLevel;
  DateTime lastSeen;
  DeviceStatus status;

  DetectedDevice({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.distance,
    required this.signalStrength,
    required this.batteryLevel,
    required this.lastSeen,
    required this.status,
  });
}

enum DeviceStatus {
  active,    // SOS กำลังขอความช่วยเหลือ
  connected, // เชื่อมต่อแล้ว
  inactive,  // ออนไลน์แต่ยังไม่เชื่อมต่อ
}