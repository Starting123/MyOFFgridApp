import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService {
  static final NearbyService _instance = NearbyService._internal();
  static NearbyService get instance => _instance;

  NearbyService._internal();

  final Nearby _nearby = Nearby();
  final String _serviceId = 'com.offgrid.sos';
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _deviceFoundController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _deviceLostController = 
      StreamController<String>.broadcast();
  
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  final Set<String> _connectedEndpoints = {};

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onDeviceFound => _deviceFoundController.stream;
  Stream<String> get onDeviceLost => _deviceLostController.stream;

  // Initialize and request permissions
  Future<bool> initialize() async {
    try {
      debugPrint('🔄 กำลังขอ permissions สำหรับ Nearby Connections...');
      
      // Request location permission (required for device discovery)
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        debugPrint('❌ Location permission ถูกปฏิเสธ');
        return false;
      }
      debugPrint('✅ Location permission อนุมัติแล้ว');
      
      if (Platform.isAndroid) {
        // Request Bluetooth permissions for Android 12+
        final bluetoothConnect = await Permission.bluetoothConnect.request();
        final bluetoothScan = await Permission.bluetoothScan.request();
        final bluetoothAdvertise = await Permission.bluetoothAdvertise.request();
        
        if (!bluetoothConnect.isGranted || !bluetoothScan.isGranted || !bluetoothAdvertise.isGranted) {
          debugPrint('❌ Bluetooth permissions ถูกปฏิเสธ');
          debugPrint('Connect: ${bluetoothConnect.isGranted}, Scan: ${bluetoothScan.isGranted}, Advertise: ${bluetoothAdvertise.isGranted}');
          return false;
        }
        debugPrint('✅ Bluetooth permissions อนุมัติแล้ว');
        
        // Request nearby WiFi devices permission for Android 13+
        try {
          final nearbyWifiStatus = await Permission.nearbyWifiDevices.request();
          if (nearbyWifiStatus.isGranted) {
            debugPrint('✅ Nearby WiFi devices permission อนุมัติแล้ว');
          } else {
            debugPrint('⚠️ Nearby WiFi devices permission ไม่ได้รับอนุมัติ');
          }
        } catch (e) {
          debugPrint('⚠️ Nearby WiFi devices permission ไม่สามารถขอได้: $e');
        }
      }
      
      debugPrint('✅ Nearby Service initialized สำเร็จ');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing nearby service: $e');
      return false;
    }
  }

  // Start advertising as an SOS device
  Future<void> startAdvertising(String deviceName) async {
    if (_isAdvertising) {
      debugPrint('⚠️ กำลังทำ advertising อยู่แล้ว - หยุดก่อนแล้วเริ่มใหม่');
      await stopAdvertising();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      debugPrint('📡 เริ่ม advertising: $deviceName');
      debugPrint('   Service ID: $_serviceId');
      debugPrint('   Strategy: P2P_CLUSTER');
      
      await _nearby.startAdvertising(
        deviceName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      _isAdvertising = true;
      debugPrint('✅ เริ่ม advertising สำเร็จ: $deviceName');
    } catch (e) {
      if (e.toString().contains('STATUS_ALREADY_ADVERTISING')) {
        debugPrint('ℹ️ Service กำลัง advertising อยู่แล้ว - ใช้งานได้ปกติ');
        _isAdvertising = true;
        return; // ไม่ throw error เพราะการทำงานยังคงปกติ
      } else {
        debugPrint('❌ Error advertising: $e');
        rethrow;
      }
    }
  }

  // Start discovering nearby devices
  Future<void> startDiscovery() async {
    if (_isDiscovering) {
      debugPrint('⚠️ กำลังทำ discovery อยู่แล้ว - หยุดก่อนแล้วเริ่มใหม่');
      await stopDiscovery();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      debugPrint('🔍 เริ่มสแกนหาอุปกรณ์ใกล้เคียง...');
      debugPrint('   Service ID: $_serviceId');
      debugPrint('   Strategy: P2P_CLUSTER');
      
      await _nearby.startDiscovery(
        _serviceId,
        Strategy.P2P_CLUSTER,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: (endpointId) {
          _connectedEndpoints.remove(endpointId);
          debugPrint('🔴 อุปกรณ์หลุดการเชื่อมต่อ: $endpointId');
        } as OnEndpointLost,
        serviceId: _serviceId,
      );
      _isDiscovering = true;
      debugPrint('✅ เริ่มสแกนสำเร็จ');
    } catch (e) {
      if (e.toString().contains('STATUS_ALREADY_DISCOVERING')) {
        debugPrint('ℹ️ Service กำลัง discovering อยู่แล้ว - ใช้งานได้ปกติ');
        _isDiscovering = true;
        return; // ไม่ throw error เพราะการทำงานยังคงปกติ
      } else {
        debugPrint('❌ Error discovering: $e');
        rethrow;
      }
    }
  }

  // Send SOS broadcast to all connected endpoints
  Future<void> broadcastSOS({
    required String deviceId,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    final payload = {
      'type': 'sos',
      'deviceId': deviceId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    final jsonData = jsonEncode(payload);
    final bytes = Uint8List.fromList(utf8.encode(jsonData));

    debugPrint('🆘 กำลังส่ง SOS Signal...');
    debugPrint('   Device ID: $deviceId');
    debugPrint('   Message: $message');
    debugPrint('   Connected Endpoints: ${_connectedEndpoints.length}');

    if (_connectedEndpoints.isEmpty) {
      debugPrint('⚠️ ไม่มีอุปกรณ์เชื่อมต่อ - SOS ไม่สามารถส่งได้');
      return;
    }

    for (final endpointId in _connectedEndpoints) {
      try {
        await _nearby.sendBytesPayload(endpointId, bytes);
        debugPrint('✅ ส่ง SOS ไปยัง $endpointId สำเร็จ');
      } catch (e) {
        debugPrint('❌ Error sending to endpoint $endpointId: $e');
      }
    }
  }

  // Stop advertising
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    try {
      await _nearby.stopAdvertising();
      _isAdvertising = false;
      debugPrint('🔴 หยุด advertising สำเร็จ');
    } catch (e) {
      debugPrint('⚠️ Error stopping advertising: $e');
      _isAdvertising = false; // Reset state anyway
    }
  }

  // Stop discovery
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    try {
      await _nearby.stopDiscovery();
      _isDiscovering = false;
      debugPrint('🔴 หยุด discovery สำเร็จ');
    } catch (e) {
      debugPrint('⚠️ Error stopping discovery: $e');
      _isDiscovering = false; // Reset state anyway
    }
  }

  // Disconnect from all endpoints
  Future<void> disconnect() async {
    for (final endpointId in _connectedEndpoints.toList()) {
      await _nearby.disconnectFromEndpoint(endpointId);
    }
    _connectedEndpoints.clear();
    await stopAdvertising();
    await stopDiscovery();
  }

  // Private callback methods
  void _onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
    debugPrint('🤝 มีการเชื่อมต่อเข้ามา: $endpointId');
    debugPrint('   Device Name: ${connectionInfo.endpointName}');
    debugPrint('   Is Incoming: ${connectionInfo.isIncomingConnection}');
    
    // Auto accept connections
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (String endpointId, PayloadTransferUpdate update) {
        debugPrint('📦 Payload transfer: $endpointId - ${update.status}');
      },
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(endpointId);
      debugPrint('✅ เชื่อมต่อสำเร็จ: $endpointId');
      debugPrint('   Total connections: ${_connectedEndpoints.length}');
    } else {
      debugPrint('❌ การเชื่อมต่อล้มเหลว: $endpointId - $status');
    }
  }

  void _onDisconnected(String endpointId) {
    _connectedEndpoints.remove(endpointId);
    debugPrint('🔴 การเชื่อมต่อขาด: $endpointId');
    debugPrint('   Remaining connections: ${_connectedEndpoints.length}');
    
    // แจ้งไปที่ Provider ว่าอุปกรณ์หลุดการเชื่อมต่อ
    _deviceLostController.add(endpointId);
  }

  void _onEndpointFound(String endpointId, String endpointName, String serviceId) {
    debugPrint('🎯 พบอุปกรณ์: $endpointId');
    debugPrint('   Name: $endpointName');
    debugPrint('   Service: $serviceId');
    
    // แจ้งไปที่ Provider ว่าพบอุปกรณ์
    _deviceFoundController.add({
      'endpointId': endpointId,
      'endpointName': endpointName,
      'serviceId': serviceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // ตรวจสอบว่าเชื่อมต่ออยู่แล้วหรือไม่
    if (_connectedEndpoints.contains(endpointId)) {
      debugPrint('ℹ️ อุปกรณ์ $endpointId เชื่อมต่ออยู่แล้ว');
      return;
    }
    
    // Request connection
    try {
      _nearby.requestConnection(
        'Device ${DateTime.now().millisecondsSinceEpoch}',
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      if (e.toString().contains('STATUS_ALREADY_CONNECTED_TO_ENDPOINT')) {
        debugPrint('ℹ️ อุปกรณ์ $endpointId เชื่อมต่ออยู่แล้ว - ใช้งานได้ปกติ');
        // เพิ่มเข้า connected list ถ้ายังไม่มี
        if (!_connectedEndpoints.contains(endpointId)) {
          _connectedEndpoints.add(endpointId);
        }
      } else {
        debugPrint('❌ Error requesting connection to $endpointId: $e');
      }
    }
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final String str = String.fromCharCodes(payload.bytes!);
      debugPrint('📨 ได้รับข้อความจาก $endpointId');
      debugPrint('   Content: $str');
      
      try {
        final data = jsonDecode(str) as Map<String, dynamic>;
        
        // Check if it's SOS message
        if (data['type'] == 'sos') {
          debugPrint('🆘 ได้รับสัญญาณ SOS!');
          debugPrint('   Device: ${data['deviceName']}');
          debugPrint('   Message: ${data['message']}');
        }
        
        _messageController.add(data);
      } catch (e) {
        debugPrint('❌ Error parsing payload: $e');
      }
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}