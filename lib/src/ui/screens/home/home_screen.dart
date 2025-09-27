import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
import '../../../models/chat_models.dart';
import '../../../services/service_coordinator.dart';
import '../../../services/auth_service.dart';
import '../../widgets/common/reusable_widgets.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';
import '../../../utils/logger.dart';

// Real data providers using service coordinator
final serviceStatusProvider = Provider<Map<String, bool>>((ref) {
  return ServiceCoordinator.instance.getServiceStatus();
});

final discoveredDevicesProvider = StreamProvider<List<NearbyDevice>>((ref) {
  return ServiceCoordinator.instance.deviceStream;
});

// Real user provider using AuthService
final currentUserProvider = StreamProvider<Map<String, dynamic>?>((ref) async* {
  final authService = AuthService.instance;
  yield* authService.userStream.map((user) => user != null ? {
    'name': user.name,
    'phone': user.phone ?? 'No phone',
    'role': _mapStringToUserRole(user.role),
  } : null);
});

UserRole _mapStringToUserRole(String role) {
  switch (role.toLowerCase()) {
    case 'rescueuser':
    case 'rescuer':
      return UserRole.rescueUser;
    case 'relayuser':
    case 'relay':
    case 'normal':
      return UserRole.relayUser;
    case 'sosuser':
    case 'sos_user':
    case 'sos':
      return UserRole.sosUser;
    default:
      return UserRole.sosUser; // Default to SOS for consistency
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final serviceStatus = ref.watch(serviceStatusProvider);
    final devicesAsync = ref.watch(discoveredDevicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Off-Grid SOS'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _refreshDevices(ref);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Scan for devices',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshDevices(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(DesignTokens.spaceMD),
          child: currentUserAsync.when(
            data: (currentUser) {
              if (currentUser == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Please log in to continue'),
                    ],
                  ),
                );
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserProfile(context, currentUser, theme),
                  const SizedBox(height: DesignTokens.spaceLG),
                  _buildStatusSection(context, currentUser, serviceStatus, theme),
                  const SizedBox(height: DesignTokens.spaceLG),
                  _buildNearbySection(context, devicesAsync, theme),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading user data: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(currentUserProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final role = user['role'] as UserRole;
    
    return AppCard(
      padding: const EdgeInsets.all(DesignTokens.spaceLG),
      child: Row(
        children: [
          RoleBadge(
            role: role,
            size: 60,
            showLabel: false,
          ),
          const SizedBox(width: DesignTokens.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXS),
                Text(
                  user['phone'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceSM, 
                    vertical: DesignTokens.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: role.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                    border: Border.all(color: role.color, width: 1),
                  ),
                  child: Text(
                    role.displayName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: role.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, Map<String, dynamic> user, Map<String, bool> serviceStatus, ThemeData theme) {
    final role = user['role'] as UserRole;
    
    return AppCard(
      padding: const EdgeInsets.all(DesignTokens.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.signal_cellular_alt,
                color: role.color,
              ),
              const SizedBox(width: DesignTokens.spaceSM),
              Text(
                'Status',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMD),
          _buildServiceStatusIndicators(serviceStatus, theme),
          const SizedBox(height: DesignTokens.spaceMD),
          _buildRoleStatus(context, role, theme),
        ],
      ),
    );
  }

  Widget _buildServiceStatusIndicators(Map<String, bool> serviceStatus, ThemeData theme) {
    return Wrap(
      spacing: DesignTokens.spaceSM,
      runSpacing: DesignTokens.spaceSM,
      children: serviceStatus.entries.map((entry) {
        return StatusIndicator(
          status: entry.value ? StatusType.online : StatusType.offline,
          text: entry.key.toUpperCase(),
          size: DesignTokens.iconSM,
        );
      }).toList(),
    );
  }

  Widget _buildRoleStatus(BuildContext context, UserRole role, ThemeData theme) {
    switch (role) {
      case UserRole.sosUser:
        return _buildSOSStatus(context, theme);
      case UserRole.rescueUser:
        return _buildRescueStatus(context, theme);
      case UserRole.relayUser:
        return _buildRelayStatus(context, theme);
    }
  }

  Widget _buildSOSStatus(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.emergencyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(color: AppTheme.emergencyColor, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning,
            color: AppTheme.emergencyColor,
            size: DesignTokens.iconLG,
          ),
          const SizedBox(width: DesignTokens.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcasting SOS Signal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.emergencyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXS),
                Text(
                  'Your emergency signal is being broadcast to nearby rescue teams',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescueStatus(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(color: AppTheme.primaryColor, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield,
            color: AppTheme.primaryColor,
            size: DesignTokens.iconLG,
          ),
          const SizedBox(width: DesignTokens.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rescue Mode Active',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXS),
                Text(
                  'Listening for SOS signals and ready to assist',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayStatus(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        border: Border.all(color: AppTheme.successColor, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi,
            color: AppTheme.successColor,
            size: DesignTokens.iconLG,
          ),
          const SizedBox(width: DesignTokens.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relaying Signals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXS),
                Text(
                  'Extending communication range for emergency signals',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySection(BuildContext context, AsyncValue<List<NearbyDevice>> devicesAsync, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline),
            const SizedBox(width: DesignTokens.spaceSM),
            Text(
              'Nearby Users',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            devicesAsync.when(
              data: (devices) => Text(
                '${devices.length} found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Icon(Icons.error, size: 16, color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceMD),
        devicesAsync.when(
          data: (devices) => devices.isEmpty
              ? _buildEmptyState(context, theme)
              : Column(
                  children: devices.map((device) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.spaceSM),
                    child: _buildDeviceCard(context, device, theme),
                  )).toList(),
                ),
          loading: () => const Center(
            child: AppLoadingIndicator(
              message: 'Scanning for nearby devices...',
              showMessage: true,
            ),
          ),
          error: (error, stack) => _buildErrorState(context, error.toString(), theme),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, NearbyDevice device, ThemeData theme) {
    final role = _mapDeviceRoleToUserRole(device.role);
    return AppCard(
      onTap: () => _startChat(context, {
        'id': device.id,
        'name': device.name,
        'role': _mapDeviceRoleToUserRole(device.role),
      }),
      child: Row(
        children: [
          RoleBadge(
            role: role,
            size: 48,
            showLabel: false,
          ),
          const SizedBox(width: DesignTokens.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXS),
                Text(
                  '${device.connectionType.toUpperCase()} • Signal: ${device.signalStrength}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusIndicator(
                status: device.isConnected ? StatusType.online : StatusType.offline,
                showText: false,
                size: DesignTokens.iconSM,
              ),
              const SizedBox(height: DesignTokens.spaceXS),
              if (device.isSOSActive)
                const StatusIndicator(
                  status: StatusType.emergency,
                  text: 'SOS',
                  size: DesignTokens.iconXS,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, ThemeData theme) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Connection Error',
      description: 'Unable to scan for nearby devices: $error',
      actionText: 'Retry',
      onAction: () async {
        // Refresh the devices without ref parameter
        await ServiceCoordinator.instance.initializeAll();
      },
    );
  }

  UserRole _mapDeviceRoleToUserRole(DeviceRole deviceRole) {
    switch (deviceRole) {
      case DeviceRole.sosUser:
        return UserRole.sosUser;
      case DeviceRole.rescuer:
        return UserRole.rescueUser;
      case DeviceRole.normal:
        return UserRole.relayUser;
    }
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'No users found nearby',
      description: 'Make sure Bluetooth and location are enabled, then pull down to refresh.',
      actionText: 'Refresh',
      onAction: () async {
        await ServiceCoordinator.instance.initializeAll();
      },
    );
  }

  Future<void> _refreshDevices(WidgetRef ref) async {
    try {
      // Restart the service coordinator to refresh device discovery
      await ServiceCoordinator.instance.initializeAll();
      debugPrint('✅ Device discovery refreshed');
    } catch (e) {
      debugPrint('❌ Failed to refresh devices: $e');
    }
  }

  void _startChat(BuildContext context, Map<String, dynamic> user) {
    // TODO: Navigate to chat screen with selected user
    Navigator.of(context).pushNamed('/chat', arguments: user);
    Logger.info('Starting chat with ${user['name']}', 'chat');
  }
}