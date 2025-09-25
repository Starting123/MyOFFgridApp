import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/permission_helper.dart';
import 'modern_main_navigation.dart';

class FirstTimeSetupScreen extends StatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen> 
    with TickerProviderStateMixin {
  
  int _currentStep = 0;
  String _selectedRole = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildRoleSelectionStep();
      case 2:
        return _buildUserInfoStep();
      case 3:
        return _buildPermissionsStep();
      case 4:
        return _buildCompletionStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          // App Logo and Title
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4FF).withOpacity(0.3),
                  const Color(0xFF5B86E5).withOpacity(0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF00D4FF),
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'ยินดีต้อนรับสู่',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Off-Grid SOS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'แอปพลิเคชันสำหรับการสื่อสารฉุกเฉิน\nโดยไม่ต้องใช้อินเทอร์เน็ต',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
          const Spacer(),
          _buildContinueButton('เริ่มต้นใช้งาน', () => _nextStep()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRoleSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 32),
          const Text(
            'เลือกบทบาทของคุณ',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'กรุณาเลือกบทบาทที่ตรงกับคุณมากที่สุด',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 48),
          // SOS User Option
          _buildRoleOption(
            'sos_user',
            'ผู้ขอความช่วยเหลือ',
            'คุณต้องการใช้แอปเพื่อขอความช่วยเหลือในสถานการณ์ฉุกเฉิน',
            Icons.warning,
            const Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 20),
          // Rescuer Option
          _buildRoleOption(
            'rescuer',
            'ผู้ช่วยเหลือ',
            'คุณพร้อมที่จะให้ความช่วยเหลือผู้อื่นในสถานการณ์ฉุกเฉิน',
            Icons.medical_services,
            const Color(0xFF4CAF50),
          ),
          const Spacer(),
          _buildContinueButton(
            'ถัดไป',
            _selectedRole.isNotEmpty ? () => _nextStep() : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String role, String title, String description, IconData icon, Color color) {
    bool isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.white54,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white70 : Colors.white54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 32),
          const Text(
            'ข้อมูลส่วนตัว',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'กรอกข้อมูลพื้นฐานสำหรับการใช้งาน',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 48),
          _buildInputField(
            'ชื่อของคุณ',
            'ชื่อที่จะแสดงให้ผู้อื่นเห็น',
            _nameController,
            Icons.person,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'หมายเลขโทรศัพท์',
            'หมายเลขติดต่อในกรณีฉุกเฉิน',
            _phoneController,
            Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const Spacer(),
          _buildContinueButton(
            'ถัดไป',
            (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) 
                ? () => _nextStep() 
                : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: const Color(0xFF00D4FF)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4FF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 32),
          const Text(
            'เปิดใช้งานสิทธิ์',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'แอปต้องการสิทธิ์เหล่านี้เพื่อการทำงานที่เหมาะสม',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 48),
          _buildPermissionItem(
            'ตำแหน่งที่อยู่',
            'ค้นหาอุปกรณ์ใกล้เคียงและส่งตำแหน่งใน SOS',
            Icons.location_on,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 20),
          _buildPermissionItem(
            'Bluetooth',
            'เชื่อมต่อกับอุปกรณ์ผ่าน Bluetooth',
            Icons.bluetooth,
            const Color(0xFF2196F3),
          ),
          const SizedBox(height: 20),
          _buildPermissionItem(
            'WiFi',
            'เชื่อมต่อกับอุปกรณ์ผ่าน WiFi Direct',
            Icons.wifi,
            const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 20),
          _buildPermissionItem(
            'พื้นที่จัดเก็บ',
            'บันทึกข้อความและไฟล์',
            Icons.storage,
            const Color(0xFFFF9800),
          ),
          const Spacer(),
          _buildContinueButton('เปิดใช้งานสิทธิ์', () => _requestPermissions()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 24),
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
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.3),
                  const Color(0xFF45A049).withOpacity(0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'พร้อมใช้งานแล้ว!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'คุณได้ตั้งค่าเป็น${_selectedRole == 'rescuer' ? 'ผู้ช่วยเหลือ' : 'ผู้ขอความช่วยเหลือ'}แล้ว',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _selectedRole == 'rescuer' ? Icons.medical_services : Icons.warning,
                      color: _selectedRole == 'rescuer' 
                          ? const Color(0xFF4CAF50) 
                          : const Color(0xFFFF6B6B),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ชื่อ: ${_nameController.text}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Color(0xFF00D4FF), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'โทรศัพท์: ${_phoneController.text}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildContinueButton('เริ่มใช้งาน', () => _completeSetup()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isActive = index <= _currentStep - 1;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isActive ? const Color(0xFF00D4FF) : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildContinueButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null 
              ? const Color(0xFF00D4FF) 
              : Colors.grey.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: onPressed != null ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep++);
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _requestPermissions() async {
    HapticFeedback.lightImpact();
    
    final permissions = [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.bluetoothConnect,
      Permission.storage,
      Permission.nearbyWifiDevices,
    ];

    // Show permission dialog
    await PermissionHelper.showPermissionDialog(
      context,
      title: 'สิทธิ์การเข้าถึง',
      message: 'แอปต้องการสิทธิ์เหล่านี้เพื่อการทำงานที่เหมาะสม',
      permissions: permissions,
    );

    // Move to next step regardless of permissions granted
    _nextStep();
  }

  void _completeSetup() async {
    HapticFeedback.lightImpact();
    
    // Save setup completion to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    await prefs.setString('user_role', _selectedRole);
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_phone', _phoneController.text);
    
    debugPrint('✅ First-time setup completed');
    debugPrint('👤 User Role: $_selectedRole');
    debugPrint('📛 User Name: ${_nameController.text}');
    debugPrint('📞 User Phone: ${_phoneController.text}');
    
    // Navigate to main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ModernMainNavigation(),
      ),
    );
  }
}