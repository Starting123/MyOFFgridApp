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
  // Essential permissions for Nearby Connections (excluding problematic ones)
  final essentialPermissions = [
    Permission.location, // ACCESS_COARSE_LOCATION & ACCESS_FINE_LOCATION
    Permission.locationWhenInUse, // Essential for Nearby Connections
  ];
  
  // Request essential permissions first
  for (final permission in essentialPermissions) {
    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
      if (status.isGranted) {
        debugPrint('✅ ESSENTIAL: ${permission.toString()} granted');
      } else {
        debugPrint('⚠️ ESSENTIAL: ${permission.toString()} not granted: $status');
      }
    } else {
      debugPrint('✅ ESSENTIAL: ${permission.toString()} already granted');
    }
  }
  
  // Handle locationAlways separately (optional, don't block app if denied)
  var backgroundLocationStatus = await Permission.locationAlways.status;
  if (!backgroundLocationStatus.isGranted && backgroundLocationStatus != PermissionStatus.permanentlyDenied) {
    backgroundLocationStatus = await Permission.locationAlways.request();
    if (backgroundLocationStatus.isGranted) {
      debugPrint('✅ BACKGROUND: Permission.locationAlways granted');
    } else {
      debugPrint('⚠️ BACKGROUND: Permission.locationAlways not granted: $backgroundLocationStatus');
      debugPrint('ℹ️ App can still work without background location');
    }
  } else if (backgroundLocationStatus == PermissionStatus.permanentlyDenied) {
    debugPrint('! CRITICAL: Permission.locationAlways not granted: $backgroundLocationStatus');
    debugPrint('ℹ️ Background location permanently denied - SOS may have limited functionality');
  }
  
  // Optional permissions (nice to have but not critical)
  final optionalPermissions = [
    Permission.camera,
    Permission.microphone,
  ];

  // Handle storage permission separately for Android 13+ compatibility
  var storageStatus = await Permission.storage.status;
  if (!storageStatus.isGranted && storageStatus != PermissionStatus.permanentlyDenied) {
    storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      debugPrint('✅ Permission Permission.storage granted');
    } else {
      debugPrint('! Permission Permission.storage not granted: $storageStatus');
      debugPrint('ℹ️ App can work without storage permission using scoped storage');
    }
  } else {
    debugPrint('! Permission Permission.storage not granted: $storageStatus');
  }

  // Add Android-specific Bluetooth permissions
  final bluetoothPermissions = [
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
  ];

  final nearbyPermissions = [Permission.nearbyWifiDevices];

  // Request optional permissions
  final allOptionalPermissions = [...optionalPermissions, ...bluetoothPermissions, ...nearbyPermissions];
  final statuses = await allOptionalPermissions.request();
  
  // Log all permission results
  for (final permission in allOptionalPermissions) {
    final status = statuses[permission];
    if (status == PermissionStatus.granted) {
      debugPrint('✅ Permission ${permission.toString()} granted');
    } else {
      debugPrint('! Permission ${permission.toString()} not granted: $status');
    }
  }
}

/// Initialize core services
Future<void> _initializeServices() async {
  try {
    // Initialize Nearby Service
    final nearbyInitialized = await NearbyService.instance.initialize();
    debugPrint(nearbyInitialized ? '✅ Nearby Service initialized' : '❌ Nearby Service failed');
    
    // Show permission summary
    await _showPermissionSummary();
    
    debugPrint('✅ All services initialized');
    
  } catch (e) {
    debugPrint('❌ Service initialization error: $e');
  }
}

/// Show summary of permission status
Future<void> _showPermissionSummary() async {
  debugPrint('📊 Permission Summary:');
  
  final permissions = {
    'Location (Essential)': Permission.location,
    'Location When In Use': Permission.locationWhenInUse,  
    'Background Location': Permission.locationAlways,
    'Storage': Permission.storage,
    'Camera': Permission.camera,
    'Microphone': Permission.microphone,
    'Bluetooth Connect': Permission.bluetoothConnect,
    'Bluetooth Scan': Permission.bluetoothScan,
    'Bluetooth Advertise': Permission.bluetoothAdvertise,
    'Nearby WiFi Devices': Permission.nearbyWifiDevices,
  };
  
  int granted = 0;
  int total = permissions.length;
  
  for (final entry in permissions.entries) {
    final status = await entry.value.status;
    final icon = status.isGranted ? '✅' : 
                 status == PermissionStatus.permanentlyDenied ? '🚫' : '⚠️';
    debugPrint('$icon ${entry.key}: $status');
    if (status.isGranted) granted++;
  }
  
  debugPrint('📈 Permissions: $granted/$total granted');
  
  if (granted >= 4) { // Essential permissions
    debugPrint('🟢 App Status: Ready - Core features available');
  } else if (granted >= 2) {
    debugPrint('🟡 App Status: Limited - Some features may not work');
  } else {
    debugPrint('🔴 App Status: Degraded - Many features unavailable');
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