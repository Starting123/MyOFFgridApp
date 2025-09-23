import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/screens/home_screen.dart';
import 'src/ui/screens/chat_screen.dart';
import 'src/ui/screens/sos_screen.dart';
import 'src/utils/background_service_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start background service if needed
  await BackgroundServiceManager.instance.startServiceIfNeeded();
  runApp(const ProviderScope(child: OffGridSOSApp()));
}

class OffGridSOSApp extends StatelessWidget {
  const OffGridSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MaterialApp(
        title: 'Off-Grid SOS',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.red,
            error: Colors.red,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.red,
            error: Colors.red,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/home': (context) => const HomeScreen(),
          '/chat': (context) => const ChatScreen(),
          '/sos': (context) => const SOSScreen(),
        },
      ),
    );
  }
}
