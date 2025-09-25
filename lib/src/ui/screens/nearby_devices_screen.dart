import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_models.dart';
import '../../providers/main_providers.dart';

// Note: Using DeviceRole from chat_models.dart instead of custom enums
// ConnectionStatus is handled by isConnected boolean in the NearbyDevice model

class NearbyDevicesScreen extends ConsumerStatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  ConsumerState<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends ConsumerState<NearbyDevicesScreen> 
    with TickerProviderStateMixin {
  bool _isScanning = false;
  String _sortBy = 'distance'; // distance, name, signal, lastSeen
  bool _showOnlyConnected = false;
  
  late AnimationController _scanAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Real nearby devices from provider

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

  void _startDiscovery() async {
    // Start real device discovery
    try {
      // Start real device discovery - in a real app this would trigger provider refresh
      // For now just show a scanning message
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Scanning for nearby devices...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error scanning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _connectToDevice(NearbyDevice device) async {
    if (device.isConnected) {
      _disconnectFromDevice(device);
      return;
    }

    // Show connecting state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔄 Connecting to ${device.name}...'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate connection process
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // In a real app, this would update through the provider
      // For now, just show success message
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
    // In a real app, this would update through the provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔌 Disconnected from ${device.name}'),
        backgroundColor: Colors.orange,
      ),
    );

    HapticFeedback.lightImpact();
  }

  List<NearbyDevice> _getFilteredDevices(List<NearbyDevice> devices) {
    var filteredDevices = devices.where((device) {
      if (_showOnlyConnected) {
        return device.isConnected;
      }
      return true;
    }).toList();

    // Sort devices
    switch (_sortBy) {
      case 'distance':
        // For now, sort by signal strength as substitute for distance
        filteredDevices.sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
        break;
      case 'name':
        filteredDevices.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'signal':
        filteredDevices.sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
        break;
      case 'lastSeen':
        filteredDevices.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        break;
    }

    return filteredDevices;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nearbyDevices = ref.watch(nearbyDevicesProvider);
    final filteredDevices = _getFilteredDevices(nearbyDevices);

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
    final connectedCount = devices.where((d) => d.isConnected).length;
    final sosUserCount = devices.where((d) => d.role == DeviceRole.sosUser).length;
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
              'SOS Users',
              sosUserCount.toString(),
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
          color: (device.isConnected ? Colors.green : Colors.grey).withOpacity(0.3),
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
                    _getDeviceIconFromRole(device.role),
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
                            'Signal: ${device.signalStrength}%',
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
                Icon(
                  device.isConnected ? Icons.link : Icons.link_off,
                  size: 16,
                  color: device.isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  device.isConnected ? 'Connected' : 'Disconnected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: device.isConnected ? Colors.green : Colors.grey,
                  ),
                ),
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
      case DeviceRole.sosUser:
        color = Colors.red;
        text = 'SOS User';
        icon = Icons.emergency;
        break;
      case DeviceRole.rescuer:
        color = Colors.blue;
        text = 'Rescuer';
        icon = Icons.medical_services;
        break;
      case DeviceRole.normal:
        color = Colors.grey;
        text = 'Normal';
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

    if (device.isConnected) {
      text = 'Disconnect';
      color = Colors.red;
      icon = Icons.link_off;
    } else {
      text = 'Connect';
      color = Colors.green;
      icon = Icons.link;
    }

    return ElevatedButton.icon(
      onPressed: () => _connectToDevice(device),
      icon: Icon(icon, size: 16),
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

  IconData _getDeviceIconFromRole(DeviceRole role) {
    switch (role) {
      case DeviceRole.sosUser:
        return Icons.emergency;
      case DeviceRole.rescuer:
        return Icons.medical_services;  
      case DeviceRole.normal:
        return Icons.smartphone;
    }
  }

  Color _getRoleColor(DeviceRole role) {
    switch (role) {
      case DeviceRole.sosUser:
        return Colors.red;
      case DeviceRole.rescuer:
        return Colors.blue;
      case DeviceRole.normal:
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