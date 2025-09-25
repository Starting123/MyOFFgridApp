import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DeviceType { phone, tablet, laptop, watch, other }
enum DeviceRole { victim, rescuer, neutral }
enum ConnectionStatus { disconnected, connecting, connected, failed }

class NearbyDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DeviceRole role;
  final ConnectionStatus status;
  final int signalStrength; // 0-100
  final double distance; // in meters
  final DateTime lastSeen;
  final String? batteryLevel;
  final bool isEncrypted;

  NearbyDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.role,
    required this.status,
    required this.signalStrength,
    required this.distance,
    required this.lastSeen,
    this.batteryLevel,
    this.isEncrypted = true,
  });
}

class NearbyDevicesScreen extends StatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  State<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends State<NearbyDevicesScreen> 
    with TickerProviderStateMixin {
  bool _isScanning = false;
  String _sortBy = 'distance'; // distance, name, signal, lastSeen
  bool _showOnlyConnected = false;
  
  late AnimationController _scanAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mock nearby devices - replace with actual device discovery service
  List<NearbyDevice> _nearbyDevices = [
    NearbyDevice(
      id: 'device_1',
      name: 'Sarah\'s Phone',
      type: DeviceType.phone,
      role: DeviceRole.victim,
      status: ConnectionStatus.connected,
      signalStrength: 95,
      distance: 15.5,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 30)),
      batteryLevel: '85%',
      isEncrypted: true,
    ),
    NearbyDevice(
      id: 'device_2', 
      name: 'Emergency Responder',
      type: DeviceType.tablet,
      role: DeviceRole.rescuer,
      status: ConnectionStatus.connected,
      signalStrength: 78,
      distance: 42.3,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
      batteryLevel: '92%',
      isEncrypted: true,
    ),
    NearbyDevice(
      id: 'device_3',
      name: 'Mike\'s Laptop',
      type: DeviceType.laptop,
      role: DeviceRole.neutral,
      status: ConnectionStatus.disconnected,
      signalStrength: 65,
      distance: 78.9,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      batteryLevel: '45%',
      isEncrypted: false,
    ),
    NearbyDevice(
      id: 'device_4',
      name: 'Volunteer Team Alpha',
      type: DeviceType.phone,
      role: DeviceRole.rescuer,
      status: ConnectionStatus.connecting,
      signalStrength: 88,
      distance: 23.7,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
      batteryLevel: '67%',
      isEncrypted: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });

    if (_isScanning) {
      _scanAnimationController.repeat();
      _startDiscovery();
    } else {
      _scanAnimationController.stop();
      _scanAnimationController.reset();
    }

    HapticFeedback.mediumImpact();
  }

  void _startDiscovery() {
    // Simulate device discovery
    Future.delayed(const Duration(seconds: 3), () {
      if (_isScanning && mounted) {
        setState(() {
          // Add mock discovered device
          _nearbyDevices.add(NearbyDevice(
            id: 'device_${DateTime.now().millisecondsSinceEpoch}',
            name: 'New Device',
            type: DeviceType.phone,
            role: DeviceRole.neutral,
            status: ConnectionStatus.disconnected,
            signalStrength: 70,
            distance: 50.0,
            lastSeen: DateTime.now(),
            batteryLevel: '80%',
          ));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 New device discovered'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _connectToDevice(NearbyDevice device) async {
    if (device.status == ConnectionStatus.connected) {
      _disconnectFromDevice(device);
      return;
    }

    setState(() {
      final index = _nearbyDevices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        _nearbyDevices[index] = NearbyDevice(
          id: device.id,
          name: device.name,
          type: device.type,
          role: device.role,
          status: ConnectionStatus.connecting,
          signalStrength: device.signalStrength,
          distance: device.distance,
          lastSeen: device.lastSeen,
          batteryLevel: device.batteryLevel,
          isEncrypted: device.isEncrypted,
        );
      }
    });

    // Simulate connection process
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        final index = _nearbyDevices.indexWhere((d) => d.id == device.id);
        if (index != -1) {
          _nearbyDevices[index] = NearbyDevice(
            id: device.id,
            name: device.name,
            type: device.type,
            role: device.role,
            status: ConnectionStatus.connected,
            signalStrength: device.signalStrength,
            distance: device.distance,
            lastSeen: DateTime.now(),
            batteryLevel: device.batteryLevel,
            isEncrypted: device.isEncrypted,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Connected to ${device.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }

    HapticFeedback.lightImpact();
  }

  void _disconnectFromDevice(NearbyDevice device) {
    setState(() {
      final index = _nearbyDevices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        _nearbyDevices[index] = NearbyDevice(
          id: device.id,
          name: device.name,
          type: device.type,
          role: device.role,
          status: ConnectionStatus.disconnected,
          signalStrength: device.signalStrength,
          distance: device.distance,
          lastSeen: device.lastSeen,
          batteryLevel: device.batteryLevel,
          isEncrypted: device.isEncrypted,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔌 Disconnected from ${device.name}'),
        backgroundColor: Colors.orange,
      ),
    );

    HapticFeedback.lightImpact();
  }

  List<NearbyDevice> get _filteredDevices {
    var devices = _nearbyDevices.where((device) {
      if (_showOnlyConnected) {
        return device.status == ConnectionStatus.connected;
      }
      return true;
    }).toList();

    // Sort devices
    switch (_sortBy) {
      case 'distance':
        devices.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'name':
        devices.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'signal':
        devices.sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
        break;
      case 'lastSeen':
        devices.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        break;
    }

    return devices;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredDevices = _filteredDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me,
                      color: _sortBy == 'distance' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text('Distance'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'signal',
                child: Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      color: _sortBy == 'signal' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text('Signal Strength'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text('Name'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'lastSeen',
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: _sortBy == 'lastSeen' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text('Last Seen'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _showOnlyConnected ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() {
                _showOnlyConnected = !_showOnlyConnected;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          _buildControlPanel(colorScheme),
          
          // Device Statistics
          _buildDeviceStats(colorScheme, filteredDevices),
          
          // Device List
          Expanded(
            child: filteredDevices.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildDeviceList(filteredDevices, colorScheme),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _scanAnimationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _scanAnimationController.value * 2 * 3.14159,
            child: FloatingActionButton(
              onPressed: _toggleScanning,
              backgroundColor: _isScanning 
                  ? colorScheme.secondary 
                  : colorScheme.primary,
              child: Icon(
                _isScanning ? Icons.stop : Icons.radar,
                color: _isScanning 
                    ? colorScheme.onSecondary 
                    : colorScheme.onPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlPanel(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isScanning ? Icons.radar : Icons.bluetooth,
            color: _isScanning ? colorScheme.secondary : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isScanning ? 'Scanning for devices...' : 'Ready to discover',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isScanning 
                      ? 'Searching nearby area' 
                      : 'Tap radar to start scanning',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_isScanning)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceStats(ColorScheme colorScheme, List<NearbyDevice> devices) {
    final connectedCount = devices.where((d) => d.status == ConnectionStatus.connected).length;
    final victimCount = devices.where((d) => d.role == DeviceRole.victim).length;
    final rescuerCount = devices.where((d) => d.role == DeviceRole.rescuer).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Connected',
              connectedCount.toString(),
              Icons.link,
              Colors.green,
              colorScheme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Victims',
              victimCount.toString(),
              Icons.emergency,
              Colors.red,
              colorScheme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Rescuers',
              rescuerCount.toString(),
              Icons.medical_services,
              Colors.blue,
              colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: Icon(
              Icons.devices,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _showOnlyConnected ? 'No connected devices' : 'No devices found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyConnected 
                ? 'Connect to nearby devices to see them here'
                : _isScanning 
                    ? 'Scanning for nearby devices...'
                    : 'Tap the radar button to start discovering devices',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<NearbyDevice> devices, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return _buildDeviceTile(device, colorScheme);
      },
    );
  }

  Widget _buildDeviceTile(NearbyDevice device, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(device.status).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Device Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRoleColor(device.role).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getDeviceIcon(device.type),
                    color: _getRoleColor(device.role),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Device Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _buildRoleBadge(device.role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${device.distance.toStringAsFixed(1)}m',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatLastSeen(device.lastSeen),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Connection Button
                _buildConnectionButton(device, colorScheme),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Device Details Row
            Row(
              children: [
                _buildSignalIndicator(device.signalStrength, colorScheme),
                const Spacer(),
                if (device.batteryLevel != null) ...[
                  Icon(
                    Icons.battery_std,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    device.batteryLevel!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                ],
                if (device.isEncrypted) ...[
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Encrypted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.lock_open,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unencrypted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
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

  Widget _buildRoleBadge(DeviceRole role) {
    Color color;
    String text;
    IconData icon;

    switch (role) {
      case DeviceRole.victim:
        color = Colors.red;
        text = 'Victim';
        icon = Icons.emergency;
        break;
      case DeviceRole.rescuer:
        color = Colors.blue;
        text = 'Rescuer';
        icon = Icons.medical_services;
        break;
      case DeviceRole.neutral:
        color = Colors.grey;
        text = 'Neutral';
        icon = Icons.person;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton(NearbyDevice device, ColorScheme colorScheme) {
    String text;
    Color color;
    IconData icon;
    bool isLoading = device.status == ConnectionStatus.connecting;

    switch (device.status) {
      case ConnectionStatus.connected:
        text = 'Disconnect';
        color = Colors.red;
        icon = Icons.link_off;
        break;
      case ConnectionStatus.connecting:
        text = 'Connecting...';
        color = Colors.orange;
        icon = Icons.sync;
        break;
      case ConnectionStatus.failed:
        text = 'Retry';
        color = Colors.red;
        icon = Icons.refresh;
        break;
      case ConnectionStatus.disconnected:
      default:
        text = 'Connect';
        color = Colors.green;
        icon = Icons.link;
        break;
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : () => _connectToDevice(device),
      icon: isLoading 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSignalIndicator(int strength, ColorScheme colorScheme) {
    Color color;
    if (strength >= 80) {
      color = Colors.green;
    } else if (strength >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.signal_cellular_alt,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$strength%',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.phone:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.laptop:
        return Icons.laptop;
      case DeviceType.watch:
        return Icons.watch;
      case DeviceType.other:
        return Icons.device_unknown;
    }
  }

  Color _getRoleColor(DeviceRole role) {
    switch (role) {
      case DeviceRole.victim:
        return Colors.red;
      case DeviceRole.rescuer:
        return Colors.blue;
      case DeviceRole.neutral:
        return Colors.grey;
    }
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.failed:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}