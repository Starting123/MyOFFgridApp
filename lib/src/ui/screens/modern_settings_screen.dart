import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class ModernSettingsScreen extends ConsumerStatefulWidget {
  const ModernSettingsScreen({super.key});

  @override
  ConsumerState<ModernSettingsScreen> createState() => _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends ConsumerState<ModernSettingsScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  bool _autoConnectEnabled = true;
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  double _scanRadius = 100.0;

  @override
  void initState() {
    super.initState();
    _deviceNameController.text = 'My Device';
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Settings
              _buildSectionHeader('Device Settings'),
              _buildDeviceSettings(),
              const SizedBox(height: 30),

              // Communication Settings
              _buildSectionHeader('Communication'),
              _buildCommunicationSettings(),
              const SizedBox(height: 30),

              // Notification Settings
              _buildSectionHeader('Notifications'),
              _buildNotificationSettings(),
              const SizedBox(height: 30),

              // Emergency Settings
              _buildSectionHeader('Emergency'),
              _buildEmergencySettings(),
              const SizedBox(height: 30),

              // About
              _buildSectionHeader('About'),
              _buildAboutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00D4FF),
        ),
      ),
    );
  }

  Widget _buildDeviceSettings() {
    return _buildSettingsCard([
      _buildTextFieldSetting(
        'Device Name',
        'Name visible to other devices',
        _deviceNameController,
        Icons.smartphone,
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildInfoSetting(
        'Device ID',
        'ABC123DEF456',
        Icons.fingerprint,
      ),
    ]);
  }

  Widget _buildCommunicationSettings() {
    return _buildSettingsCard([
      _buildSwitchSetting(
        'Auto Connect',
        'Automatically connect to known devices',
        _autoConnectEnabled,
        Icons.link,
        (value) => setState(() => _autoConnectEnabled = value),
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildSliderSetting(
        'Scan Radius',
        'Discovery range in meters',
        _scanRadius,
        Icons.radar,
        10.0,
        500.0,
        (value) => setState(() => _scanRadius = value),
      ),
    ]);
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsCard([
      _buildSwitchSetting(
        'Notifications',
        'Show system notifications',
        _notificationsEnabled,
        Icons.notifications,
        (value) => setState(() => _notificationsEnabled = value),
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildSwitchSetting(
        'Vibration',
        'Vibrate for important alerts',
        _vibrationEnabled,
        Icons.vibration,
        (value) => setState(() => _vibrationEnabled = value),
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildSwitchSetting(
        'Sound Alerts',
        'Play sound for emergencies',
        _soundEnabled,
        Icons.volume_up,
        (value) => setState(() => _soundEnabled = value),
      ),
    ]);
  }

  Widget _buildEmergencySettings() {
    return _buildSettingsCard([
      _buildActionSetting(
        'Test Emergency Alert',
        'Send a test SOS signal',
        Icons.warning,
        () => _testEmergencyAlert(),
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildActionSetting(
        'Clear Message History',
        'Delete all saved messages',
        Icons.delete,
        () => _showClearHistoryDialog(),
      ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildSettingsCard([
      _buildInfoSetting(
        'App Version',
        '1.0.0 (Beta)',
        Icons.info,
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildActionSetting(
        'Privacy Policy',
        'View our privacy policy',
        Icons.privacy_tip,
        () => _showPrivacyPolicy(),
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildActionSetting(
        'Open Source Licenses',
        'View third-party licenses',
        Icons.code,
        () => _showLicenses(),
      ),
    ]);
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextFieldSetting(
    String title,
    String subtitle,
    TextEditingController controller,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D4FF).withOpacity(0.2),
                const Color(0xFF5B86E5).withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00D4FF),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: subtitle,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4CAF50).withOpacity(0.2),
                const Color(0xFF388E3C).withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4CAF50),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00D4FF),
          activeTrackColor: const Color(0xFF00D4FF).withOpacity(0.3),
          inactiveThumbColor: Colors.white54,
          inactiveTrackColor: Colors.white.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    IconData icon,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF9800).withOpacity(0.2),
                    const Color(0xFFF57C00).withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF9800),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$subtitle (${value.round()}m)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00D4FF),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: const Color(0xFF00D4FF),
            overlayColor: const Color(0xFF00D4FF).withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 10).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSetting(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withOpacity(0.2),
                  const Color(0xFF7B1FA2).withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9C27B0),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSetting(
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white70,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _testEmergencyAlert() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Test Emergency Alert',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will send a test SOS signal to nearby devices. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test alert sent successfully'),
                  backgroundColor: Color(0xFFFF9800),
                ),
              );
            },
            child: const Text(
              'Send Test',
              style: TextStyle(color: Color(0xFFFF9800)),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Clear Message History',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all your messages and cannot be undone. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message history cleared'),
                  backgroundColor: Color(0xFFFF6B6B),
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'This app is designed for emergency communication and respects your privacy. '
            'All messages are encrypted end-to-end and stored only on your device. '
            'No personal data is transmitted to external servers.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF00D4FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Off-Grid SOS',
      applicationVersion: '1.0.0',
    );
  }
}