import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  
  // Mock settings - in real app from providers/shared preferences
  bool _notificationsEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _backgroundScanningEnabled = false;
  bool _autoConnectEnabled = true;
  bool _encryptionEnabled = true;
  bool _cloudSyncEnabled = false;
  bool _locationServicesEnabled = true;
  bool _batteryOptimizationEnabled = true;
  
  String _userName = 'John Doe';
  String _deviceName = 'John\'s Phone';
  String _emergencyContact = '+1 234 567 8900';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(theme),
              
              // User Profile Section
              _buildUserProfileSection(theme),
              
              // Emergency Settings
              _buildEmergencySettingsSection(theme),
              
              // Communication Settings
              _buildCommunicationSettingsSection(theme),
              
              // Privacy & Security
              _buildPrivacySecuritySection(theme),
              
              // Device Settings
              _buildDeviceSettingsSection(theme),
              
              // About & Support
              _buildAboutSupportSection(theme),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.settings,
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
                  'Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Configure your emergency app',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(ThemeData theme) {
    return _buildSection(
      theme,
      'User Profile',
      Icons.person,
      [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(_userName),
          subtitle: const Text('Tap to edit profile'),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editUserProfile(context),
        ),
        ListTile(
          leading: const Icon(Icons.smartphone),
          title: const Text('Device Name'),
          subtitle: Text(_deviceName),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editDeviceName(context),
        ),
        ListTile(
          leading: const Icon(Icons.emergency),
          title: const Text('Emergency Contact'),
          subtitle: Text(_emergencyContact),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editEmergencyContact(context),
        ),
      ],
    );
  }

  Widget _buildEmergencySettingsSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Emergency Settings',
      Icons.warning,
      [
        SwitchListTile(
          secondary: const Icon(Icons.notification_important),
          title: const Text('Emergency Alerts'),
          subtitle: const Text('Receive alerts for nearby emergencies'),
          value: _emergencyAlertsEnabled,
          onChanged: (value) {
            setState(() {
              _emergencyAlertsEnabled = value;
            });
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.location_on),
          title: const Text('Location Services'),
          subtitle: const Text('Share location in emergencies'),
          value: _locationServicesEnabled,
          onChanged: (value) {
            setState(() {
              _locationServicesEnabled = value;
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('SOS Timeout'),
          subtitle: const Text('Auto-disable SOS after: 30 minutes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSOSTimeoutDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.vibration),
          title: const Text('Emergency Vibration Pattern'),
          subtitle: const Text('Custom vibration for emergencies'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showVibrationSettings(context),
        ),
      ],
    );
  }

  Widget _buildCommunicationSettingsSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Communication',
      Icons.wifi,
      [
        SwitchListTile(
          secondary: const Icon(Icons.wifi_tethering),
          title: const Text('Auto-connect to Devices'),
          subtitle: const Text('Automatically connect to nearby devices'),
          value: _autoConnectEnabled,
          onChanged: (value) {
            setState(() {
              _autoConnectEnabled = value;
            });
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.radar),
          title: const Text('Background Scanning'),
          subtitle: const Text('Scan for devices when app is closed'),
          value: _backgroundScanningEnabled,
          onChanged: (value) {
            setState(() {
              _backgroundScanningEnabled = value;
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.bluetooth),
          title: const Text('Connection Protocols'),
          subtitle: const Text('Bluetooth, WiFi Direct, Nearby'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showConnectionProtocolsSettings(context),
        ),
        ListTile(
          leading: const Icon(Icons.network_check),
          title: const Text('Network Priority'),
          subtitle: const Text('Mesh > WiFi Direct > Bluetooth'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showNetworkPrioritySettings(context),
        ),
      ],
    );
  }

  Widget _buildPrivacySecuritySection(ThemeData theme) {
    return _buildSection(
      theme,
      'Privacy & Security',
      Icons.security,
      [
        SwitchListTile(
          secondary: const Icon(Icons.lock),
          title: const Text('End-to-End Encryption'),
          subtitle: const Text('Encrypt all messages and data'),
          value: _encryptionEnabled,
          onChanged: (value) {
            setState(() {
              _encryptionEnabled = value;
            });
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_off),
          title: const Text('Cloud Sync'),
          subtitle: const Text('Sync data when online (not recommended)'),
          value: _cloudSyncEnabled,
          onChanged: (value) {
            setState(() {
              _cloudSyncEnabled = value;
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('Encryption Keys'),
          subtitle: const Text('Manage device encryption keys'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showEncryptionKeysSettings(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Clear All Data'),
          subtitle: const Text('Delete messages, contacts, and settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showClearDataDialog(context),
        ),
      ],
    );
  }

  Widget _buildDeviceSettingsSection(ThemeData theme) {
    return _buildSection(
      theme,
      'Device Settings',
      Icons.settings_applications,
      [
        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          subtitle: const Text('Show app notifications'),
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.battery_saver),
          title: const Text('Battery Optimization'),
          subtitle: const Text('Reduce power consumption'),
          value: _batteryOptimizationEnabled,
          onChanged: (value) {
            setState(() {
              _batteryOptimizationEnabled = value;
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Storage Usage'),
          subtitle: const Text('View app storage and cache'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showStorageSettings(context),
        ),
        ListTile(
          leading: const Icon(Icons.system_update),
          title: const Text('App Updates'),
          subtitle: const Text('Check for updates'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _checkForUpdates(context),
        ),
      ],
    );
  }

  Widget _buildAboutSupportSection(ThemeData theme) {
    return _buildSection(
      theme,
      'About & Support',
      Icons.info,
      [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About Off-Grid SOS'),
          subtitle: const Text('Version 1.0.0'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAboutDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & FAQ'),
          subtitle: const Text('Get help and view frequently asked questions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showHelpFAQ(context),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Report Bug'),
          subtitle: const Text('Report issues or suggest improvements'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _reportBug(context),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          subtitle: const Text('View our privacy policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPrivacyPolicy(context),
        ),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          ...children,
        ],
      ),
    );
  }

  // Edit methods
  void _editUserProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: TextEditingController(text: _userName),
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
          onChanged: (value) {
            _userName = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editDeviceName(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: TextEditingController(text: _deviceName),
          decoration: const InputDecoration(
            labelText: 'Device Name',
            hintText: 'Enter device name',
          ),
          onChanged: (value) {
            _deviceName = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editEmergencyContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Contact'),
        content: TextField(
          controller: TextEditingController(text: _emergencyContact),
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter emergency contact number',
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) {
            _emergencyContact = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Settings dialogs and actions
  void _showSOSTimeoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Timeout'),
        content: const Text('Choose how long SOS mode stays active:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('15 minutes'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('30 minutes'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('1 hour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showVibrationSettings(BuildContext context) {
    // TODO: Implement vibration pattern settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vibration settings - Coming soon')),
    );
  }

  void _showConnectionProtocolsSettings(BuildContext context) {
    // TODO: Implement connection protocols settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection protocols settings - Coming soon')),
    );
  }

  void _showNetworkPrioritySettings(BuildContext context) {
    // TODO: Implement network priority settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network priority settings - Coming soon')),
    );
  }

  void _showEncryptionKeysSettings(BuildContext context) {
    // TODO: Implement encryption keys management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Encryption keys management - Coming soon')),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all messages, contacts, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showStorageSettings(BuildContext context) {
    // TODO: Implement storage settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage settings - Coming soon')),
    );
  }

  void _checkForUpdates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for updates...')),
    );
    
    // Simulate update check
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are using the latest version')),
        );
      }
    });
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Off-Grid SOS & Nearby Share',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.offline_bolt,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'An offline-first emergency communication app that enables secure mesh networking for crisis situations.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• SOS broadcasting and rescue coordination\n'
          '• Mesh networking via Bluetooth LE and WiFi Direct\n'
          '• End-to-end encrypted messaging\n'
          '• Offline-first architecture\n'
          '• Location sharing for emergencies',
        ),
      ],
    );
  }

  void _showHelpFAQ(BuildContext context) {
    // TODO: Implement help & FAQ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & FAQ - Coming soon')),
    );
  }

  void _reportBug(BuildContext context) {
    // TODO: Implement bug reporting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bug reporting - Coming soon')),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    // TODO: Implement privacy policy view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy - Coming soon')),
    );
  }
}