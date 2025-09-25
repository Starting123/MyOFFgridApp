import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import all the new screens
import 'home_screen.dart';
import 'sos_screen.dart';
import 'modern_chat_screen.dart';
import 'nearby_devices_screen.dart';
import 'settings_screen.dart';

/// Main navigation with bottom tab bar for all screens
class ModernMainNavigation extends ConsumerStatefulWidget {
  const ModernMainNavigation({super.key});

  @override
  ConsumerState<ModernMainNavigation> createState() => _ModernMainNavigationState();
}

class _ModernMainNavigationState extends ConsumerState<ModernMainNavigation> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  // Screen list with all new modern screens
  final List<Widget> _screens = const [
    HomeScreen(),
    SOSScreen(),
    ModernChatScreen(chatId: 'main-chat', chatName: 'Main Chat'),
    NearbyDevicesScreen(),
    SettingsScreen(),
  ];

  // Navigation items configuration
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      color: Colors.blue,
    ),
    NavigationItem(
      icon: Icons.emergency_outlined,
      activeIcon: Icons.emergency,
      label: 'SOS',
      color: Colors.red,
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
      color: Colors.green,
    ),
    NavigationItem(
      icon: Icons.devices_outlined,
      activeIcon: Icons.devices,
      label: 'Devices',
      color: Colors.purple,
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Animate FAB for SOS screen
    if (index == 1) { // SOS Screen
      _fabAnimationController.forward();
    } else if (_currentIndex == 1) {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          HapticFeedback.lightImpact();
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(colorScheme),
      floatingActionButton: _currentIndex == 1 ? _buildSOSFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBottomNavigationBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = index == _currentIndex;
              
              return _buildNavigationItem(
                item: item,
                isActive: isActive,
                onTap: () => _onTabTapped(index),
                colorScheme: colorScheme,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required NavigationItem item,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    final color = isActive ? item.color : colorScheme.onSurface.withOpacity(0.6);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? item.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: isActive ? 12 : 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSFab() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Quick SOS activation
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🆘 Quick SOS activated!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.emergency),
        label: const Text(
          'Quick SOS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Navigation item configuration class
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}