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
    NavItem(
      icon: Icons.devices_other_outlined,
      activeIcon: Icons.devices_other_rounded,
      label: 'Devices',
      color: Color(0xFF9C27B0),
    ),
    NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      color: Color(0xFFFF9800),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.mainGradient,
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: _currentIndex == 1 
          ? null 
          : AppTheme.pulseEffect(
              isActive: true,
              child: ScaleTransition(
                scale: _fabAnimation,
                child: FloatingActionButton(
                  onPressed: () => _onTabTapped(1),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  elevation: 8,
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _navItems[_currentIndex].color,
          unselectedItemColor: Colors.white.withOpacity(0.4),
          selectedFontSize: 12,
          unselectedFontSize: 10,
          items: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _currentIndex == index;
            
            return BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? item.color.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: isSelected ? 26 : 22,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}