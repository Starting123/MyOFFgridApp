import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class DeviceDiscoveryDebugger {
  static Future<void> checkAllPermissions() async {
    debugPrint('🔍 ตรวจสอบ Permissions ทั้งหมด...');
    
    final permissions = [
      Permission.location,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    for (final permission in permissions) {
      try {
        final status = await permission.status;
        final name = permission.toString().split('.').last;
        
        switch (status) {
          case PermissionStatus.granted:
            debugPrint('✅ $name: อนุมัติแล้ว');
            break;
          case PermissionStatus.denied:
            debugPrint('❌ $name: ถูกปฏิเสธ');
            break;
          case PermissionStatus.permanentlyDenied:
            debugPrint('🚫 $name: ถูกปฏิเสธถาวร');
            break;
          case PermissionStatus.restricted:
            debugPrint('⚠️ $name: ถูกจำกัด');
            break;
          case PermissionStatus.limited:
            debugPrint('⚠️ $name: จำกัดบางส่วน');
            break;
          case PermissionStatus.provisional:
            debugPrint('⚠️ $name: ชั่วคราว');
            break;
        }
      } catch (e) {
        debugPrint('❌ ไม่สามารถตรวจสอบ $permission: $e');
      }
    }
  }

  static void checkDeviceCapabilities() {
    debugPrint('📱 ตรวจสอบความสามารถของอุปกรณ์...');
    debugPrint('   Platform: ${Platform.operatingSystem}');
    debugPrint('   Version: ${Platform.operatingSystemVersion}');
    debugPrint('   Is Android: ${Platform.isAndroid}');
    debugPrint('   Is iOS: ${Platform.isIOS}');
  }

  static void logConnectionState({
    required bool isAdvertising,
    required bool isDiscovering,
    required int connectedEndpoints,
    required String mode,
  }) {
    debugPrint('📊 สถานะการเชื่อมต่อ:');
    debugPrint('   Mode: $mode');
    debugPrint('   Advertising: ${isAdvertising ? "🟢 เปิด" : "🔴 ปิด"}');
    debugPrint('   Discovering: ${isDiscovering ? "🟢 เปิด" : "🔴 ปิด"}');
    debugPrint('   Connected Devices: $connectedEndpoints');
  }

  static void logTroubleshootingSteps() {
    debugPrint('🔧 วิธีแก้ปัญหาการเชื่อมต่อ:');
    debugPrint('1. ตรวจสอบ Bluetooth และ WiFi เปิดอยู่');
    debugPrint('2. ตรวจสอบ Location Services เปิดอยู่');
    debugPrint('3. ให้ permissions ทั้งหมดในแอป');
    debugPrint('4. อยู่ในระยะ 100 เมตรจากกัน');
    debugPrint('5. ปิด Mobile Data และ WiFi (ทดสอบ offline)');
    debugPrint('6. Restart แอปทั้งสองเครื่อง');
    debugPrint('7. เครื่องหนึ่งเปิด SOS ก่อน แล้วเครื่องอื่นเปิด Rescuer');
  }

  static void logExpectedBehavior() {
    debugPrint('✅ พฤติกรรมที่คาดหวัง:');
    debugPrint('SOS Mode:');
    debugPrint('  • เห็น "Started advertising" ใน log');
    debugPrint('  • เห็น "Connection initiated" เมื่อ Rescuer เชื่อมต่อ');
    debugPrint('  • เห็น "Connected to endpoint" เมื่อเชื่อมต่อสำเร็จ');
    debugPrint('');
    debugPrint('Rescuer Mode:');
    debugPrint('  • เห็น "Started discovery" ใน log');
    debugPrint('  • เห็น "Endpoint found" เมื่อพบ SOS device');
    debugPrint('  • เห็น "Connected to endpoint" เมื่อเชื่อมต่อสำเร็จ');
  }
}