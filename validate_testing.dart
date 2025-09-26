#!/usr/bin/env dart

// Device Testing Validation Script
// Run this to validate 2-device offline functionality

import 'dart:io';

void main() async {
  print('🧪 Off-Grid SOS - Device Validation Test');
  print('=' * 50);
  
  await validateProjectStructure();
  await validateDependencies();
  await validatePermissions();
  await generateTestInstructions();
  
  print('\n✅ Validation complete! Ready for 2-device testing.');
}

Future<void> validateProjectStructure() async {
  print('\n📁 Validating project structure...');
  
  final requiredFiles = [
    'lib/src/services/nearby_service.dart',
    'lib/src/services/p2p_service.dart', 
    'lib/src/services/sos_broadcast_service.dart',
    'lib/src/services/local_db_service.dart',
    'lib/src/ui/screens/sos/sos_screen.dart',
    'lib/src/ui/screens/nearby/nearby_devices_screen.dart',
    'android/app/src/main/AndroidManifest.xml',
  ];
  
  for (final file in requiredFiles) {
    final exists = await File(file).exists();
    print('${exists ? '✅' : '❌'} $file');
  }
}

Future<void> validateDependencies() async {
  print('\n📦 Validating dependencies...');
  
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final content = await pubspecFile.readAsString();
    
    final requiredDeps = [
      'nearby_connections',
      'flutter_blue_plus', 
      'flutter_riverpod',
      'drift',
      'geolocator',
      'permission_handler',
    ];
    
    for (final dep in requiredDeps) {
      final hasDepency = content.contains(dep);
      print('${hasDepency ? '✅' : '❌'} $dep');
    }
  }
}

Future<void> validatePermissions() async {
  print('\n🔐 Validating Android permissions...');
  
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (await manifestFile.exists()) {
    final content = await manifestFile.readAsString();
    
    final requiredPermissions = [
      'BLUETOOTH',
      'BLUETOOTH_ADMIN',
      'ACCESS_FINE_LOCATION',
      'ACCESS_COARSE_LOCATION',
      'NEARBY_WIFI_DEVICES',
    ];
    
    for (final permission in requiredPermissions) {
      final hasPermission = content.contains(permission);
      print('${hasPermission ? '✅' : '❌'} android.permission.$permission');
    }
  }
}

Future<void> generateTestInstructions() async {
  print('\n📋 Generating test instructions...');
  
  final instructions = '''
# 2-Device Testing Instructions

## Prerequisites:
1. Two Android devices (API 21+)
2. Bluetooth enabled on both devices  
3. Location permissions granted
4. WiFi can be disabled (test offline mode)

## Test Scenario 1: Basic SOS
**Device A (Victim):**
1. Open app
2. Disable WiFi/Mobile data
3. Tap "SOS MODE" (red button)
4. Wait for broadcast signal

**Device B (Rescuer):**
1. Open app  
2. Disable WiFi/Mobile data
3. Enable "RESCUER MODE" (blue switch)
4. Should see Device A in nearby list
5. Tap to connect and chat

## Test Scenario 2: P2P Messaging
**Both Devices:**
1. Connect as above
2. Send text messages
3. Send images/location
4. Verify delivery status indicators

## Expected Results:
✅ Devices discover each other (10-30 seconds)
✅ SOS signals broadcast and received
✅ Chat messages sent/received offline  
✅ Status indicators work (pending/sent/delivered)
✅ Location sharing works
✅ App works without internet connection

## Troubleshooting:
- If discovery fails: Check Bluetooth/Location permissions
- If messaging fails: Try restarting Nearby Connections
- Check debug logs: `flutter logs --verbose`
''';

  await File('TESTING_INSTRUCTIONS.md').writeAsString(instructions);
  print('✅ Generated TESTING_INSTRUCTIONS.md');
}