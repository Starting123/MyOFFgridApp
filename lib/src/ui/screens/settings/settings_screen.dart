import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart' as role_models;
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/service_coordinator.dart';
import '../../widgets/common/reusable_widgets.dart';
import '../../../utils/logger.dart';

// Real user provider connected to auth service
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return AuthService.instance.userStream;
});

// Convert UserModel to Map for backward compatibility
final settingsCurrentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null ? {
      'name': user.name,
      'phone': user.phone ?? '',
      'role': _mapStringToUserRole(user.role),
    } : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

role_models.UserRole _mapStringToUserRole(String role) {
  switch (role.toLowerCase()) {
    case 'rescuer':
      return role_models.UserRole.rescueUser;
    case 'normal':
      return role_models.UserRole.relayUser;
    case 'sos_user':
      return role_models.UserRole.sosUser;
    default:
      return role_models.UserRole.sosUser;
  }
}

// Settings state notifiers
class SettingsNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return {
      'encryption': true,
      'cloudSync': false,
    };
  }
  
  void toggleEncryption() {
    state = {...state, 'encryption': !state['encryption']!};
  }
  
  void toggleCloudSync() {
    state = {...state, 'cloudSync': !state['cloudSync']!};
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Map<String, bool>>(() {
  return SettingsNotifier();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(settingsCurrentUserProvider);
    final settings = ref.watch(settingsProvider);
    final encryptionEnabled = settings['encryption'] ?? true;
    final cloudSyncEnabled = settings['cloudSync'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            currentUser != null 
              ? _buildUserProfile(context, currentUser, theme)
              : _buildLoadingUserProfile(theme),
            const SizedBox(height: 24),
            _buildSecuritySection(context, ref, encryptionEnabled, cloudSyncEnabled, theme),
            const SizedBox(height: 24),
            _buildCommunicationSection(context, ref, theme),
            const SizedBox(height: 24),
            _buildAppSection(context, theme),
            const SizedBox(height: 24),
            _buildAboutSection(context, theme),
            const SizedBox(height: 24),
            _buildLogoutButton(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingUserProfile(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 24,
                        width: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final role = user['role'] as role_models.UserRole;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
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
                IconButton(
                  onPressed: () => _editProfile(context),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(
    BuildContext context,
    WidgetRef ref,
    bool encryptionEnabled,
    bool cloudSyncEnabled,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security & Privacy',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('End-to-End Encryption'),
                subtitle: const Text('Encrypt all messages and media'),
                value: encryptionEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).toggleEncryption();
                  _toggleEncryption(value);
                },
                secondary: const Icon(Icons.security),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Cloud Sync'),
                subtitle: const Text('Sync data when internet is available'),
                value: cloudSyncEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).toggleCloudSync();
                  _toggleCloudSync(value);
                },
                secondary: const Icon(Icons.cloud),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunicationSection(BuildContext context, WidgetRef ref, ThemeData theme) {
    final serviceStatus = ServiceCoordinator.instance.getServiceStatus();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Services',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _buildServiceToggle(
                context,
                theme,
                'Nearby Connections',
                'Short-range device-to-device communication',
                Icons.wifi_tethering,
                serviceStatus['nearby'] ?? false,
                (enabled) => _toggleNearbyService(context, enabled),
              ),
              const Divider(height: 1),
              _buildServiceToggle(
                context,
                theme,
                'WiFi Direct',
                'High-speed peer-to-peer networking',
                Icons.wifi,
                serviceStatus['p2p'] ?? false,
                (enabled) => _toggleP2PService(context, enabled),
              ),
              const Divider(height: 1),
              _buildServiceToggle(
                context,
                theme,
                'Bluetooth LE',
                'Low-energy device communication',
                Icons.bluetooth,
                serviceStatus['ble'] ?? false,
                (enabled) => _toggleBLEService(context, enabled),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceToggle(
    BuildContext context,
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool isEnabled,
    Function(bool) onToggle,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: isEnabled,
        onChanged: onToggle,
      ),
    );
  }

  Widget _buildAppSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: const Text('Manage notification preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openNotificationSettings(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bluetooth),
                title: const Text('Connection Settings'),
                subtitle: const Text('Bluetooth, WiFi Direct, and Nearby'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openConnectionSettings(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Storage'),
                subtitle: const Text('Manage app data and cache'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openStorageSettings(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                onTap: () => _showVersionInfo(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and report issues'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openHelp(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.policy),
                title: const Text('Privacy Policy'),
                subtitle: const Text('Read our privacy policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPrivacyPolicy(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                subtitle: const Text('Read our terms of service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openTermsOfService(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _editProfile(BuildContext context) async {
    final authService = AuthService.instance;
    final currentUser = await authService.userStream.first;
    
    if (currentUser == null) return;
    
    final nameController = TextEditingController(text: currentUser.name);
    final phoneController = TextEditingController(text: currentUser.phone ?? '');
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      try {
        // Update the user profile in AuthService
        final success = await authService.updateProfile(
          name: result['name']!,
          phone: result['phone']!.isEmpty ? null : result['phone'],
        );
        
        if (!success) {
          throw Exception('Failed to update profile');
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _toggleEncryption(bool enabled) {
    // TODO: Implement encryption toggle with security service
    Logger.info('Encryption ${enabled ? 'enabled' : 'disabled'}', 'settings');
  }

  void _toggleCloudSync(bool enabled) {
    // TODO: Implement cloud sync toggle with cloud_sync_service
    Logger.info('Cloud sync ${enabled ? 'enabled' : 'disabled'}', 'settings');
  }

  void _toggleNearbyService(BuildContext context, bool enabled) async {
    try {
      if (enabled) {
        // Re-initialize nearby service if needed
        ServiceCoordinator.instance;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nearby Connections enabled')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nearby Connections disabled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling Nearby service: $e')),
      );
    }
  }

  void _toggleP2PService(BuildContext context, bool enabled) async {
    try {
      if (enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WiFi Direct enabled')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WiFi Direct disabled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling P2P service: $e')),
      );
    }
  }

  void _toggleBLEService(BuildContext context, bool enabled) async {
    try {
      if (enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth LE enabled')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth LE disabled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling BLE service: $e')),
      );
    }
  }

  void _openNotificationSettings(BuildContext context) {
    // TODO: Navigate to notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings not implemented')),
    );
  }

  void _openConnectionSettings(BuildContext context) {
    // TODO: Navigate to connection settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection settings not implemented')),
    );
  }

  void _openStorageSettings(BuildContext context) {
    // TODO: Navigate to storage settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage settings not implemented')),
    );
  }

  void _showVersionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Off-Grid SOS & Nearby Share'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 1'),
            SizedBox(height: 16),
            Text('Emergency communication app for offline scenarios'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openHelp(BuildContext context) {
    // TODO: Navigate to help screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help screen not implemented')),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    // TODO: Open privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy not implemented')),
    );
  }

  void _openTermsOfService(BuildContext context) {
    // TODO: Open terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of service not implemented')),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    // TODO: Implement logout with auth_service
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}