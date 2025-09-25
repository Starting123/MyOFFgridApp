import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/main_providers.dart';
import '../../models/chat_models.dart';
import '../theme/app_theme.dart';

class EnhancedSOSScreen extends ConsumerStatefulWidget {
  const EnhancedSOSScreen({super.key});

  @override
  ConsumerState<EnhancedSOSScreen> createState() => _EnhancedSOSScreenState();
}

class _EnhancedSOSScreenState extends ConsumerState<EnhancedSOSScreen> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isEmergencyMode = false;
  String _selectedEmergencyType = 'general';
  final TextEditingController _emergencyMessageController = TextEditingController();
  Position? _currentPosition;

  final List<Map<String, dynamic>> _emergencyTypes = [
    {
      'id': 'medical',
      'title': 'Medical Emergency',
      'icon': Icons.local_hospital,
      'color': const Color(0xFFFF4757),
      'description': 'Medical assistance needed immediately',
    },
    {
      'id': 'accident',
      'title': 'Accident',
      'icon': Icons.warning,
      'color': const Color(0xFFFFA726),
      'description': 'Vehicle or injury accident',
    },
    {
      'id': 'lost',
      'title': 'Lost/Stranded',
      'icon': Icons.location_searching,
      'color': const Color(0xFF29B6F6),
      'description': 'Lost location or stranded',
    },
    {
      'id': 'threat',
      'title': 'Safety Threat',
      'icon': Icons.security,
      'color': const Color(0xFFEF5350),
      'description': 'Personal safety at risk',
    },
    {
      'id': 'fire',
      'title': 'Fire Emergency',
      'icon': Icons.local_fire_department,
      'color': const Color(0xFFFF7043),
      'description': 'Fire or smoke emergency',
    },
    {
      'id': 'general',
      'title': 'General Emergency',
      'icon': Icons.emergency,
      'color': const Color(0xFFFF4757),
      'description': 'Other emergency situation',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _emergencyMessageController.dispose();
    super.dispose();
  }

  void _showEmergencyTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Select Emergency Type',
                style: AppTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Choose the type that best describes your emergency:',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              // Emergency type grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: _emergencyTypes.length,
                itemBuilder: (context, index) {
                  final type = _emergencyTypes[index];
                  final isSelected = _selectedEmergencyType == type['id'];
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedEmergencyType = type['id'];
                        });
                        Navigator.pop(context);
                        _showEmergencyConfirmation();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? type['color'].withOpacity(0.15)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? type['color']
                                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type['icon'],
                                size: 32,
                                color: isSelected 
                                    ? type['color']
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                type['title'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected 
                                      ? type['color']
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyConfirmation() {
    final selectedType = _emergencyTypes.firstWhere(
      (type) => type['id'] == _selectedEmergencyType,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              selectedType['icon'],
              color: selectedType['color'],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedType['title'],
                style: AppTheme.titleMedium.copyWith(
                  color: selectedType['color'],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedType['description'],
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _emergencyMessageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional details (optional)',
                hintText: 'Describe your situation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_currentPosition != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location will be included in SOS',
                        style: AppTheme.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location unavailable',
                        style: AppTheme.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () => _sendEmergencySOS(context, selectedType),
            style: AppTheme.emergencyButtonStyle.copyWith(
              minimumSize: const MaterialStatePropertyAll(Size(120, 48)),
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            child: const Text('🚨 SEND SOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmergencySOS(BuildContext context, Map<String, dynamic> emergencyType) async {
    Navigator.pop(context);
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    setState(() {
      _isEmergencyMode = true;
    });

    try {
      await AppActions.broadcastSOS(
        ref,
        emergencyType: emergencyType['id'],
        emergencyMessage: _emergencyMessageController.text.isNotEmpty 
            ? _emergencyMessageController.text 
            : emergencyType['description'],
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🚨 SOS broadcasted to nearby devices',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('SOS broadcast error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to broadcast SOS: $e',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    _emergencyMessageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosActiveModeProvider);
    final rescuerMode = ref.watch(rescuerActiveModeProvider);
    final nearbyDevices = ref.watch(nearbyDevicesProvider);
    final connectedDevices = nearbyDevices.where((d) => d.isConnected).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Emergency SOS',
          style: AppTheme.titleLarge,
        ),
        backgroundColor: Colors.transparent,
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: connectedDevices > 0
                  ? Theme.of(context).colorScheme.tertiary.withOpacity(0.2)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              border: Border.all(
                color: connectedDevices > 0
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            child: AppTheme.statusIndicator(
              status: connectedDevices > 0 ? 'connected' : 'disconnected',
              label: '$connectedDevices',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: sosState || _isEmergencyMode 
              ? AppTheme.emergencyGradient 
              : rescuerMode 
                  ? AppTheme.rescuerGradient 
                  : AppTheme.mainGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status header
                _buildStatusHeader(sosState, rescuerMode, connectedDevices),
                
                const SizedBox(height: 40),
                
                // Main SOS button
                Expanded(
                  child: Center(
                    child: _buildMainSOSButton(sosState),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Action buttons
                _buildActionButtons(sosState, rescuerMode),
                
                const SizedBox(height: 24),
                
                // Quick info
                _buildQuickInfo(sosState, rescuerMode, nearbyDevices),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool sosState, bool rescuerMode, int connectedDevices) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (sosState) {
      statusText = '🚨 SOS ACTIVE - Broadcasting emergency signal';
      statusColor = Theme.of(context).colorScheme.error;
      statusIcon = Icons.emergency;
    } else if (rescuerMode) {
      statusText = '🔵 RESCUER MODE - Monitoring for SOS signals';
      statusColor = Theme.of(context).colorScheme.tertiary;
      statusIcon = Icons.shield;
    } else {
      statusText = '⚡ READY - Tap button below for emergency';
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.health_and_safety;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: AppTheme.titleMedium.copyWith(color: statusColor),
            textAlign: TextAlign.center,
          ),
          if (connectedDevices > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Connected to $connectedDevices device${connectedDevices > 1 ? 's' : ''}',
              style: AppTheme.bodyMedium.copyWith(color: statusColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainSOSButton(bool sosState) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: sosState ? null : _showEmergencyTypeSelector,
      child: ScaleTransition(
        scale: sosState ? _pulseAnimation : _scaleAnimation,
        child: AppTheme.pulseEffect(
          isActive: sosState || _isEmergencyMode,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.error,
                  Theme.of(context).colorScheme.error.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: sosState ? null : _showEmergencyTypeSelector,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sosState ? Icons.stop : Icons.emergency,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sosState ? 'ACTIVE' : 'SOS',
                        style: AppTheme.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!sosState) ...[
                        const SizedBox(height: 4),
                        Text(
                          'TAP FOR HELP',
                          style: AppTheme.labelMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool sosState, bool rescuerMode) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: sosState 
                ? () => AppActions.deactivateSOS(ref)
                : rescuerMode 
                    ? () => AppActions.deactivateRescuer(ref)
                    : () => AppActions.activateRescuer(ref),
            icon: Icon(
              rescuerMode ? Icons.shield_outlined : Icons.shield,
              size: 20,
            ),
            label: Text(
              rescuerMode ? 'Stop Rescuer' : 'Rescuer Mode',
              style: AppTheme.labelLarge,
            ),
            style: rescuerMode 
                ? AppTheme.rescuerButtonStyle
                : ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to devices screen
              Navigator.of(context).pushNamed('/devices');
            },
            icon: const Icon(Icons.devices, size: 20),
            label: Text(
              'View Devices',
              style: AppTheme.labelLarge,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfo(bool sosState, bool rescuerMode, List<NearbyDevice> nearbyDevices) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Status',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                'Nearby',
                '${nearbyDevices.length}',
                Icons.radar,
                Theme.of(context).colorScheme.primary,
              ),
              _buildInfoItem(
                'SOS Active',
                '${nearbyDevices.where((d) => d.isSOSActive).length}',
                Icons.emergency,
                Theme.of(context).colorScheme.error,
              ),
              _buildInfoItem(
                'Rescuers',
                '${nearbyDevices.where((d) => d.isRescuerActive).length}',
                Icons.shield,
                Theme.of(context).colorScheme.tertiary,
              ),
              _buildInfoItem(
                'Location',
                _currentPosition != null ? 'Yes' : 'No',
                Icons.location_on,
                _currentPosition != null 
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTheme.labelMedium,
        ),
      ],
    );
  }
}