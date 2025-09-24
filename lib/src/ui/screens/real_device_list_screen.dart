import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/real_device_providers.dart';

class RealDeviceListScreen extends ConsumerStatefulWidget {
  const RealDeviceListScreen({super.key});

  @override
  ConsumerState<RealDeviceListScreen> createState() => _RealDeviceListScreenState();
}

class _RealDeviceListScreenState extends ConsumerState<RealDeviceListScreen> {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() async {
    setState(() => _isScanning = true);
    
    final devicesNotifier = ref.read(realNearbyDevicesProvider.notifier);
    await devicesNotifier.startScanning();
    
    // Auto-stop scanning after 30 seconds to save battery
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _stopScanning();
      }
    });
  }

  void _stopScanning() async {
    if (!_isScanning) return;
    
    setState(() => _isScanning = false);
    
    final devicesNotifier = ref.read(realNearbyDevicesProvider.notifier);
    await devicesNotifier.stopScanning();
  }

  Widget _buildDeviceCard(RealNearbyDevice device) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (device.status) {
      case DeviceConnectionStatus.sosActive:
        statusColor = Colors.red;
        statusIcon = Icons.emergency;
        statusText = 'ขอความช่วยเหลือ';
        break;
      case DeviceConnectionStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.link;
        statusText = 'เชื่อมต่อแล้ว';
        break;
      case DeviceConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        statusText = 'กำลังเชื่อมต่อ';
        break;
      case DeviceConnectionStatus.discovered:
        statusColor = Colors.blue;
        statusIcon = Icons.visibility;
        statusText = 'พบแล้ว';
        break;
      case DeviceConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusIcon = Icons.link_off;
        statusText = 'ตัดการเชื่อมต่อ';
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
              backgroundColor: _getDeviceTypeColor(device.type),
              child: Icon(
                _getDeviceTypeIcon(device.type),
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
                if (device.distance != null) ...[
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${device.distance!.toStringAsFixed(0)}m'),
                  const SizedBox(width: 16),
                ],
                if (device.signalStrength != null) ...[
                  Icon(Icons.signal_cellular_4_bar, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${device.signalStrength}dBm'),
                  const SizedBox(width: 16),
                ],
                if (device.batteryLevel != null) ...[
                  Icon(Icons.battery_std, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${device.batteryLevel}%'),
                ],
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
            if (device.status != DeviceConnectionStatus.connected)
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
    switch (deviceType.toLowerCase()) {
      case 'sos':
        return Colors.red.shade600;
      case 'rescuer':
        return Colors.blue.shade600;
      case 'relay':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getDeviceTypeIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'sos':
        return Icons.emergency;
      case 'rescuer':
        return Icons.local_hospital;
      case 'relay':
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

  void _connectToDevice(RealNearbyDevice device) {
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

  void _performConnection(RealNearbyDevice device) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กำลังเชื่อมต่อกับ ${device.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    final devicesNotifier = ref.read(realNearbyDevicesProvider.notifier);
    final success = await devicesNotifier.connectToDevice(device.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? '✅ เชื่อมต่อกับ ${device.name} สำเร็จ'
              : '❌ เชื่อมต่อกับ ${device.name} ไม่สำเร็จ'
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _handleDeviceAction(RealNearbyDevice device, String action) {
    switch (action) {
      case 'connect':
        _connectToDevice(device);
        break;
      case 'chat':
        // Navigate to chat screen with this device
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'deviceId': device.id,
            'deviceName': device.name,
          },
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

  void _showDeviceInfo(RealNearbyDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('ID:', device.id),
            _buildInfoRow('ประเภท:', device.type),
            if (device.distance != null)
              _buildInfoRow('ระยะทาง:', '${device.distance!.toStringAsFixed(1)} เมตร'),
            if (device.signalStrength != null)
              _buildInfoRow('สัญญาณ:', '${device.signalStrength} dBm'),
            if (device.batteryLevel != null)
              _buildInfoRow('แบตเตอรี่:', '${device.batteryLevel}%'),
            _buildInfoRow('เห็นล่าสุด:', _formatLastSeen(device.lastSeen)),
            _buildInfoRow('สถานะ:', _getStatusText(device.status)),
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

  String _getStatusText(DeviceConnectionStatus status) {
    switch (status) {
      case DeviceConnectionStatus.sosActive:
        return 'ขอความช่วยเหลือ';
      case DeviceConnectionStatus.connected:
        return 'เชื่อมต่อแล้ว';
      case DeviceConnectionStatus.connecting:
        return 'กำลังเชื่อมต่อ';
      case DeviceConnectionStatus.discovered:
        return 'พบแล้ว';
      case DeviceConnectionStatus.disconnected:
        return 'ตัดการเชื่อมต่อ';
    }
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
    final detectedDevices = ref.watch(realNearbyDevicesProvider);

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
                  'พบ ${detectedDevices.length} เครื่อง',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Real-time device discovery status
          if (_isScanning && detectedDevices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'กำลังเริ่มต้นระบบ P2P และ Bluetooth...',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Device List
          Expanded(
            child: detectedDevices.isEmpty
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
                            ? 'กำลังค้นหาอุปกรณ์...\nกรุณารอสักครู่' 
                            : 'ไม่พบอุปกรณ์ใกล้เคียง',
                          textAlign: TextAlign.center,
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
                        ] else ...[
                          const SizedBox(height: 16),
                          Text(
                            'เคล็ดลับ:\n• ตรวจสอบว่าเปิด Bluetooth และ WiFi แล้ว\n• ให้อุปกรณ์อื่นเปิดแอปนี้ด้วย\n• อยู่ในระยะ 100 เมตร',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: detectedDevices.length,
                    itemBuilder: (context, index) => 
                        _buildDeviceCard(detectedDevices[index]),
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
    if (_isScanning) {
      _stopScanning();
    }
    super.dispose();
  }
}