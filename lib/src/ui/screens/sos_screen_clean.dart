import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/modern_widgets.dart';

enum SOSMode { inactive, victim, rescuer }

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen> 
    with SingleTickerProviderStateMixin {
  SOSMode currentMode = SOSMode.inactive;
  late AnimationController _pulseController;
  
  // Mock location data - in real app from location service
  String latitude = "13.7563";
  String longitude = "100.5018";
  String locationName = "Bangkok, Thailand";
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleSOSMode(SOSMode newMode) {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              _buildHeader(theme),
              const SizedBox(height: 40),
              
              // SOS Toggle Buttons
              _buildSOSToggleSection(context, theme),
              const SizedBox(height: 40),
              
              // Location Information
              _buildLocationSection(theme),
              const SizedBox(height: 32),
              
              // Status Information
              _buildStatusSection(theme),
              const SizedBox(height: 32),
              
              // Emergency Instructions
              if (currentMode != SOSMode.inactive)
                _buildEmergencyInstructions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: currentMode == SOSMode.victim 
              ? Colors.red.withOpacity(0.1)
              : currentMode == SOSMode.rescuer
                ? Colors.blue.withOpacity(0.1)
                : theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            currentMode == SOSMode.victim 
              ? Icons.emergency
              : currentMode == SOSMode.rescuer
                ? Icons.local_hospital
                : Icons.offline_bolt,
            size: 32,
            color: currentMode == SOSMode.victim 
              ? Colors.red
              : currentMode == SOSMode.rescuer
                ? Colors.blue
                : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SOS Emergency Mode',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getHeaderSubtitle(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSOSToggleSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Main SOS Toggle Buttons
        Row(
          children: [
            // Victim Mode Button
            Expanded(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = currentMode == SOSMode.victim 
                    ? 1.0 + (_pulseController.value * 0.1)
                    : 1.0;
                  
                  return Transform.scale(
                    scale: scale,
                    child: ModernWidgets.sosToggleButton(
                      isVictim: true,
                      isActive: currentMode == SOSMode.victim,
                      onPressed: () => _toggleSOSMode(SOSMode.victim),
                      size: 160,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            // Rescuer Mode Button
            Expanded(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = currentMode == SOSMode.rescuer 
                    ? 1.0 + (_pulseController.value * 0.1)
                    : 1.0;
                  
                  return Transform.scale(
                    scale: scale,
                    child: ModernWidgets.sosToggleButton(
                      isVictim: false,
                      isActive: currentMode == SOSMode.rescuer,
                      onPressed: () => _toggleSOSMode(SOSMode.rescuer),
                      size: 160,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Mode Descriptions
        Row(
          children: [
            Expanded(
              child: Text(
                'Tap to request\nemergency help',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Tap to offer\nrescue assistance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blue.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Location',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            locationName,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latitude',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      latitude,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Longitude',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      longitude,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusText(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getStatusColor(),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInstructions(ThemeData theme) {
    final instructions = currentMode == SOSMode.victim 
      ? [
          'Stay calm and remain in your current location',
          'Keep your device charged and nearby',
          'Respond to rescue messages when possible',
          'Follow safety protocols until help arrives',
        ]
      : [
          'Scan for nearby emergency signals',
          'Approach victims with caution',
          'Identify yourself as a rescuer',
          'Follow emergency response protocols',
        ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Emergency Instructions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...instructions.map((instruction) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    instruction,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  String _getHeaderSubtitle() {
    switch (currentMode) {
      case SOSMode.victim:
        return 'Broadcasting emergency signal to nearby rescuers';
      case SOSMode.rescuer:
        return 'Listening for emergency signals in your area';
      case SOSMode.inactive:
        return 'Choose your role in emergency situations';
    }
  }

  Color _getStatusColor() {
    switch (currentMode) {
      case SOSMode.victim:
        return Colors.red;
      case SOSMode.rescuer:
        return Colors.blue;
      case SOSMode.inactive:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (currentMode) {
      case SOSMode.victim:
        return Icons.broadcast_on_personal;
      case SOSMode.rescuer:
        return Icons.search;
      case SOSMode.inactive:
        return Icons.power_settings_new;
    }
  }

  String _getStatusText() {
    switch (currentMode) {
      case SOSMode.victim:
        return 'Broadcasting SOS Signal';
      case SOSMode.rescuer:
        return 'Scanning for Emergencies';
      case SOSMode.inactive:
        return 'SOS Mode Inactive';
    }
  }

  String _getStatusDescription() {
    switch (currentMode) {
      case SOSMode.victim:
        return 'Your emergency signal is being broadcast to nearby devices';
      case SOSMode.rescuer:
        return 'Listening for emergency signals from nearby devices';
      case SOSMode.inactive:
        return 'Tap a button above to activate SOS mode';
    }
  }
}