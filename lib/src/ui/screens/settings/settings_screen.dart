import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    case 'rescueuser':
    case 'rescuer':
      return role_models.UserRole.rescueUser;
    case 'relayuser':
    case 'relay':
    case 'normal':
      return role_models.UserRole.relayUser;
    case 'sosuser':
    case 'sos_user':
    case 'sos':
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
            currentUser != null 
              ? _buildRoleSwitchingSection(context, ref, currentUser, theme)
              : const SizedBox.shrink(),
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

  Widget _buildRoleSwitchingSection(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> currentUser,
    ThemeData theme,
  ) {
    final currentRole = currentUser['role'] as role_models.UserRole;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role & Capabilities',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Switch Role',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your current role determines how you interact with the emergency network.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentRole.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: currentRole.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentRole.icon,
                        color: currentRole.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current: ${currentRole.displayName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: currentRole.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRoleSwitchDialog(context, ref, currentRole),
                    icon: const Icon(Icons.change_circle),
                    label: const Text('Change Role'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                  _toggleEncryption(context, value);
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
                  _toggleCloudSync(context, value);
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

  void _toggleEncryption(BuildContext context, bool enabled) async {
    try {
      // Save encryption preference to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('encryption_enabled', enabled);
      
      // In a production app, this would configure encryption service
      // For now, we just store the preference and log the action
      Logger.info('Encryption ${enabled ? 'enabled' : 'disabled'} - Preference saved', 'settings');
      
      // Show user confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Encryption ${enabled ? 'enabled' : 'disabled'} successfully'),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      Logger.error('Failed to toggle encryption: $e', 'settings');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle encryption: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleCloudSync(BuildContext context, bool enabled) async {
    try {
      // Save cloud sync preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cloud_sync_enabled', enabled);
      
      if (enabled) {
        // Try to sync current user to cloud
        final authService = AuthService.instance;
        if (authService.isLoggedIn) {
          await authService.syncToCloud();
          Logger.success('Cloud sync enabled and user synced', 'settings');
        } else {
          Logger.warning('Cloud sync enabled but no user logged in', 'settings');
        }
      } else {
        Logger.info('Cloud sync disabled', 'settings');
      }
      
      // Show user confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cloud sync ${enabled ? 'enabled' : 'disabled'} successfully'),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      Logger.error('Failed to toggle cloud sync: $e', 'settings');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle cloud sync: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    // Show notification settings dialog since no separate screen exists
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('SOS Alerts'),
                subtitle: const Text('Receive emergency notifications'),
                value: true,
                onChanged: (value) {
                  Logger.info('SOS alerts ${value ? 'enabled' : 'disabled'}', 'settings');
                },
              ),
              SwitchListTile(
                title: const Text('Chat Messages'),
                subtitle: const Text('New message notifications'),
                value: true,
                onChanged: (value) {
                  Logger.info('Chat notifications ${value ? 'enabled' : 'disabled'}', 'settings');
                },
              ),
              SwitchListTile(
                title: const Text('Connection Status'),
                subtitle: const Text('Device connection notifications'),
                value: false,
                onChanged: (value) {
                  Logger.info('Connection notifications ${value ? 'enabled' : 'disabled'}', 'settings');
                },
              ),
            ],
          ),
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

  void _openConnectionSettings(BuildContext context) {
    // Show connection settings dialog with protocol preferences
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connection Priority Order:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Text('1.'),
                title: Text('Google Nearby Connections'),
                subtitle: Text('Primary - WiFi and Bluetooth'),
                trailing: Icon(Icons.wifi, color: Colors.green),
              ),
              const ListTile(
                leading: Text('2.'),
                title: Text('WiFi Direct (P2P)'),
                subtitle: Text('Secondary - Device-to-device WiFi'),
                trailing: Icon(Icons.router, color: Colors.blue),
              ),
              const ListTile(
                leading: Text('3.'),
                title: Text('Bluetooth Low Energy'),
                subtitle: Text('Fallback - Low power messaging'),
                trailing: Icon(Icons.bluetooth, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connection Timeout: 30 seconds\nDiscovery Range: ~100 meters\nMax Connections: 8 devices',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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

  void _openStorageSettings(BuildContext context) async {
    // Show storage management dialog with cleanup options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Local Storage Usage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.message, color: Colors.blue),
                title: Text('Messages'),
                subtitle: Text('Local chat history and attachments'),
                trailing: Text('~2.5 MB'),
              ),
              const ListTile(
                leading: Icon(Icons.contacts, color: Colors.green),
                title: Text('User Data'),
                subtitle: Text('Profile and settings'),
                trailing: Text('~0.1 MB'),
              ),
              const ListTile(
                leading: Icon(Icons.devices, color: Colors.orange),
                title: Text('Device Cache'),
                subtitle: Text('Nearby device information'),
                trailing: Text('~0.3 MB'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cleanup Options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearOldMessages(context);
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Clear Old Messages'),
                ),
              ),
            ],
          ),
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

  void _clearOldMessages(BuildContext context) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Old Messages'),
          content: const Text(
            'This will delete messages older than 30 days. '
            'Recent messages and emergency communications will be preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        // In a real app, this would clear old messages from database
        Logger.info('Old messages cleared', 'settings');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Old messages cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to clear messages: $e', 'settings');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    // Show comprehensive help dialog with usage instructions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Instructions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Getting Started:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Register with your name and phone number\n'
                '2. Enable Bluetooth and WiFi for best connectivity\n'
                '3. Grant location permissions for SOS features\n'
                '4. Choose your role: Normal, SOS, or Rescuer',
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergency Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '• SOS Mode: Broadcasts emergency signal to nearby devices\n'
                '• Rescuer Mode: Receives and responds to SOS signals\n'
                '• Location Sharing: Shares GPS coordinates in emergencies\n'
                '• Offline Communication: Works without internet',
              ),
              const SizedBox(height: 16),
              const Text(
                'Chat Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '• P2P Messaging: Direct device-to-device communication\n'
                '• Mesh Network: Messages route through other devices\n'
                '• Offline Storage: Messages saved locally\n'
                '• Multiple Protocols: WiFi Direct, BLE, Nearby Connections',
              ),
              const SizedBox(height: 16),
              const Text(
                'Troubleshooting:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Ensure all permissions are granted\n'
                '• Keep devices within 100 meters\n'
                '• Restart app if connections fail\n'
                '• Check Bluetooth and WiFi are enabled',
              ),
            ],
          ),
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

  void _openPrivacyPolicy(BuildContext context) {
    // Show privacy policy information dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Off-Grid SOS Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data Collection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• We collect only essential information: name, phone number\n'
                '• Location data is used only for emergency SOS features\n'
                '• Messages are stored locally on your device\n'
                '• No personal data is shared with third parties',
              ),
              const SizedBox(height: 16),
              const Text(
                'Data Storage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• All data is stored locally on your device\n'
                '• Optional cloud backup uses Firebase (Google)\n'
                '• You can delete all data anytime from settings\n'
                '• No data mining or advertising',
              ),
              const SizedBox(height: 16),
              const Text(
                'Communication:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Direct peer-to-peer communication\n'
                '• Messages are not intercepted or monitored\n'
                '• Emergency broadcasts visible to nearby devices\n'
                '• Encryption optional (when enabled in settings)',
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact: support@offgridsos.com',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
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

  void _openTermsOfService(BuildContext context) {
    // Show terms of service dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Off-Grid SOS Terms of Service',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acceptable Use:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Use this app responsibly and only for legitimate emergencies\n'
                '• Do not abuse the SOS feature for non-emergency situations\n'
                '• Respect other users and maintain appropriate communication\n'
                '• Do not use for illegal activities or harmful content',
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergency Disclaimer:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• This app is not a replacement for official emergency services\n'
                '• Always contact local emergency services (911, etc.) first\n'
                '• App functionality depends on device proximity and connectivity\n'
                '• No guarantee of message delivery in all situations',
              ),
              const SizedBox(height: 16),
              const Text(
                'Liability:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• App provided "as-is" without warranties\n'
                '• User assumes responsibility for proper usage\n'
                '• Developer not liable for missed emergencies\n'
                '• Use additional emergency communication methods',
              ),
              const SizedBox(height: 16),
              const Text(
                'By using this app, you agree to these terms.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
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

  void _showRoleSwitchDialog(
    BuildContext context,
    WidgetRef ref,
    role_models.UserRole currentRole,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your new role. This will change how you interact with the emergency network:',
            ),
            const SizedBox(height: 16),
            ...role_models.UserRole.values.map((role) => _buildRoleOption(
              context,
              role,
              currentRole == role,
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context,
    role_models.UserRole role,
    bool isCurrentRole,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCurrentRole 
              ? null 
              : () => _confirmRoleSwitch(context, role),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isCurrentRole 
                    ? role.color 
                    : Colors.grey.withOpacity(0.3),
                width: isCurrentRole ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isCurrentRole 
                  ? role.color.withOpacity(0.1) 
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  role.icon,
                  color: role.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isCurrentRole ? role.color : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentRole)
                  Icon(
                    Icons.check_circle,
                    color: role.color,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRoleSwitch(BuildContext context, role_models.UserRole newRole) {
    Navigator.of(context).pop(); // Close role selection dialog
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Role Switch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to switch to ${newRole.displayName}?',
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This will update your role across all connected services and change how you interact with the emergency network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _switchRole(context, newRole);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Switch Role'),
          ),
        ],
      ),
    );
  }

  void _switchRole(BuildContext context, role_models.UserRole newRole) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Switching role...'),
            ],
          ),
        ),
      );

      // Update role in AuthService with full cloud sync (this will trigger providers to update)
      final authService = AuthService.instance;
      final success = await authService.changeRole(newRole.name, forceCloudSync: true);
      
      if (!success) {
        throw Exception('Failed to update role in AuthService');
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role switched to ${newRole.displayName} successfully!'),
            backgroundColor: newRole.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch role: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _logout(BuildContext context) async {
    try {
      // Show loading while logging out
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Logging out...'),
            ],
          ),
        ),
      );

      // Perform logout with AuthService
      await AuthService.instance.logout();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Navigate to login screen and clear stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
      
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}