import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/modern_widgets.dart';
import '../../models/chat_models.dart';

class NearbyDevicesScreen extends ConsumerStatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  ConsumerState<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends ConsumerState<NearbyDevicesScreen> 
    with SingleTickerProviderStateMixin {
  
  // Mock nearby devices data - in real app from providers
  final List<NearbyDevice> _nearbyDevices = [
    NearbyDevice(
      id: 'device1',
      name: 'Emergency Team Alpha',
      role: DeviceRole.rescuer,
      isSOSActive: false,
      isRescuerActive: true,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 30)),
      latitude: 13.7565,
      longitude: 100.5020,
      signalStrength: 85,
      isConnected: true,
      connectionType: 'bluetooth',
    ),
    NearbyDevice(
      id: 'device2',
      name: 'Local Resident',
      role: DeviceRole.normal,
      isSOSActive: false,
      isRescuerActive: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
      signalStrength: 72,
      isConnected: false,
      connectionType: 'wifi_direct',
    ),
    NearbyDevice(
      id: 'device3',
      name: 'Tourist - Help Needed',
      role: DeviceRole.sosUser,
      isSOSActive: true,
      isRescuerActive: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
      latitude: 13.7560,
      longitude: 100.5015,
      signalStrength: 90,
      isConnected: true,
      connectionType: 'nearby',
    ),
  ];

  bool _isScanning = false;
  late AnimationController _scanController;
  
  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _scanController.repeat();
      } else {
        _scanController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme),
            
            // Scan controls
            _buildScanControls(theme),
            
            // Device list
            Expanded(
              child: _buildDeviceList(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.radar,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearby Devices',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_nearbyDevices.length} devices in range',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Settings button
              IconButton(
                onPressed: () => _showScanSettings(context),
                icon: Icon(
                  Icons.tune,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanControls(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Scan animation
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isScanning 
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Transform.rotate(
                  angle: _scanController.value * 2 * 3.14159,
                  child: Icon(
                    Icons.radar,
                    color: _isScanning 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isScanning ? 'Scanning for devices...' : 'Scan paused',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _isScanning 
                    ? 'Looking for emergency signals and nearby users'
                    : 'Tap to start scanning for nearby devices',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Scan toggle button
          Container(
            decoration: BoxDecoration(
              color: _isScanning 
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _toggleScanning,
              icon: Icon(
                _isScanning ? Icons.pause : Icons.play_arrow,
                color: _isScanning 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(ThemeData theme) {
    if (_nearbyDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isScanning 
                ? 'Scanning for nearby devices...'
                : 'Start scanning to find nearby devices',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group devices by role for better organization
    final sosDevices = _nearbyDevices.where((d) => d.role == DeviceRole.sosUser).toList();
    final rescuerDevices = _nearbyDevices.where((d) => d.role == DeviceRole.rescuer).toList();
    final normalDevices = _nearbyDevices.where((d) => d.role == DeviceRole.normal).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Emergency devices (highest priority)
        if (sosDevices.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Emergency Signals', sosDevices.length, Colors.red),
          ...sosDevices.map((device) => _buildDeviceCard(theme, device)),
          const SizedBox(height: 16),
        ],
        
        // Rescuer devices
        if (rescuerDevices.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Rescue Teams', rescuerDevices.length, Colors.blue),
          ...rescuerDevices.map((device) => _buildDeviceCard(theme, device)),
          const SizedBox(height: 16),
        ],
        
        // Normal devices
        if (normalDevices.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Available Users', normalDevices.length, Colors.green),
          ...normalDevices.map((device) => _buildDeviceCard(theme, device)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(ThemeData theme, NearbyDevice device) {
    return GestureDetector(
      onTap: () => _showDeviceDetails(context, device),
      child: ModernWidgets.deviceListTile(
        deviceName: device.name,
        role: device.role,
        isConnected: device.isConnected,
        onConnect: () => device.isConnected 
          ? _startChatWith(device)
          : _connectToDevice(device),
        lastSeen: _formatLastSeen(device.lastSeen),
        distance: device.signalStrength.toDouble(), // Using signal strength as distance placeholder
      ),
    );
  }

  void _connectToDevice(NearbyDevice device) {
    // TODO: Implement device connection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to ${device.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Simulate connection
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          final index = _nearbyDevices.indexWhere((d) => d.id == device.id);
          if (index != -1) {
            _nearbyDevices[index] = device.copyWith(isConnected: true);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _startChatWith(NearbyDevice device) {
    // TODO: Navigate to chat with specific device
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting chat with ${device.name}'),
      ),
    );
  }

  void _showDeviceDetails(BuildContext context, NearbyDevice device) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRoleColor(device.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getRoleIcon(device.role),
                    color: _getRoleColor(device.role),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getRoleText(device.role),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getRoleColor(device.role),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildDetailRow(theme, 'Connection', device.connectionType.toUpperCase()),
            _buildDetailRow(theme, 'Signal Strength', '${device.signalStrength}%'),
            _buildDetailRow(theme, 'Last Seen', _formatLastSeen(device.lastSeen)),
            _buildDetailRow(theme, 'Status', device.isConnected ? 'Connected' : 'Available'),
            
            if (device.latitude != null && device.longitude != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(theme, 'Location', 
                '${device.latitude!.toStringAsFixed(4)}, ${device.longitude!.toStringAsFixed(4)}'),
            ],
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                if (!device.isConnected)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _connectToDevice(device);
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Connect'),
                    ),
                  ),
                if (device.isConnected) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startChatWith(device);
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Implement disconnect
                      },
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-scan for SOS signals'),
              subtitle: const Text('Automatically scan for emergency signals'),
              value: true,
              onChanged: (value) {
                // TODO: Implement setting
              },
            ),
            SwitchListTile(
              title: const Text('Show all device types'),
              subtitle: const Text('Include all nearby devices in results'),
              value: true,
              onChanged: (value) {
                // TODO: Implement setting
              },
            ),
            SwitchListTile(
              title: const Text('Background scanning'),
              subtitle: const Text('Continue scanning when app is minimized'),
              value: false,
              onChanged: (value) {
                // TODO: Implement setting
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_applications),
              title: const Text('Advanced settings'),
              subtitle: const Text('Configure scan intervals and protocols'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to advanced settings
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Color _getRoleColor(DeviceRole role) {
    switch (role) {
      case DeviceRole.sosUser:
        return Colors.red.shade600;
      case DeviceRole.rescuer:
        return Colors.blue.shade600;
      case DeviceRole.normal:
        return Colors.green.shade600;
    }
  }

  IconData _getRoleIcon(DeviceRole role) {
    switch (role) {
      case DeviceRole.sosUser:
        return Icons.emergency;
      case DeviceRole.rescuer:
        return Icons.local_hospital;
      case DeviceRole.normal:
        return Icons.person;
    }
  }

  String _getRoleText(DeviceRole role) {
    switch (role) {
      case DeviceRole.sosUser:
        return 'NEEDS HELP';
      case DeviceRole.rescuer:
        return 'RESCUER';
      case DeviceRole.normal:
        return 'Available';
    }
  }
}