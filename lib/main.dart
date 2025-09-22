import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: OffGridSOSApp()));
}

class OffGridSOSApp extends StatelessWidget {
  const OffGridSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Off-Grid SOS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
      routes: {
        '/login': (context) => const Scaffold(body: Center(child: Text('Login (TODO)'))),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const Scaffold(body: Center(child: Text('Chat (TODO)'))),
        '/sos': (context) => const Scaffold(body: Center(child: Text('SOS (TODO)'))),
      },
    );
  }
}
// Entry point is above (OffGridSOSApp)
