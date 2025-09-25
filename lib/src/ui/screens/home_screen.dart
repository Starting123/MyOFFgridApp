import 'package:flutter/material.dart';
import 'modern_chat_screen.dart';
import 'nearby_devices_screen.dart';
import 'sos_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOnline = false; // This will be connected to your connectivity provider
  int nearbyDevices = 3; // This will come from your device discovery service
  int unreadMessages = 2; // This will come from your message provider

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Title
                    Text(
                      'Off-Grid SOS',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emergency Communication Network',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Connection Status Card
                    _buildConnectionStatusCard(colorScheme),
                  ],
                ),
              ),
            ),
            
            // Quick Stats
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Nearby Devices',
                        nearbyDevices.toString(),
                        Icons.devices,
                        colorScheme.primary,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Messages',
                        unreadMessages.toString(),
                        Icons.message,
                        colorScheme.secondary,
                        colorScheme,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            // Main Actions Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _buildActionCard(
                    'SOS Mode',
                    'Emergency Broadcasting',
                    Icons.emergency,
                    Colors.red,
                    () => _navigateToSOS(context),
                    colorScheme,
                  ),
                  _buildActionCard(
                    'Nearby Devices',
                    'Discover & Connect',
                    Icons.radar,
                    Colors.blue,
                    () => _navigateToDevices(context),
                    colorScheme,
                  ),
                  _buildActionCard(
                    'Messages',
                    'Secure Chat',
                    Icons.chat_bubble,
                    Colors.green,
                    () => _navigateToChat(context),
                    colorScheme,
                  ),
                  _buildActionCard(
                    'Settings',
                    'Profile & Config',
                    Icons.settings,
                    Colors.orange,
                    () => _navigateToSettings(context),
                    colorScheme,
                  ),
                ]),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOnline 
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline 
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOnline ? colorScheme.primary : colorScheme.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: isOnline ? colorScheme.onPrimary : colorScheme.onError,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Connected' : 'Offline Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? colorScheme.primary : colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline 
                      ? 'Cloud sync active • All features available'
                      : 'Device-to-device only • Emergency ready',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: (value) {
              setState(() {
                isOnline = value;
              });
              // TODO: Connect to connectivity service
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSOS(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SOSScreen()),
    );
  }

  void _navigateToDevices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NearbyDevicesScreen()),
    );
  }

  void _navigateToChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModernChatScreen(
          chatId: 'general',
          chatName: 'General Chat',
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}