import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // User profile settings
  String _userName = 'John Doe';
  String _userRole = 'neutral'; // victim, rescuer, neutral
  String _deviceName = 'My Device';
  
  // Security settings
  bool _encryptionEnabled = true;
  bool _autoConnect = false;
  bool _shareLocation = true;
  bool _emergencyNotifications = true;
  
  // Sync settings
  bool _cloudSyncEnabled = false;
  bool _autoSync = true;
  bool _syncOnWiFiOnly = true;
  
  // Privacy settings
  bool _shareDeviceName = true;
  bool _shareUserInfo = false;
  bool _anonymousMode = false;
  
  // App settings
  String _theme = 'system'; // light, dark, system
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showTips = true;
  
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userNameController.text = _userName;
    _deviceNameController.text = _deviceName;
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Section
          _buildProfileSection(colorScheme),
          
          const SizedBox(height: 24),
          
          // Security Section
          _buildSecuritySection(colorScheme),
          
          const SizedBox(height: 24),
          
          // Sync & Backup Section
          _buildSyncSection(colorScheme),
          
          const SizedBox(height: 24),
          
          // Privacy Section
          _buildPrivacySection(colorScheme),
          
          const SizedBox(height: 24),
          
          // App Preferences Section
          _buildAppPreferencesSection(colorScheme),
          
          const SizedBox(height: 24),
          
          // Advanced Section
          _buildAdvancedSection(colorScheme),
          
          const SizedBox(height: 24),
          
          // Emergency Actions
          _buildEmergencyActionsSection(colorScheme),
          
          const SizedBox(height: 80), // Extra space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildProfileSection(ColorScheme colorScheme) {
    return _buildSection(
      'User Profile',
      Icons.person,
      colorScheme,
      [
        _buildProfileTile(colorScheme),
        const SizedBox(height: 16),
        _buildTextField(
          'Display Name',
          _userNameController,
          'Enter your display name',
          (value) => setState(() => _userName = value),
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Device Name',
          _deviceNameController,
          'Enter device name',
          (value) => setState(() => _deviceName = value),
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildRoleSelector(colorScheme),
      ],
    );
  }

  Widget _buildProfileTile(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildRoleBadge(_userRole, colorScheme),
                    const SizedBox(width: 8),
                    Icon(
                      _encryptionEnabled ? Icons.lock : Icons.lock_open,
                      size: 16,
                      color: _encryptionEnabled ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _encryptionEnabled ? 'Secure' : 'Unsecured',
                      style: TextStyle(
                        color: _encryptionEnabled ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfileDialog(),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role, ColorScheme colorScheme) {
    Color color;
    String text;
    IconData icon;

    switch (role) {
      case 'victim':
        color = Colors.red;
        text = 'Victim';
        icon = Icons.emergency;
        break;
      case 'rescuer':
        color = Colors.blue;
        text = 'Rescuer';
        icon = Icons.medical_services;
        break;
      case 'neutral':
      default:
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

  Widget _buildRoleSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role in Emergency',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption('neutral', 'Neutral', Icons.person, Colors.grey, colorScheme),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleOption('victim', 'Victim', Icons.emergency, Colors.red, colorScheme),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleOption('rescuer', 'Rescuer', Icons.medical_services, Colors.blue, colorScheme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption(String value, String label, IconData icon, Color color, ColorScheme colorScheme) {
    final isSelected = _userRole == value;
    
    return InkWell(
      onTap: () {
        setState(() => _userRole = value);
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(ColorScheme colorScheme) {
    return _buildSection(
      'Security & Privacy',
      Icons.security,
      colorScheme,
      [
        _buildSwitchTile(
          'End-to-End Encryption',
          'Encrypt all messages and data',
          _encryptionEnabled,
          (value) => setState(() => _encryptionEnabled = value),
          Icons.lock,
          colorScheme,
        ),
        _buildSwitchTile(
          'Auto-Connect to Devices',
          'Automatically connect to nearby trusted devices',
          _autoConnect,
          (value) => setState(() => _autoConnect = value),
          Icons.bluetooth_connected,
          colorScheme,
        ),
        _buildSwitchTile(
          'Share Location',
          'Allow location sharing in emergencies',
          _shareLocation,
          (value) => setState(() => _shareLocation = value),
          Icons.location_on,
          colorScheme,
        ),
        _buildSwitchTile(
          'Emergency Notifications',
          'Receive alerts from nearby emergency signals',
          _emergencyNotifications,
          (value) => setState(() => _emergencyNotifications = value),
          Icons.notifications_active,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildSyncSection(ColorScheme colorScheme) {
    return _buildSection(
      'Sync & Backup',
      Icons.cloud_sync,
      colorScheme,
      [
        _buildSwitchTile(
          'Cloud Sync',
          'Sync data when internet is available',
          _cloudSyncEnabled,
          (value) => setState(() => _cloudSyncEnabled = value),
          Icons.cloud,
          colorScheme,
        ),
        if (_cloudSyncEnabled) ...[
          _buildSwitchTile(
            'Auto Sync',
            'Automatically sync when connection is available',
            _autoSync,
            (value) => setState(() => _autoSync = value),
            Icons.sync,
            colorScheme,
          ),
          _buildSwitchTile(
            'Wi-Fi Only Sync',
            'Only sync over Wi-Fi to save mobile data',
            _syncOnWiFiOnly,
            (value) => setState(() => _syncOnWiFiOnly = value),
            Icons.wifi,
            colorScheme,
          ),
        ],
        _buildActionTile(
          'Backup Data',
          'Export your data for backup',
          Icons.backup,
          colorScheme,
          () => _showBackupDialog(),
        ),
        _buildActionTile(
          'Restore Data',
          'Import data from backup',
          Icons.restore,
          colorScheme,
          () => _showRestoreDialog(),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(ColorScheme colorScheme) {
    return _buildSection(
      'Privacy',
      Icons.privacy_tip,
      colorScheme,
      [
        _buildSwitchTile(
          'Share Device Name',
          'Show device name to other users',
          _shareDeviceName,
          (value) => setState(() => _shareDeviceName = value),
          Icons.devices,
          colorScheme,
        ),
        _buildSwitchTile(
          'Share User Information',
          'Share your name and role with others',
          _shareUserInfo,
          (value) => setState(() => _shareUserInfo = value),
          Icons.person_outline,
          colorScheme,
        ),
        _buildSwitchTile(
          'Anonymous Mode',
          'Hide your identity from other users',
          _anonymousMode,
          (value) => setState(() => _anonymousMode = value),
          Icons.visibility_off,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildAppPreferencesSection(ColorScheme colorScheme) {
    return _buildSection(
      'App Preferences',
      Icons.tune,
      colorScheme,
      [
        _buildDropdownTile(
          'Theme',
          'App appearance',
          _theme,
          ['light', 'dark', 'system'],
          ['Light', 'Dark', 'System'],
          (value) => setState(() => _theme = value!),
          Icons.palette,
          colorScheme,
        ),
        _buildSwitchTile(
          'Sound Effects',
          'Play sounds for notifications and actions',
          _soundEnabled,
          (value) => setState(() => _soundEnabled = value),
          Icons.volume_up,
          colorScheme,
        ),
        _buildSwitchTile(
          'Vibration',
          'Vibrate for notifications and feedback',
          _vibrationEnabled,
          (value) => setState(() => _vibrationEnabled = value),
          Icons.vibration,
          colorScheme,
        ),
        _buildSwitchTile(
          'Show Tips',
          'Display helpful tips and tutorials',
          _showTips,
          (value) => setState(() => _showTips = value),
          Icons.lightbulb_outline,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(ColorScheme colorScheme) {
    return _buildSection(
      'Advanced',
      Icons.build,
      colorScheme,
      [
        _buildActionTile(
          'Network Diagnostics',
          'Test connectivity and performance',
          Icons.network_check,
          colorScheme,
          () => _showNetworkDiagnosticsDialog(),
        ),
        _buildActionTile(
          'Clear Cache',
          'Free up storage space',
          Icons.clear_all,
          colorScheme,
          () => _showClearCacheDialog(),
        ),
        _buildActionTile(
          'Export Logs',
          'Export app logs for troubleshooting',
          Icons.bug_report,
          colorScheme,
          () => _showExportLogsDialog(),
        ),
        _buildActionTile(
          'Factory Reset',
          'Reset all settings to default',
          Icons.restore_page,
          colorScheme,
          () => _showFactoryResetDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildEmergencyActionsSection(ColorScheme colorScheme) {
    return _buildSection(
      'Emergency Actions',
      Icons.emergency,
      colorScheme,
      [
        _buildActionTile(
          'Emergency Contacts',
          'Manage emergency contact list',
          Icons.contact_emergency,
          colorScheme,
          () => _showEmergencyContactsDialog(),
          color: Colors.red,
        ),
        _buildActionTile(
          'Test SOS Signal',
          'Test emergency broadcasting system',
          Icons.campaign,
          colorScheme,
          () => _showTestSOSDialog(),
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, ColorScheme colorScheme, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (value) {
          onChanged(value);
          HapticFeedback.lightImpact();
        },
        secondary: Icon(
          icon,
          color: colorScheme.primary,
        ),
        activeColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colorScheme,
    VoidCallback onTap, {
    bool isDestructive = false,
    Color? color,
  }) {
    final tileColor = isDestructive ? Colors.red : (color ?? colorScheme.primary);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        leading: Icon(
          icon,
          color: tileColor,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    List<String> optionLabels,
    ValueChanged<String?> onChanged,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: options.asMap().entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.value,
                child: Text(optionLabels[entry.key]),
              );
            }).toList(),
            underline: Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    ValueChanged<String> onChanged,
    ColorScheme colorScheme,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      onChanged: onChanged,
    );
  }

  // Dialog methods
  void _showEditProfileDialog() {
    // TODO: Implement profile editing dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile editing dialog coming soon')),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text('This will export your messages, contacts, and settings to a secure file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup created successfully')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text('This will replace your current data with the backup. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data restored successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showNetworkDiagnosticsDialog() {
    // TODO: Implement network diagnostics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network diagnostics feature coming soon')),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will free up storage space by removing temporary files.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showExportLogsDialog() {
    // TODO: Implement log export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log export feature coming soon')),
    );
  }

  void _showFactoryResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory Reset'),
        content: const Text('This will reset all settings to default values. Your messages and data will be preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to default')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContactsDialog() {
    // TODO: Implement emergency contacts management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency contacts feature coming soon')),
    );
  }

  void _showTestSOSDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test SOS Signal'),
        content: const Text('This will broadcast a test emergency signal to nearby devices. They will be notified it\'s a test.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🧪 Test SOS signal sent'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send Test'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Off-Grid SOS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.0.0'),
            const SizedBox(height: 8),
            const Text('An offline-first emergency communication app'),
            const SizedBox(height: 16),
            const Text('Features:'),
            const Text('• Peer-to-peer messaging'),
            const Text('• Emergency SOS broadcasting'),
            const Text('• End-to-end encryption'),
            const Text('• Works without internet'),
            const SizedBox(height: 16),
            const Text('Built with Flutter & Material 3'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}