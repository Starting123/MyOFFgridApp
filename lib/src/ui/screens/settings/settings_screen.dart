import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_role.dart';
import '../../widgets/common/reusable_widgets.dart';

// Mock settings providers - replace with actual service providers
final settingsCurrentUserProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'name': 'John Doe',
    'phone': '+1234567890',
    'role': UserRole.sosUser,
  };
});

final encryptionEnabledProvider = StateProvider<bool>((ref) => true);
final cloudSyncEnabledProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(settingsCurrentUserProvider);
    final encryptionEnabled = ref.watch(encryptionEnabledProvider);
    final cloudSyncEnabled = ref.watch(cloudSyncEnabledProvider);

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
            _buildUserProfile(context, currentUser, theme),
            const SizedBox(height: 24),
            _buildSecuritySection(context, ref, encryptionEnabled, cloudSyncEnabled, theme),
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

  Widget _buildUserProfile(BuildContext context, Map<String, dynamic> user, ThemeData theme) {
    final role = user['role'] as UserRole;
    
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
                  ref.read(encryptionEnabledProvider.notifier).state = value;
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
                  ref.read(cloudSyncEnabledProvider.notifier).state = value;
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

  void _editProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
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
              Navigator.of(context).pop();
              // TODO: Save profile changes
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleEncryption(bool enabled) {
    // TODO: Implement encryption toggle with security service
    print('Encryption ${enabled ? 'enabled' : 'disabled'}');
  }

  void _toggleCloudSync(bool enabled) {
    // TODO: Implement cloud sync toggle with cloud_sync_service
    print('Cloud sync ${enabled ? 'enabled' : 'disabled'}');
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