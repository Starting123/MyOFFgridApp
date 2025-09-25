import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SOSMode { inactive, victim, rescuer }

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> 
    with SingleTickerProviderStateMixin {
  SOSMode currentMode = SOSMode.inactive;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mock location data - replace with actual location service
  String latitude = "37.7749";
  String longitude = "-122.4194";
  String locationName = "San Francisco, CA";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleMode(SOSMode newMode) {
    setState(() {
      if (currentMode == newMode) {
        currentMode = SOSMode.inactive;
        _pulseController.stop();
      } else {
        currentMode = newMode;
        if (newMode != SOSMode.inactive) {
          _pulseController.repeat(reverse: true);
        }
      }
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // TODO: Connect to SOS broadcasting service
    _showModeChangeSnackBar();
  }

  void _showModeChangeSnackBar() {
    String message;
    switch (currentMode) {
      case SOSMode.victim:
        message = '🔴 SOS ACTIVE - Broadcasting distress signal';
        break;
      case SOSMode.rescuer:
        message = '🔵 RESCUER MODE - Listening for emergency calls';
        break;
      case SOSMode.inactive:
        message = '⚪ SOS DEACTIVATED - Normal mode restored';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _getModeColor(),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getModeColor() {
    switch (currentMode) {
      case SOSMode.victim:
        return Colors.red;
      case SOSMode.rescuer:
        return Colors.blue;
      case SOSMode.inactive:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Emergency Mode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Status Header
              _buildStatusHeader(colorScheme),
              
              const SizedBox(height: 40),
              
              // Main SOS Toggle Area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SOS Toggle Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildSOSToggleButton(
                            mode: SOSMode.victim,
                            title: 'VICTIM',
                            subtitle: 'Need Help',
                            icon: Icons.emergency,
                            color: Colors.red,
                            isActive: currentMode == SOSMode.victim,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildSOSToggleButton(
                            mode: SOSMode.rescuer,
                            title: 'RESCUER',
                            subtitle: 'Can Help',
                            icon: Icons.medical_services,
                            color: Colors.blue,
                            isActive: currentMode == SOSMode.rescuer,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Status Text
                    _buildStatusText(colorScheme),
                  ],
                ),
              ),
              
              // Location Information
              _buildLocationCard(colorScheme),
              
              const SizedBox(height: 24),
              
              // Emergency Contacts Quick Actions
              if (currentMode == SOSMode.victim)
                _buildEmergencyActions(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getModeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getModeColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getModeIcon(),
            size: 48,
            color: _getModeColor(),
          ),
          const SizedBox(height: 12),
          Text(
            _getModeTitle(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getModeColor(),
            ),
          ),
          Text(
            _getModeSubtitle(),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSToggleButton({
    required SOSMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _pulseAnimation.value : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleMode(mode),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isActive 
                      ? color.withOpacity(0.15)
                      : color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive 
                        ? color 
                        : color.withOpacity(0.3),
                    width: isActive ? 3 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isActive ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText(ColorScheme colorScheme) {
    String statusText;
    switch (currentMode) {
      case SOSMode.victim:
        statusText = "🔴 Broadcasting SOS signal...\nNearby rescuers will be notified";
        break;
      case SOSMode.rescuer:
        statusText = "🔵 Listening for emergency calls...\nReady to assist those in need";
        break;
      case SOSMode.inactive:
        statusText = "⚪ SOS Mode Inactive\nTap a button above to activate emergency mode";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Text(
        statusText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildLocationCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            locationName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: $latitude, Lng: $longitude',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.7),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyActions(ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'Emergency Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Call 911',
                Icons.phone,
                Colors.red,
                () {
                  // TODO: Implement emergency call
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Initiating emergency call...'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Share Location',
                Icons.share_location,
                Colors.orange,
                () {
                  // TODO: Implement location sharing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing location with emergency contacts...'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  IconData _getModeIcon() {
    switch (currentMode) {
      case SOSMode.victim:
        return Icons.emergency;
      case SOSMode.rescuer:
        return Icons.medical_services;
      case SOSMode.inactive:
        return Icons.shield;
    }
  }

  String _getModeTitle() {
    switch (currentMode) {
      case SOSMode.victim:
        return 'SOS ACTIVE';
      case SOSMode.rescuer:
        return 'RESCUER MODE';
      case SOSMode.inactive:
        return 'STANDBY MODE';
    }
  }

  String _getModeSubtitle() {
    switch (currentMode) {
      case SOSMode.victim:
        return 'Emergency signal broadcasting';
      case SOSMode.rescuer:
        return 'Available to help others';
      case SOSMode.inactive:
        return 'Ready for emergency activation';
    }
  }
}