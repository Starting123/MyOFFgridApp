import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE Service for small payload transfer and device discovery
/// Note: BLE has limited throughput. Use this for:
/// - Device discovery
/// - Small message exchange (< 512 bytes)
/// - Initial connection establishment
/// For larger payloads, use this to exchange connection info then switch to WiFi Direct/Nearby
class BLEService {
  static final BLEService _instance = BLEService._internal();
  static BLEService get instance => _instance;

  BLEService._internal();

  static const String SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String CHARACTERISTIC_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  
  bool _isAdvertising = false;
  bool _isScanning = false;
  
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is available and turned on
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('Bluetooth not supported');
        return false;
      }

      await FlutterBluePlus.turnOn();
      return true;
    } catch (e) {
      debugPrint('Error initializing BLE: $e');
      return false;
    }
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    try {
      // Note: Custom advertisement data setup would require platform-specific code
      // This is a simplified version
      _isAdvertising = true;
      debugPrint('Started advertising BLE');
    } catch (e) {
      debugPrint('Error advertising BLE: $e');
      rethrow;
    }
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      
      // Start scanning with filters
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (_isSOSDevice(r.device)) {
            _handleDiscoveredDevice(r);
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      debugPrint('Error scanning BLE: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  Future<void> sendSmallMessage(BluetoothDevice device, Map<String, dynamic> message) async {
    try {
      await device.connect();
      
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString() == SERVICE_UUID,
      );
      
      final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == CHARACTERISTIC_UUID,
      );

      final data = utf8.encode(json.encode(message));
      if (data.length > 512) {
        throw Exception('Message too large for BLE transfer');
      }

      await characteristic.write(data);
      await device.disconnect();
    } catch (e) {
      debugPrint('Error sending BLE message: $e');
      rethrow;
    }
  }

  bool _isSOSDevice(BluetoothDevice device) {
    // Check if the device name or service indicates it's an SOS device
    return device.name.startsWith('SOS_') || 
           device.name.contains('Emergency');
  }

  void _handleDiscoveredDevice(ScanResult result) {
    _messageController.add({
      'type': 'device_found',
      'id': result.device.id.id,
      'name': result.device.name,
      'rssi': result.rssi,
    });
  }

  void dispose() {
    stopScan();
    _messageController.close();
  }
}

// Extension for permission handling
extension BluetoothPermissions on BLEService {
  Future<bool> requestPermissions() async {
    try {
      // Request location permission (required for BLE scanning)
      final locationGranted = await FlutterBluePlus.isLocationGranted;
      if (!locationGranted) {
        debugPrint('Location permission denied');
        return false;
      }

      // Check and request Bluetooth permissions
      if (!await FlutterBluePlus.isOn) {
        await FlutterBluePlus.turnOn();
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }
}