import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;
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
  String? _currentDeviceName;

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onDeviceFound => _deviceFoundController.stream;
  Stream<String> get onDeviceLost => _deviceLostController.stream;
  List<String> get connectedEndpoints => List.unmodifiable(_connectedEndpoints);
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  // Enhanced initialization with better permission handling
  Future<bool> initialize() async {
    try {
      debugPrint('🔄 กำลังขอ permissions สำหรับ Nearby Connections...');
      
      // CRITICAL: Request location permissions first (required for Nearby Connections)
      await _requestLocationPermissions();
      
      // Request Bluetooth permissions (Android 12+)
      if (Platform.isAndroid) {
        await _requestBluetoothPermissions();
        await _requestNearbyWifiPermissions();
      }
      
      debugPrint('✅ Nearby Service initialized สำเร็จ');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing nearby service: $e');
      return false;
    }
  }

  // Enhanced location permission request
  Future<void> _requestLocationPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
    ];

    for (final permission in permissions) {
      try {
        final status = await permission.request();
        if (status.isGranted) {
          debugPrint('✅ ${permission.toString()} อนุมัติแล้ว');
        } else if (status.isPermanentlyDenied) {
          debugPrint('❌ ${permission.toString()} ถูกปฏิเสธถาวร - ต้องเปิดใน Settings');
        } else {
          debugPrint('⚠️ ${permission.toString()} ถูกปฏิเสธ: $status');
        }
      } catch (e) {
        debugPrint('⚠️ ไม่สามารถขอ ${permission.toString()}: $e');
      }
    }

    // Check if we have at least basic location permission
    final hasLocation = await Permission.location.isGranted || 
                       await Permission.locationWhenInUse.isGranted;
    
    if (!hasLocation) {
      debugPrint('❌ ไม่มี location permissions - Nearby Connections จะไม่ทำงาน');
      throw Exception('Location permission required for P2P discovery');
    }
  }

  // Enhanced Bluetooth permission request
  Future<void> _requestBluetoothPermissions() async {
    final bluetoothPermissions = [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
    ];

    bool allBluetoothGranted = true;
    for (final permission in bluetoothPermissions) {
      try {
        final status = await permission.request();
        if (status.isGranted) {
          debugPrint('✅ ${permission.toString()} อนุมัติแล้ว');
        } else {
          debugPrint('❌ ${permission.toString()} ถูกปฏิเสธ: $status');
          allBluetoothGranted = false;
        }
      } catch (e) {
        debugPrint('⚠️ ไม่สามารถขอ ${permission.toString()}: $e');
        allBluetoothGranted = false;
      }
    }

    if (allBluetoothGranted) {
      debugPrint('✅ Bluetooth permissions อนุมัติแล้ว');
    } else {
      debugPrint('⚠️ Bluetooth permissions ไม่ครบถ้วน - อาจใช้ WiFi Direct แทน');
    }
  }

  // Enhanced nearby WiFi permission request
  Future<void> _requestNearbyWifiPermissions() async {
    try {
      final nearbyWifiStatus = await Permission.nearbyWifiDevices.request();
      if (nearbyWifiStatus.isGranted) {
        debugPrint('✅ Nearby WiFi devices permission อนุมัติแล้ว');
      } else {
        debugPrint('⚠️ Nearby WiFi devices permission ไม่ได้รับอนุมัติ: $nearbyWifiStatus');
      }
    } catch (e) {
      debugPrint('⚠️ Nearby WiFi devices permission ไม่สามารถขอได้: $e');
    }
  }

  // Enhanced advertising with better error handling
  Future<bool> startAdvertising(String deviceName) async {
    if (_isAdvertising && _currentDeviceName == deviceName) {
      debugPrint('ℹ️ กำลัง advertising อยู่แล้วด้วยชื่อ: $deviceName');
      return true;
    }

    // Stop current advertising if different name
    if (_isAdvertising) {
      await stopAdvertising();
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    try {
      debugPrint('📡 เริ่ม advertising: $deviceName');
      debugPrint('   Service ID: $_serviceId');
      debugPrint('   Strategy: P2P_CLUSTER');
      
      await _nearby.startAdvertising(
        deviceName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (String endpointId, ConnectionInfo connectionInfo) {
          debugPrint('🔗 Connection initiated from: ${connectionInfo.endpointName}');
          _onConnectionInitiated(endpointId, connectionInfo);
        },
        onConnectionResult: (String endpointId, Status status) {
          debugPrint('📶 Connection result: $endpointId - ${status.toString()}');
          _onConnectionResult(endpointId, status);
        },
        onDisconnected: (String endpointId) {
          debugPrint('💔 Disconnected from: $endpointId');
          _onDisconnected(endpointId);
        },
        serviceId: _serviceId,
      );
      
      _isAdvertising = true;
      _currentDeviceName = deviceName;
      debugPrint('✅ Advertising เริ่มสำเร็จ: $deviceName');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error starting advertising: $e');
      if (e.toString().contains('STATUS_ALREADY_ADVERTISING')) {
        debugPrint('ℹ️ Service กำลัง advertising อยู่แล้ว - ใช้งานได้ปกติ');
        _isAdvertising = true;
        _currentDeviceName = deviceName;
        return true;
      }
      return false;
    }
  }

  // Enhanced discovery with better permission checks
  Future<bool> startDiscovery() async {
    if (_isDiscovering) {
      debugPrint('ℹ️ กำลัง discovering อยู่แล้ว');
      return true;
    }

    try {
      // Double-check permissions before discovery
      final hasLocationPermission = await _checkLocationPermissions();
      if (!hasLocationPermission) {
        debugPrint('❌ ไม่มี location permissions สำหรับ discovery');
        return false;
      }

      debugPrint('🔍 ตรวจสอบ location permissions สำหรับ discovery...');
      debugPrint('🔵 BLE discovery would start here');
      
      // Check permissions one more time
      final locationStatus = await Permission.location.status;
      final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
      
      debugPrint('Location: $locationStatus, LocationWhenInUse: $locationWhenInUseStatus');
      
      if (!locationStatus.isGranted && !locationWhenInUseStatus.isGranted) {
        debugPrint('❌ Location permissions required for discovery');
        return false;
      }
      
      debugPrint('✅ All location permissions confirmed');
      debugPrint('🔍 เริ่มสแกนหาอุปกรณ์ใกล้เคียง...');
      debugPrint('   Service ID: $_serviceId');
      debugPrint('   Strategy: P2P_CLUSTER');
      
      await _nearby.startDiscovery(
        _serviceId,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (String endpointId, String endpointName, String serviceId) {
          debugPrint('🎯 พบอุปกรณ์: $endpointName (ID: $endpointId)');
          _onEndpointFound(endpointId, endpointName, serviceId);
        },
        onEndpointLost: _onEndpointLost,
      );
      
      _isDiscovering = true;
      debugPrint('✅ Discovery เริ่มสำเร็จ');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error discovering: $e');
      
      // Handle specific errors
      if (e.toString().contains('MISSING_PERMISSION_ACCESS_COARSE_LOCATION')) {
        debugPrint('💡 ต้องเปิด Location permission ใน Settings → Apps → Off-Grid SOS → Permissions');
        debugPrint('💡 เลือก "Allow all the time" ไม่ใช่ "Allow only while using the app"');
      }
      
      return false;
    }
  }

  // Enhanced permission checking
  Future<bool> _checkLocationPermissions() async {
    final location = await Permission.location.status;
    final locationWhenInUse = await Permission.locationWhenInUse.status;
    
    return location.isGranted || locationWhenInUse.isGranted;
  }

  // Stop advertising
  Future<void> stopAdvertising() async {
    if (_isAdvertising) {
      try {
        await _nearby.stopAdvertising();
        _isAdvertising = false;
        _currentDeviceName = null;
        debugPrint('🛑 หยุด advertising แล้ว');
      } catch (e) {
        debugPrint('⚠️ Error stopping advertising: $e');
      }
    }
  }

  // Stop discovery
  Future<void> stopDiscovery() async {
    if (_isDiscovering) {
      try {
        await _nearby.stopDiscovery();
        _isDiscovering = false;
        debugPrint('🛑 หยุด discovery แล้ว');
      } catch (e) {
        debugPrint('⚠️ Error stopping discovery: $e');
      }
    }
  }

  // Enhanced connection handlers
  void _onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
    debugPrint('🤝 Connection initiated: ${connectionInfo.endpointName}');
    
    // Auto-accept connections (you might want to add user confirmation)
    _nearby.acceptConnection(
      endpointId, 
      onPayLoadRecieved: (String endpointId, Payload payload) {
        _onPayloadReceived(endpointId, payload);
      },
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      debugPrint('✅ เชื่อมต่อสำเร็จ: $endpointId');
      _connectedEndpoints.add(endpointId);
    } else {
      debugPrint('❌ เชื่อมต่อไม่สำเร็จ: $endpointId - ${status.toString()}');
    }
  }

  void _onDisconnected(String endpointId) {
    debugPrint('💔 ตัดการเชื่อมต่อ: $endpointId');
    _connectedEndpoints.remove(endpointId);
  }

  void _onEndpointFound(String endpointId, String endpointName, String serviceId) {
    debugPrint('🎯 พบอุปกรณ์: $endpointName');
    
    _deviceFoundController.add({
      'endpointId': endpointId,
      'endpointName': endpointName,
      'serviceId': serviceId,
    });
  }

  void _onEndpointLost(String endpointId) {
    debugPrint('💔 อุปกรณ์หายไป: $endpointId');
    _deviceLostController.add(endpointId);
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      try {
        final message = String.fromCharCodes(payload.bytes!);
        final data = jsonDecode(message);
        debugPrint('📨 ได้รับข้อความ: $message');
        
        _messageController.add({
          'endpointId': endpointId,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        debugPrint('❌ Error parsing message: $e');
      }
    }
  }

  // Enhanced message sending
  Future<bool> sendMessage(String endpointId, Map<String, dynamic> data) async {
    try {
      final message = jsonEncode(data);
      final bytes = Uint8List.fromList(message.codeUnits);
      
      await _nearby.sendBytesPayload(endpointId, bytes);
      debugPrint('📤 ส่งข้อความแล้ว: $message');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      return false;
    }
  }

  // Connect to a discovered endpoint
  Future<bool> connectToEndpoint(String endpointId, String endpointName) async {
    try {
      debugPrint('🔗 กำลังเชื่อมต่อกับ: $endpointName');
      
      await _nearby.requestConnection(
        'SOS_Rescuer',
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ Error connecting to endpoint: $e');
      return false;
    }
  }

  // Cleanup
  void dispose() {
    stopAdvertising();
    stopDiscovery();
    _messageController.close();
    _deviceFoundController.close();
    _deviceLostController.close();
  }
}