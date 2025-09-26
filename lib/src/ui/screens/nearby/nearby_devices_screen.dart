import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
import '../../../models/chat_models.dart';
import '../../../providers/enhanced_nearby_provider.dart';
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
    final role = _getUserRoleFromDevice(device);
    final isConnected = device.isConnected;
    final signalStrength = device.signalStrength.abs(); // Convert to positive percentage
    final distance = 'Unknown'; // Distance calculation would need to be implemented
    final lastSeen = device.lastSeen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _connectToDevice(device),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Role Badge
                  RoleBadge(
                    role: role,
                    size: 48,
                    showLabel: false,
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isConnected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green, width: 1),
                                ),
                                child: Text(
                                  'Connected',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Role and Status
                        Row(
                          children: [
                            Icon(
                              role.icon,
                              size: 16,
                              color: role.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              role.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: role.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              distance.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        
                        if (lastSeen != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Last seen: ${_formatLastSeen(lastSeen)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Signal Strength
                  Column(
                    children: [
                      Icon(
                        _getSignalIcon(signalStrength),
                        color: _getSignalColor(signalStrength),
                        size: 24,
                      ),
                      Text(
                        '${signalStrength}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getSignalColor(signalStrength),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (role == UserRole.sosUser) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'EMERGENCY: Person needs assistance!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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

  UserRole _getUserRoleFromDevice(Map<String, dynamic> device) {
    final roleString = device['role'] as String?;
    switch (roleString) {
      case 'sos':
        return UserRole.sosUser;
      case 'rescuer':
        return UserRole.rescueUser;
      case 'relay':
        return UserRole.relayUser;
      default:
        return UserRole.normalUser;
    }
  }

  IconData _getSignalIcon(int strength) {
    if (strength >= 80) return Icons.signal_wifi_4_bar;
    if (strength >= 60) return Icons.signal_wifi_3_bar;
    if (strength >= 40) return Icons.signal_wifi_2_bar;
    if (strength >= 20) return Icons.signal_wifi_1_bar;
    return Icons.signal_wifi_0_bar;
  }

  Color _getSignalColor(int strength) {
    if (strength >= 60) return Colors.green;
    if (strength >= 30) return Colors.orange;
    return Colors.red;
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
      // Use the nearby provider to start scanning
      await ref.read(nearbyProviderProvider.notifier).startScanning();
      
      // Simulate scanning duration
      await Future.delayed(const Duration(seconds: 3));
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

  void _connectToDevice(Map<String, dynamic> device) {
    // Navigate to chat with this device
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(user: device),
      ),
    );
  }
}