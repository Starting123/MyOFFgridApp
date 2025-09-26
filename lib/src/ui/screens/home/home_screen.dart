import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
import '../../widgets/common/reusable_widgets.dart';

// Mock data providers - replace with actual service providers
final currentUserProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'name': 'John Doe',
    'phone': '+1234567890',
    'role': UserRole.sosUser, // Change this to test different roles
  };
});

final nearbyUsersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final currentRole = currentUser['role'] as UserRole;
  
  // Show different users based on current user's role
  if (currentRole == UserRole.rescueUser) {
    // Rescue users see SOS users
    return [
      {
        'name': 'Alice Emergency',
        'phone': '+1234567891',
        'role': UserRole.sosUser,
        'lastSeen': DateTime.now().subtract(const Duration(minutes: 2)),
        'distance': '0.5 km',
      },
      {
        'name': 'Bob Crisis',
        'phone': '+1234567892',
        'role': UserRole.sosUser,
        'lastSeen': DateTime.now().subtract(const Duration(minutes: 5)),
        'distance': '1.2 km',
      },
    ];
  } else if (currentRole == UserRole.sosUser) {
    // SOS users see rescue users
    return [
      {
        'name': 'Rescue Team Alpha',
        'phone': '+1234567893',
        'role': UserRole.rescueUser,
        'lastSeen': DateTime.now().subtract(const Duration(minutes: 1)),
        'distance': '0.8 km',
      },
      {
        'name': 'Medical Support',
        'phone': '+1234567894',
        'role': UserRole.rescueUser,
        'lastSeen': DateTime.now().subtract(const Duration(minutes: 3)),
        'distance': '1.5 km',
      },
    ];
  } else {
    // Relay users see all types
    return [
      {
        'name': 'Alice Emergency',
        'phone': '+1234567891',
        'role': UserRole.sosUser,
        'lastSeen': DateTime.now().subtract(const Duration(minutes: 2)),
        'distance': '0.5 km',
      },
      {
        'name': 'Rescue Team Alpha',
        'phone': '+1234567893',
        'role': UserRole.rescueUser,
        'lastSeen': DateTime.now().subtract(const Duration(minutes: 1)),
        'distance': '0.8 km',
      },
    ];
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final nearbyUsers = ref.watch(nearbyUsersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Off-Grid SOS'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement refresh/scan for devices
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserProfile(context, currentUser, theme),
              const SizedBox(height: 24),
              _buildStatusSection(context, currentUser, theme),
              const SizedBox(height: 24),
              _buildNearbySection(context, nearbyUsers, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final role = user['role'] as UserRole;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            RoleBadge(
              role: role,
              size: 60,
              showLabel: false,
            ),
            const SizedBox(width: 20),
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
                  const SizedBox(height: 4),
                  Text(
                    user['phone'],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: role.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final role = user['role'] as UserRole;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  color: role.color,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRoleStatus(context, role, theme),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcasting SOS Signal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rescue Mode Active',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relaying Signals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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

  Widget _buildNearbySection(BuildContext context, List<Map<String, dynamic>> nearbyUsers, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline),
            const SizedBox(width: 8),
            Text(
              'Nearby Users',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${nearbyUsers.length} found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (nearbyUsers.isEmpty)
          _buildEmptyState(context, theme)
        else
          ...nearbyUsers.map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: UserCard(
                  name: user['name'],
                  phone: user['phone'],
                  role: user['role'],
                  lastSeen: user['lastSeen'],
                  lastMessage: 'Distance: ${user['distance']}',
                  onChatTap: () {
                    // TODO: Navigate to chat with this user
                    _startChat(context, user);
                  },
                ),
              )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found nearby',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure Bluetooth and location are enabled',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshDevices(WidgetRef ref) async {
    // TODO: Implement device scanning with nearby_service
    await Future.delayed(const Duration(seconds: 2));
    print('Refreshing nearby devices...');
  }

  void _startChat(BuildContext context, Map<String, dynamic> user) {
    // TODO: Navigate to chat screen with selected user
    Navigator.of(context).pushNamed('/chat', arguments: user);
    print('Starting chat with ${user['name']}');
  }
}