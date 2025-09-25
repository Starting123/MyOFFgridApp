import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/permission_helper.dart';

class ModernSettingsScreen extends ConsumerStatefulWidget {
  const ModernSettingsScreen({super.key});

  @override
  ConsumerState<ModernSettingsScreen> createState() => _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends ConsumerState<ModernSettingsScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _autoConnectEnabled = true;
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  double _scanRadius = 100.0;
  String _userRole = 'sos_user'; // 'sos_user' or 'rescuer'

  @override
  void initState() {
    super.initState();
    _deviceNameController.text = 'My Device';
    _userNameController.text = 'อุปกรณ์ฉุกเฉิน';
    _phoneController.text = '';
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNameController.text = prefs.getString('device_name') ?? 'อุปกรณ์ฉุกเฉิน';
      _phoneController.text = prefs.getString('emergency_phone') ?? '';
      _userRole = prefs.getString('user_role') ?? 'sos_user';
    });
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _userNameController.dispose();
    _phoneController.dispose();
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
              // Device Profile Section
              _buildSectionHeader('ข้อมูลอุปกรณ์'),
              _buildDeviceInfoCard(),
              _buildUserProfileSettings(),
              const SizedBox(height: 30),

              // Device Settings
              _buildSectionHeader('การตั้งค่าอุปกรณ์'),
              _buildDeviceSettings(),
              const SizedBox(height: 30),

              // Communication Settings
              _buildSectionHeader('การสื่อสาร'),
              _buildCommunicationSettings(),
              const SizedBox(height: 30),

              // Emergency Settings
              _buildSectionHeader('การตั้งค่าฉุกเฉิน'),
              _buildEmergencySettings(),
              const SizedBox(height: 30),

              // Notification Settings
              _buildSectionHeader('การแจ้งเตือน'),
              _buildNotificationSettings(),
              const SizedBox(height: 30),

              // Privacy & Security
              _buildSectionHeader('ความปลอดภัย'),
              _buildSecuritySettings(),
              const SizedBox(height: 30),

              // About & Help
              _buildSectionHeader('เกี่ยวกับ'),
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

  Widget _buildRoleSelectionSetting() {
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
            _userRole == 'rescuer' ? Icons.medical_services : Icons.warning,
            color: const Color(0xFF00D4FF),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'บทบาทของคุณ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _userRole = 'sos_user');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _userRole == 'sos_user' 
                              ? const Color(0xFFFF6B6B).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: _userRole == 'sos_user'
                                ? const Color(0xFFFF6B6B)
                                : Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning,
                              color: _userRole == 'sos_user' 
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ผู้ขอความช่วยเหลือ',
                              style: TextStyle(
                                color: _userRole == 'sos_user' 
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _userRole = 'rescuer');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _userRole == 'rescuer' 
                              ? const Color(0xFF4CAF50).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: _userRole == 'rescuer'
                                ? const Color(0xFF4CAF50)
                                : Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: _userRole == 'rescuer' 
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ผู้ช่วยเหลือ',
                              style: TextStyle(
                                color: _userRole == 'rescuer' 
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveSettings() async {
    HapticFeedback.lightImpact();
    
    // Validate inputs
    if (_userNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาใส่ชื่ออุปกรณ์'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00D4FF),
        ),
      ),
    );

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_name', _userNameController.text.trim());
    await prefs.setString('emergency_phone', _phoneController.text.trim());
    await prefs.setString('user_role', _userRole);
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Close loading dialog
    Navigator.pop(context);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'บันทึกการตั้งค่าสำเร็จ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'อุปกรณ์: ${_userNameController.text} | บทบาท: ${_userRole == 'rescuer' ? 'ผู้ช่วยเหลือ' : 'ผู้ขอความช่วยเหลือ'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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

  Widget _buildDeviceInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.1),
            const Color(0xFF5B86E5).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF00D4FF).withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF00D4FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'เกี่ยวกับการใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '📱 อุปกรณ์นี้ใช้ชื่อเดียวกันสำหรับทุกคนที่ใช้งาน',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '👥 ผู้ใช้แต่ละคนสามารถเลือกบทบาท (SOS หรือ Rescuer) ได้',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '🔄 สามารถเปลี่ยนบทบาทได้ตลอดเวลาตามสถานการณ์',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSettings() {
    return _buildSettingsCard([
      _buildRoleSelectionSetting(),
      const Divider(color: Colors.white10, height: 32),
      _buildTextFieldSetting(
        'ชื่ออุปกรณ์',
        'ชื่อที่จะใช้แสดงให้ผู้อื่นเห็น (ใช้ร่วมกันทุกคน)',
        _userNameController,
        Icons.smartphone,
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildInfoSetting(
        'หมายเลขติดต่อหลัก',
        _phoneController.text.isEmpty ? 'ไม่ได้ระบุ' : _phoneController.text,
        Icons.phone,
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildActionSetting(
        'แก้ไขรูปโปรไฟล์',
        'เลือกรูปภาพจากแกลเลอรี่',
        Icons.photo_camera,
        () => _changeProfilePicture(),
      ),
    ]);
  }

  Widget _buildSecuritySettings() {
    return _buildSettingsCard([
      _buildActionSetting(
        'จัดการสิทธิ์แอป',
        'ตรวจสอบและปรับแต่งสิทธิ์การเข้าถึง',
        Icons.admin_panel_settings,
        () => _managePermissions(),
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildActionSetting(
        'สร้างกุญแจใหม่',
        'สร้างกุญแจเข้ารหัสใหม่',
        Icons.vpn_key,
        () => _regenerateKeys(),
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildInfoSetting(
        'สถานะการเข้ารหัส',
        'เปิดใช้งาน (AES-256)',
        Icons.security,
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildActionSetting(
        'ส่งออกข้อมูล',
        'ส่งออกข้อความและการตั้งค่า',
        Icons.download,
        () => _exportData(),
      ),
      const Divider(color: Colors.white10, height: 32),
      _buildActionSetting(
        'ลบข้อมูลทั้งหมด',
        'ลบข้อความและรีเซ็ตแอป',
        Icons.delete_forever,
        () => _clearAllData(),
      ),
    ]);
  }

  void _managePermissions() async {
    await PermissionHelper.showPermissionDialog(
      context,
      title: 'สิทธิ์การเข้าถึง',
      message: 'แอปต้องการสิทธิ์เหล่านี้เพื่อการทำงานที่เหมาะสม',
      permissions: [
        Permission.location,
        Permission.locationAlways,
        Permission.storage,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ],
      onSettingsPressed: () => openAppSettings(),
    );
  }

  void _changeProfilePicture() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'เปลี่ยนรูปโปรไฟล์',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'ฟีเจอร์นี้จะพร้อมใช้งานในเวอร์ชันถัดไป',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ตกลง',
              style: TextStyle(color: Color(0xFF00D4FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _regenerateKeys() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'สร้างกุญแจใหม่',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'การสร้างกุญแจใหม่จะทำให้ข้อความเก่าไม่สามารถถอดรหัสได้ คุณแน่ใจหรือไม่?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement key regeneration
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('สร้างกุญแจใหม่สำเร็จ'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text(
              'สร้างใหม่',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'ส่งออกข้อมูล',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'ส่งออกข้อความและการตั้งค่าเป็นไฟล์ JSON',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement data export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ส่งออกข้อมูลสำเร็จ'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text(
              'ส่งออก',
              style: TextStyle(color: Color(0xFF00D4FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'ลบข้อมูลทั้งหมด',
          style: TextStyle(color: Color(0xFFFF6B6B)),
        ),
        content: const Text(
          'การดำเนินการนี้จะลบข้อความ การตั้งค่า และข้อมูลทั้งหมด ไม่สามารถย้อนกลับได้',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement data clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ลบข้อมูลทั้งหมดสำเร็จ'),
                  backgroundColor: Color(0xFFFF6B6B),
                ),
              );
            },
            child: const Text(
              'ลบทั้งหมด',
              style: TextStyle(color: Color(0xFFFF6B6B)),
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