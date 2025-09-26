import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/sos/sos_screen.dart';
import 'screens/nearby/nearby_devices_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/common/bottom_navigation.dart';
import 'theme/app_theme.dart';
import 'widgets/app_widgets.dart';

// Main App with Material 3 Theme
class OffGridApp extends ConsumerWidget {
  const OffGridApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Off-Grid SOS & Nearby Share',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/auth-check',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/auth-check':
            return MaterialPageRoute(builder: (context) => const AuthCheckScreen());
          case '/register':
            return MaterialPageRoute(builder: (context) => const RegisterScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/main':
            return MaterialPageRoute(builder: (context) => const MainNavigationScreen());
          case '/chat':
            return MaterialPageRoute(builder: (context) => const ChatListScreen());
          case '/chat-detail':
            final user = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ChatDetailScreen(user: user),
            );
          default:
            return MaterialPageRoute(builder: (context) => const AuthCheckScreen());
        }
      },
    );
  }


}

// Auth Check Screen - determines which screen to show on app start
class AuthCheckScreen extends ConsumerWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Check if user is logged in
    // For now, always show register screen on first launch
    return FutureBuilder<bool>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: AppLoadingIndicator(
                message: 'Checking authentication...',
                showMessage: true,
                size: 48,
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          // User is logged in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/main');
          });
        } else {
          // User needs to register/login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/register');
          });
        }

        return const Scaffold(
          body: Center(
            child: AppLoadingIndicator(
              message: 'Loading...',
              showMessage: true,
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkAuthStatus() async {
    // TODO: Implement auth check with auth_service
    await Future.delayed(const Duration(seconds: 1));
    return false; // Always show register for now
  }
}

// Main Navigation Screen with Bottom Navigation
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SOSScreen(),
    const ChatListScreen(),
    const NearbyDevicesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}