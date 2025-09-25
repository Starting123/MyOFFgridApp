import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'src/ui/screens/modern_main_navigation.dart';
import 'src/services/nearby_service.dart';
import 'src/utils/background_service_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request critical permissions
  await _requestPermissions();
  
  // Initialize services
  await _initializeServices();
  
  // Start background service if needed
  await BackgroundServiceManager.instance.startServiceIfNeeded();
  
  runApp(const ProviderScope(child: CompleteOffGridSOSApp()));
}

/// Request all necessary permissions for the app
Future<void> _requestPermissions() async {
  // Critical permissions for Nearby Connections
  final criticalPermissions = [
    Permission.location, // This covers ACCESS_COARSE_LOCATION
    Permission.locationWhenInUse,
    Permission.locationAlways,
  ];
  
  // Request critical permissions first and ensure they're granted
  for (final permission in criticalPermissions) {
    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
      if (!status.isGranted) {
        debugPrint('⚠️ CRITICAL: ${permission.toString()} not granted: $status');
        // Show dialog to user explaining importance
      } else {
        debugPrint('✅ CRITICAL: ${permission.toString()} granted');
      }
    }
  }
  
  // Other permissions
  final permissions = [
    Permission.storage,
    Permission.camera,
    Permission.microphone,
  ];

  // Add Android-specific permissions
  if (await Permission.bluetoothConnect.status != PermissionStatus.granted) {
    permissions.addAll([
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
    ]);
  }

  if (await Permission.nearbyWifiDevices.status != PermissionStatus.granted) {
    permissions.add(Permission.nearbyWifiDevices);
  }

  // Request all permissions
  final statuses = await permissions.request();
  
  // Double-check location permissions specifically for Nearby Connections
  if (await Permission.location.status != PermissionStatus.granted) {
    debugPrint('🔥 CRITICAL: Location permission still not granted, requesting again...');
    await Permission.location.request();
    await Permission.locationWhenInUse.request();
  }
  
  // Log permission results
  for (final permission in permissions) {
    final status = statuses[permission];
    if (status != PermissionStatus.granted) {
      debugPrint('⚠️ Permission ${permission.toString()} not granted: $status');
    } else {
      debugPrint('✅ Permission ${permission.toString()} granted');
    }
  }
}

/// Initialize core services
Future<void> _initializeServices() async {
  try {
    // Initialize Nearby Service
    final nearbyInitialized = await NearbyService.instance.initialize();
    debugPrint(nearbyInitialized ? '✅ Nearby Service initialized' : '❌ Nearby Service failed');
    
    debugPrint('✅ All services initialized');
    
  } catch (e) {
    debugPrint('❌ Service initialization error: $e');
  }
}

class CompleteOffGridSOSApp extends StatelessWidget {
  const CompleteOffGridSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MaterialApp(
        title: 'Off-Grid SOS & Nearby Share',
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
            elevation: 2,
          ),
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
            elevation: 2,
          ),
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: const ModernMainNavigation(),
      ),
    );
  }
}