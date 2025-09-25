import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import all the screens

import 'home_screen.dart';// Import all the new screens

import 'sos_screen.dart';import 'home_screen.dart';

import 'modern_chat_screen.dart';import 'sos_screen.dart';

import 'nearby_devices_screen.dart';import 'modern_chat_screen.dart';

import 'settings_screen.dart';import 'nearby_devices_screen.dart';

import 'settings_screen.dart';

/// Modern main navigation with Material 3 bottom navigation

class ModernMainNavigation extends ConsumerStatefulWidget {/// Main navigation with bottom tab bar for all screens

  const ModernMainNavigation({super.key});class ModernMainNavigation extends ConsumerStatefulWidget {

  const ModernMainNavigation({super.key});

  @override

  ConsumerState<ModernMainNavigation> createState() => _ModernMainNavigationState();  @override

}  ConsumerState<ModernMainNavigation> createState() => _ModernMainNavigationState();

}

class _ModernMainNavigationState extends ConsumerState<ModernMainNavigation> {

  int _currentIndex = 0;class _ModernMainNavigationState extends ConsumerState<ModernMainNavigation> 

  late PageController _pageController;    with TickerProviderStateMixin {

  int _currentIndex = 0;

  // 4-tab navigation as per requirements (Home, SOS, Nearby, Chat)  late PageController _pageController;

  final List<Widget> _screens = const [  late AnimationController _fabAnimationController;

    HomeScreen(),  late Animation<double> _fabScaleAnimation;

    SOSScreen(),

    NearbyDevicesScreen(),  // Screen list with all new modern screens

    ModernChatScreen(chatId: 'general', chatName: 'General Chat'),  final List<Widget> _screens = const [

  ];    HomeScreen(),

    SOSScreen(),

  @override    ModernChatScreen(chatId: 'main-chat', chatName: 'Main Chat'),

  void initState() {    NearbyDevicesScreen(),

    super.initState();    SettingsScreen(),

    _pageController = PageController();  ];

  }

  // Navigation items configuration

  @override  final List<NavigationItem> _navigationItems = [

  void dispose() {    NavigationItem(

    _pageController.dispose();      icon: Icons.home_outlined,

    super.dispose();      activeIcon: Icons.home,

  }      label: 'Home',

      color: Colors.blue,

  void _onTabTapped(int index) {    ),

    setState(() {    NavigationItem(

      _currentIndex = index;      icon: Icons.emergency_outlined,

    });      activeIcon: Icons.emergency,

    _pageController.animateToPage(      label: 'SOS',

      index,      color: Colors.red,

      duration: const Duration(milliseconds: 300),    ),

      curve: Curves.easeInOut,    NavigationItem(

    );      icon: Icons.chat_bubble_outline,

  }      activeIcon: Icons.chat_bubble,

      label: 'Chat',

  @override      color: Colors.green,

  Widget build(BuildContext context) {    ),

    final theme = Theme.of(context);    NavigationItem(

          icon: Icons.devices_outlined,

    return Scaffold(      activeIcon: Icons.devices,

      body: PageView(      label: 'Devices',

        controller: _pageController,      color: Colors.purple,

        onPageChanged: (index) {    ),

          setState(() {    NavigationItem(

            _currentIndex = index;      icon: Icons.settings_outlined,

          });      activeIcon: Icons.settings,

        },      label: 'Settings',

        children: _screens,      color: Colors.orange,

      ),    ),

      bottomNavigationBar: Container(  ];

        decoration: BoxDecoration(    NavItem(

          boxShadow: [      icon: Icons.devices_other_outlined,

            BoxShadow(      activeIcon: Icons.devices_other_rounded,

              color: Colors.black.withOpacity(0.1),      label: 'Devices',

              blurRadius: 10,      color: Color(0xFF9C27B0),

              offset: const Offset(0, -5),    ),

            ),    NavItem(

          ],      icon: Icons.settings_outlined,

        ),      activeIcon: Icons.settings_rounded,

        child: BottomNavigationBar(      label: 'Settings',

          currentIndex: _currentIndex,      color: Color(0xFFFF9800),

          onTap: _onTabTapped,    ),

          type: BottomNavigationBarType.fixed,  ];

          backgroundColor: theme.colorScheme.surface,

          selectedItemColor: theme.colorScheme.primary,  @override

          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),  void initState() {

          selectedLabelStyle: const TextStyle(    super.initState();

            fontWeight: FontWeight.w600,    _pageController = PageController();

            fontSize: 12,    _fabAnimationController = AnimationController(

          ),      duration: const Duration(milliseconds: 300),

          unselectedLabelStyle: const TextStyle(      vsync: this,

            fontWeight: FontWeight.w400,    );

            fontSize: 12,    _fabAnimation = CurvedAnimation(

          ),      parent: _fabAnimationController,

          items: [      curve: Curves.easeInOut,

            BottomNavigationBarItem(    );

              icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),    _fabAnimationController.forward();

              label: 'Home',  }

            ),

            BottomNavigationBarItem(  @override

              icon: Container(  void dispose() {

                padding: const EdgeInsets.all(2),    _pageController.dispose();

                decoration: BoxDecoration(    _fabAnimationController.dispose();

                  color: _currentIndex == 1     super.dispose();

                    ? Colors.red.withOpacity(0.1)   }

                    : Colors.transparent,

                  borderRadius: BorderRadius.circular(8),  void _onTabTapped(int index) {

                ),    HapticFeedback.lightImpact();

                child: Icon(    setState(() {

                  _currentIndex == 1 ? Icons.emergency : Icons.emergency_outlined,      _currentIndex = index;

                  color: _currentIndex == 1 ? Colors.red : null,    });

                ),    _pageController.animateToPage(

              ),      index,

              label: 'SOS',      duration: const Duration(milliseconds: 300),

            ),      curve: Curves.easeInOut,

            BottomNavigationBarItem(    );

              icon: Icon(_currentIndex == 2 ? Icons.radar : Icons.radar_outlined),  }

              label: 'Nearby',

            ),  @override

            BottomNavigationBarItem(  Widget build(BuildContext context) {

              icon: Stack(    return Scaffold(

                children: [      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

                  Icon(_currentIndex == 3 ? Icons.chat : Icons.chat_outlined),      body: Container(

                  // Message count badge could be added here        decoration: BoxDecoration(

                  // Positioned(...) for unread message count          gradient: AppTheme.mainGradient,

                ],        ),

              ),        child: PageView(

              label: 'Chat',          controller: _pageController,

            ),          onPageChanged: (index) {

          ],            setState(() {

        ),              _currentIndex = index;

      ),            });

    );          },

  }          children: _screens,

}        ),
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