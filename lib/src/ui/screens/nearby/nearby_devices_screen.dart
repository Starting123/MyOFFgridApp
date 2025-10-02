import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
import '../../../models/chat_models.dart';
import '../../../providers/enhanced_nearby_provider.dart';
import '../../../services/service_coordinator.dart';
import '../../../utils/logger.dart';
import '../../widgets/common/reusable_widgets.dart';
import '../chat/chat_detail_screen.dart';

class NearbyDevicesScreen extends ConsumerStatefulWidget {
  const NearbyDevicesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends ConsumerState<NearbyDevicesScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nearbyDevicesAsync = ref.watch(nearbyDevicesWithSOSProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isScanning ? null : () => _startScanning(),
            icon: _isScanning 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: _isScanning ? 'Scanning...' : 'Scan for devices',
          ),
        ],
      ),
      body: nearbyDevicesAsync.when(
        data: (devices) => _buildDeviceList(context, devices, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString(), theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : () => _startScanning(),
        icon: const Icon(Icons.radar),
        label: Text(_isScanning ? 'Scanning...' : 'Scan Devices'),
        backgroundColor: _isScanning ? Colors.grey : null,
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, List<NearbyDevice> devices, ThemeData theme) {
    if (devices.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return RefreshIndicator(
      onRefresh: () => _startScanning(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return _buildDeviceCard(context, device, theme);
        },
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, NearbyDevice device, ThemeData theme) {
    final role = _getUserRoleFromDeviceRole(device.role);
    final isConnected = device.isConnected;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: RoleBadge(
          role: role,
          size: 48,
          showLabel: false,
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role.displayName),
            Text('Signal: ${device.signalStrength} dBm'),
            Text('Last seen: ${_formatLastSeen(device.lastSeen)}'),
          ],
        ),
        trailing: isConnected 
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.radio_button_unchecked),
        onTap: () => _connectToDevice(device),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radar,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No nearby devices found',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the scan button to search for devices',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _startScanning(),
            icon: const Icon(Icons.refresh),
            label: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error scanning devices',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _startScanning(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  UserRole _getUserRoleFromDeviceRole(DeviceRole deviceRole) {
    switch (deviceRole) {
      case DeviceRole.sosUser:
        return UserRole.sosUser;
      case DeviceRole.rescuer:
        return UserRole.rescueUser;
      case DeviceRole.normal:
        return UserRole.relayUser;
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Start device discovery via ServiceCoordinator
      final coordinator = ServiceCoordinator.instance;
      
      if (!coordinator.isInitialized) {
        await coordinator.initializeAll();
      }
      
      // Start unified discovery across all services
      Logger.info('Starting device discovery scan', 'nearby');
      
      // Discovery is handled automatically by ServiceCoordinator
      // The devices will appear in the stream-based UI
      await Future.delayed(const Duration(seconds: 2)); // Brief delay for UI feedback
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanning failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _connectToDevice(NearbyDevice device) {
    // Convert NearbyDevice to format expected by ChatDetailScreen
    final deviceMap = {
      'id': device.id,
      'name': device.name,
      'role': _getUserRoleFromDeviceRole(device.role),
      'isOnline': device.isConnected,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(user: deviceMap),
      ),
    );
  }
}