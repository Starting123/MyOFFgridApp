import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/modern_widgets.dart';

import 'sos_screen_clean.dart';
import 'nearby_devices_screen_clean.dart';
import 'chat_screen_clean.dart';
import 'settings_screen_clean.dart';

class HomeScreenClean extends ConsumerStatefulWidget {
  const HomeScreenClean({super.key});

  @override
  ConsumerState<HomeScreenClean> createState() => _HomeScreenCleanState();
}

class _HomeScreenCleanState extends ConsumerState<HomeScreenClean> {
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Mock data - in real app, this would come from providers
    final bool isOnline = false; // Mock offline status
    final int connectedDevices = 3;
    final int unreadMessages = 2;
    final int nearbySOSDevices = 1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Header
              _buildAppHeader(theme),
              const SizedBox(height: 24),
              
              // Connection Status Banner
              ModernWidgets.connectionStatusBanner(
                isOnline: isOnline,
                connectedDevices: connectedDevices,
              ),
              const SizedBox(height: 32),
              
              // Quick Stats Cards
              _buildQuickStats(
                context,
                nearbyDevices: connectedDevices,
                unreadMessages: unreadMessages,
                sosDevices: nearbySOSDevices,
              ),
              const SizedBox(height: 32),
              
              // Main Action Cards
              Text(
                'Quick Actions',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildActionGrid(context, theme),
              const SizedBox(height: 32),
              
              // Recent Activity Section
              _buildRecentActivity(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.offline_bolt,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Off-Grid SOS',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Emergency Communication Network',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(
    BuildContext context, {
    required int nearbyDevices,
    required int unreadMessages,
    required int sosDevices,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Nearby Devices',
            nearbyDevices.toString(),
            Icons.radar,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Messages',
            unreadMessages.toString(),
            Icons.chat_bubble,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'SOS Alerts',
            sosDevices.toString(),
            Icons.emergency,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        ModernWidgets.statusCard(
          title: 'SOS Mode',
          subtitle: 'Emergency Broadcasting',
          icon: Icons.emergency,
          color: Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SOSScreen()),
          ),
        ),
        ModernWidgets.statusCard(
          title: 'Nearby Devices',
          subtitle: 'Discover & Connect',
          icon: Icons.radar,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NearbyDevicesScreen()),
          ),
        ),
        ModernWidgets.statusCard(
          title: 'Messages',
          subtitle: 'Secure Chat',
          icon: Icons.chat_bubble,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          ),
        ),
        ModernWidgets.statusCard(
          title: 'Settings',
          subtitle: 'Profile & Config',
          icon: Icons.settings,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Mock recent activities
        _buildActivityItem(
          context,
          'Device Connected',
          'John\'s Phone joined the network',
          Icons.phone_android,
          Colors.green,
          '2 min ago',
        ),
        _buildActivityItem(
          context,
          'SOS Alert Received',
          'Emergency signal from Sarah\'s Device',
          Icons.emergency,
          Colors.red,
          '5 min ago',
        ),
        _buildActivityItem(
          context,
          'Message Synced',
          '3 messages synced to cloud',
          Icons.cloud_done,
          Colors.blue,
          '10 min ago',
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
