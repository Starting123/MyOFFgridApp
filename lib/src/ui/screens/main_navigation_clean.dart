import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import all the clean screens
import 'home_screen_clean.dart';
import 'sos_screen_clean.dart';
import 'chat_screen_clean.dart';
import 'nearby_devices_screen_clean.dart';

/// Modern main navigation with Material 3 bottom navigation
class ModernMainNavigation extends ConsumerStatefulWidget {
  const ModernMainNavigation({super.key});

  @override
  ConsumerState<ModernMainNavigation> createState() => _ModernMainNavigationState();
}

class _ModernMainNavigationState extends ConsumerState<ModernMainNavigation> {
  int _currentIndex = 0;
  late PageController _pageController;

  // 4-tab navigation as per requirements (Home, SOS, Nearby, Chat)
  final List<Widget> _screens = [
    const HomeScreenClean(),
    const SOSScreen(),
    const NearbyDevicesScreen(),
    const ChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
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
    final theme = Theme.of(context);
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 
                    ? Colors.red.withOpacity(0.1) 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentIndex == 1 ? Icons.emergency : Icons.emergency_outlined,
                  color: _currentIndex == 1 ? Colors.red : null,
                ),
              ),
              label: 'SOS',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2 ? Icons.radar : Icons.radar_outlined),
              label: 'Nearby',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(_currentIndex == 3 ? Icons.chat : Icons.chat_outlined),
                  // Message count badge could be added here
                ],
              ),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}