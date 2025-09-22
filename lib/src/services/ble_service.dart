import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// BLE Service for small payload transfer and device discovery
class BLEService {
  static final BLEService _instance = BLEService._internal();
  static BLEService get instance => _instance;

  BLEService._internal();

  static const String SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String CHARACTERISTIC_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;
  final Set<String> _discoveredDevices = {};

  Future<bool> initialize() async {
    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();
      
      // Check if any permission was denied
      if (statuses.values.any((status) => status.isDenied)) {
        debugPrint('Some permissions were denied');
        return false;
      }

      // Initialize FlutterBluePlus
      FlutterBluePlus.setLogLevel(LogLevel.info);
      return true;
    } catch (e) {
      debugPrint('Error initializing BLE: $e');
      return false;
    }
  }

  Future<void> startScanning() async {
    if (_isScanning) return;
    _isScanning = true;
    _discoveredDevices.clear();

    try {
      // Cancel any existing subscription
      await _scanSubscription?.cancel();
      
      // Start scanning with timeout
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (ScanResult r in results) {
            if (!_discoveredDevices.contains(r.device.id.id)) {
              _discoveredDevices.add(r.device.id.id);
              debugPrint('${r.device.localName} found! rssi: ${r.rssi}');
            }
          }
        },
        onError: (error) {
          debugPrint('Error during scan: $error');
          stopScanning();
        }
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Error scanning: $e');
      _isScanning = false;
      rethrow;
    } finally {
      Future.delayed(const Duration(seconds: 4), () {
        stopScanning();
      });
    }
  }

  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
  }

  Future<void> connect(BluetoothDevice device) async {
    StreamSubscription<BluetoothConnectionState>? stateSubscription;
    
    try {
      // Check if already connected
      if (await device.isConnected) {
        debugPrint('Device already connected');
        return;
      }

      // Create connection state subscription
      final connectionCompleter = Completer<void>();
      
      stateSubscription = device.connectionState.listen(
        (BluetoothConnectionState state) {
          debugPrint('Connection state changed: $state');
          if (state == BluetoothConnectionState.connected) {
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.complete();
            }
          }
        },
        onError: (error) {
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.completeError(error);
          }
        },
        cancelOnError: true,
      );

      // Attempt to connect with retry
      for (int i = 0; i < 3; i++) {
        try {
          await device.connect().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('Connection attempt $i timed out');
              throw TimeoutException('Connection timeout');
            },
          );
          
          // Wait for connection confirmation
          await connectionCompleter.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Connection state confirmation timeout');
            },
          );
          
          debugPrint('Successfully connected to ${device.localName}');
          break;
        } catch (e) {
          await device.disconnect();
          if (i == 2) {
            rethrow; // Last attempt failed
          }
          debugPrint('Connection attempt $i failed: $e. Retrying...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      debugPrint('Connected to ${device.localName}');
        
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
              // Found our characteristic
              debugPrint('Found target characteristic');
              return;
            }
          }
        }
      }
        
      // If we get here, we didn't find our service/characteristic
      throw Exception('Required BLE service/characteristic not found');
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      await disconnect(device); // Clean up on error
      rethrow;
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
      debugPrint('Disconnected from ${device.localName}');
    } catch (e) {
      debugPrint('Error disconnecting: $e');
      rethrow;
    }
  }

  Stream<List<BluetoothDevice>> get connectedDevices {
    return FlutterBluePlus.connectedDevices.asStream();
  }
}