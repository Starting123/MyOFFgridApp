import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

import '../services/p2p_service.dart';
import '../services/nearby_service.dart';
import '../data/enhanced_db.dart';
import '../utils/debug_helper.dart';

// Real device model
class RealNearbyDevice {
  final String id;
  final String name;
  final String type;
  final double? distance;
  final int? signalStrength;
  final int? batteryLevel;
  final DateTime lastSeen;
  final DeviceConnectionStatus status;

  RealNearbyDevice({
    required this.id,
    required this.name,
    required this.type,
    this.distance,
    this.signalStrength,
    this.batteryLevel,
    required this.lastSeen,
    required this.status,
  });

  factory RealNearbyDevice.fromEndpoint({
    required String endpointId,
    required String deviceName,
    required DeviceConnectionStatus status,
    String? deviceType,
    Map<String, dynamic>? metadata,
  }) {
    return RealNearbyDevice(
      id: endpointId,
      name: deviceName,
      type: deviceType ?? 'Unknown',
      distance: metadata?['distance']?.toDouble(),
      signalStrength: metadata?['signalStrength']?.toInt(),
      batteryLevel: metadata?['batteryLevel']?.toInt(),
      lastSeen: DateTime.now(),
      status: status,
    );
  }

  RealNearbyDevice copyWith({
    String? id,
    String? name,
    String? type,
    double? distance,
    int? signalStrength,
    int? batteryLevel,
    DateTime? lastSeen,
    DeviceConnectionStatus? status,
  }) {
    return RealNearbyDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      distance: distance ?? this.distance,
      signalStrength: signalStrength ?? this.signalStrength,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
    );
  }
}

enum DeviceConnectionStatus {
  discovered,
  connecting,
  connected,
  disconnected,
  sosActive,
}

// Service providers
final p2pServiceProvider = Provider<P2PService>((ref) {
  return P2PService.instance;
});

final nearbyServiceProvider = Provider<NearbyService>((ref) {
  return NearbyService.instance;
});

final databaseProvider = Provider<EnhancedAppDatabase>((ref) {
  return EnhancedAppDatabase();
});

// User info provider (existing - keeping real implementation)
final userInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'name': prefs.getString('user_name') ?? 'ไม่ได้ระบุชื่อ',
    'phone': prefs.getString('user_phone') ?? '',
    'deviceType': prefs.getString('device_type') ?? 'SOS',
  };
});

// Real SOS provider with actual P2P service integration
final realSOSActiveProvider = NotifierProvider<RealSOSNotifier, bool>(() {
  return RealSOSNotifier();
});

class RealSOSNotifier extends Notifier<bool> {
  StreamSubscription? _messageSubscription;
  P2PService? _p2pService;
  NearbyService? _nearbyService;

  @override
  bool build() {
    _p2pService = ref.read(p2pServiceProvider);
    _nearbyService = ref.read(nearbyServiceProvider);
    
    // Listen for incoming data to detect SOS signals from others
    _messageSubscription = _p2pService?.onDataReceived.listen((data) {
      if (data['type'] == 'sos' && data['active'] == true) {
        // Another device is broadcasting SOS - update UI accordingly
        ref.read(realNearbyDevicesProvider.notifier).updateDeviceStatus(
          data['deviceId'], 
          DeviceConnectionStatus.sosActive
        );
      }
    });
    
    return false;
  }

  Future<void> toggle() async {
    final userInfo = await ref.read(userInfoProvider.future);
    final deviceName = userInfo['name'] ?? 'Unknown Device';
    
    if (!state) {
      // Activate SOS
      Logger.sos('🆘 เปิด SOS Mode...');
      state = true;
      
      // Initialize services if needed
      debugPrint('🔄 เริ่มต้น services...');
      final p2pInit = await _p2pService?.initialize() ?? false;
      final nearbyInit = await _nearbyService?.initialize() ?? false;
      
      debugPrint('P2P Service: ${p2pInit ? "✅" : "❌"}');
      debugPrint('Nearby Service: ${nearbyInit ? "✅" : "❌"}');
      
      if (!p2pInit && !nearbyInit) {
        debugPrint('❌ ไม่สามารถเริ่มต้น services ได้');
        state = false;
        return;
      }
      
      // FIXED: Start advertising with clear SOS prefix - Only use Nearby Service since P2P failed
      debugPrint('📡 เริ่ม advertising: SOS_$deviceName');
      if (nearbyInit) {
        try {
          await _nearbyService?.startAdvertising('SOS_$deviceName');
          debugPrint('✅ Nearby advertising เริ่มสำเร็จ');
        } catch (e) {
          debugPrint('⚠️ Nearby advertising error (จะลองใหม่): $e');
        }
      }
      
      // Try P2P only if initialized
      if (p2pInit) {
        try {
          await _p2pService?.startAdvertising('SOS_$deviceName');
          debugPrint('✅ P2P advertising เริ่มสำเร็จ');
        } catch (e) {
          debugPrint('⚠️ P2P advertising error: $e');
        }
      }
      
      // Wait for advertising to establish
      await Future.delayed(const Duration(seconds: 2));
      
      // ALSO start discovery to see other devices
      debugPrint('🔍 เริ่ม discovery เพื่อหาอุปกรณ์อื่น...');
      if (nearbyInit) {
        try {
          await _nearbyService?.startDiscovery();
          debugPrint('✅ Nearby discovery เริ่มสำเร็จ');
        } catch (e) {
          debugPrint('⚠️ Nearby discovery error: $e');
        }
      }
      
      if (p2pInit) {
        try {
          await _p2pService?.startDiscovery();
          debugPrint('✅ P2P discovery เริ่มสำเร็จ');
        } catch (e) {
          debugPrint('⚠️ P2P discovery error: $e');
        }
      }
      
      // 🔥 NEW: เริ่ม device scanning ใน UI ด้วย
      debugPrint('📱 เริ่ม device scanning สำหรับ SOS...');
      ref.read(realNearbyDevicesProvider.notifier).startScanning();
      
      // Broadcast SOS signal
      final sosData = {
        'type': 'sos',
        'active': true,
        'deviceId': 'SOS_${DateTime.now().millisecondsSinceEpoch}',
        'deviceName': deviceName,
        'deviceType': userInfo['deviceType'],
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Emergency: Need assistance',
        'priority': 'high',
      };
      
      debugPrint('📢 Broadcasting SOS signal...');
      await _p2pService?.sendSOS(sosData['message'] as String);
      await _nearbyService?.broadcastSOS(
        deviceId: sosData['deviceId'] as String,
        message: sosData['message'] as String,
        additionalData: {
          'deviceName': deviceName,
          'deviceType': userInfo['deviceType'],
          'priority': 'high',
        },
      );
      
      debugPrint('✅ SOS Broadcasting เสร็จสิ้น');
    } else {
      // Deactivate SOS
      debugPrint('🔴 ปิด SOS Mode...');
      state = false;
      
      // Broadcast SOS deactivation
      await _p2pService?.sendMessage('SOS deactivated by $deviceName');
      
      // Stop discovery but keep advertising for normal communication
      await _p2pService?.stopDiscovery();
      await _nearbyService?.stopDiscovery();
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}

// Real Rescuer Mode provider with actual service integration
final realRescuerModeProvider = NotifierProvider<RealRescuerModeNotifier, bool>(() {
  return RealRescuerModeNotifier();
});

class RealRescuerModeNotifier extends Notifier<bool> {
  P2PService? _p2pService;
  NearbyService? _nearbyService;

  @override
  bool build() {
    _p2pService = ref.read(p2pServiceProvider);
    _nearbyService = ref.read(nearbyServiceProvider);
    return false;
  }

  Future<void> toggle() async {
    final userInfo = await ref.read(userInfoProvider.future);
    final deviceName = userInfo['name'] ?? 'Unknown Rescuer';
    
    state = !state;
    
    if (state) {
      debugPrint('👨‍⚕️ เปิด Rescuer Mode...');
      
      // Check permissions first
      await DeviceDiscoveryDebugger.checkAllPermissions();
      
      // Initialize services
      debugPrint('🔄 เริ่มต้น services...');
      final p2pInit = await _p2pService?.initialize() ?? false;
      final nearbyInit = await _nearbyService?.initialize() ?? false;
      
      debugPrint('P2P Service: ${p2pInit ? "✅" : "❌"}');
      debugPrint('Nearby Service: ${nearbyInit ? "✅" : "❌"}');
      
      if (!p2pInit && !nearbyInit) {
        debugPrint('❌ ไม่สามารถเริ่มต้น services ได้');
        state = false;
        return;
      }
      
      // FIXED: Start advertising FIRST, then discovery
      debugPrint('📡 เริ่ม advertising ก่อน...');
      await _p2pService?.startAdvertising('Rescuer_$deviceName');
      await _nearbyService?.startAdvertising('Rescuer_$deviceName');
      
      // Wait a bit for advertising to establish
      await Future.delayed(const Duration(seconds: 2));
      
      debugPrint('🔍 เริ่มสแกนหา SOS signals...');
      await _p2pService?.startDiscovery();
      await _nearbyService?.startDiscovery();
      
      // Trigger immediate device scanning
      ref.read(realNearbyDevicesProvider.notifier).startScanning();
      
    } else {
      // Stop rescuer mode - stop scanning
      debugPrint('🔴 ปิด Rescuer Mode...');
      await _p2pService?.stopDiscovery();
      await _nearbyService?.stopDiscovery();
      // Keep advertising for normal communication
    }
  }
}

// Real nearby devices provider with actual service integration
final realNearbyDevicesProvider = NotifierProvider<RealNearbyDevicesNotifier, List<RealNearbyDevice>>(() {
  return RealNearbyDevicesNotifier();
});

class RealNearbyDevicesNotifier extends Notifier<List<RealNearbyDevice>> {
  StreamSubscription? _peerFoundSubscription;
  StreamSubscription? _peerLostSubscription;
  StreamSubscription? _messageSubscription;
  P2PService? _p2pService;
  NearbyService? _nearbyService;
  Timer? _cleanupTimer;

  @override
  List<RealNearbyDevice> build() {
    _p2pService = ref.read(p2pServiceProvider);
    _nearbyService = ref.read(nearbyServiceProvider);
    
    _initializeServiceListeners();
    
    // Start periodic cleanup of old devices
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupOldDevices();
    });
    
    return [];
  }

  void _initializeServiceListeners() {
    // Listen for peer discovery from P2P Service
    _peerFoundSubscription = _p2pService?.onPeerFound.listen((endpointId) {
      addOrUpdateDevice(RealNearbyDevice.fromEndpoint(
        endpointId: endpointId,
        deviceName: 'Device_$endpointId',
        status: DeviceConnectionStatus.discovered,
      ));
    });

    // Listen for peer lost from P2P Service
    _peerLostSubscription = _p2pService?.onPeerLost.listen((endpointId) {
      removeDevice(endpointId);
    });

    // 🔥 NEW: Listen for device discovery from Nearby Service
    _nearbyService?.onDeviceFound.listen((deviceData) {
      final String endpointId = deviceData['endpointId'];
      final String endpointName = deviceData['endpointName'];
      
      // แยกข้อมูลจาก device name
      String deviceType = 'Unknown';
      String actualName = endpointName;
      
      if (endpointName.startsWith('SOS_')) {
        deviceType = 'SOS';
        actualName = endpointName.substring(4); // ตัด 'SOS_' ออก
      } else if (endpointName.startsWith('Rescuer_')) {
        deviceType = 'Rescuer';
        actualName = endpointName.substring(8); // ตัด 'Rescuer_' ออก
      }
      
      final device = RealNearbyDevice.fromEndpoint(
        endpointId: endpointId,
        deviceName: actualName,
        deviceType: deviceType,
        status: DeviceConnectionStatus.discovered,
      );
      
      debugPrint('📱 เพิ่มอุปกรณ์ใน UI: $actualName ($deviceType)');
      addOrUpdateDevice(device);
    });

    // 🔥 NEW: Listen for device lost from Nearby Service
    _nearbyService?.onDeviceLost.listen((endpointId) {
      debugPrint('📱 ลบอุปกรณ์จาก UI: $endpointId');
      removeDevice(endpointId);
    });

    // Listen for incoming messages to extract device info
    _messageSubscription = _p2pService?.onDataReceived.listen((data) {
      if (data.containsKey('deviceId') && data.containsKey('deviceName')) {
        final device = RealNearbyDevice.fromEndpoint(
          endpointId: data['deviceId'],
          deviceName: data['deviceName'],
          deviceType: data['deviceType'],
          status: data['type'] == 'sos' && data['active'] == true
              ? DeviceConnectionStatus.sosActive
              : DeviceConnectionStatus.connected,
          metadata: {
            'signalStrength': data['signalStrength'],
            'batteryLevel': data['batteryLevel'],
            'distance': data['distance'],
          },
        );
        addOrUpdateDevice(device);
      }
    });

    // 🔥 NEW: Listen for messages from Nearby Service
    _nearbyService?.onMessage.listen((data) {
      debugPrint('📨 ได้รับข้อความใน Provider: $data');
      
      // อัปเดต device status ตามข้อความที่ได้รับ
      if (data.containsKey('deviceName')) {
        final existingDevice = state.firstWhere(
          (device) => device.name == data['deviceName'],
          orElse: () => RealNearbyDevice.fromEndpoint(
            endpointId: data['deviceId'] ?? 'unknown',
            deviceName: data['deviceName'],
            deviceType: data['deviceType'] ?? 'Unknown',
            status: DeviceConnectionStatus.connected,
          ),
        );
        
        // อัปเดต status
        final updatedDevice = existingDevice.copyWith(
          status: data['type'] == 'sos' 
              ? DeviceConnectionStatus.sosActive 
              : DeviceConnectionStatus.connected,
        );
        
        addOrUpdateDevice(updatedDevice);
      }
    });
  }

  void addOrUpdateDevice(RealNearbyDevice device) {
    final currentDevices = List<RealNearbyDevice>.from(state);
    final existingIndex = currentDevices.indexWhere((d) => d.id == device.id);
    
    if (existingIndex >= 0) {
      currentDevices[existingIndex] = device;
    } else {
      currentDevices.add(device);
    }
    
    state = currentDevices;
    
    // Save to database
    _saveDeviceToDatabase(device);
  }

  void removeDevice(String deviceId) {
    state = state.where((device) => device.id != deviceId).toList();
  }

  void updateDeviceStatus(String deviceId, DeviceConnectionStatus status) {
    final currentDevices = List<RealNearbyDevice>.from(state);
    final deviceIndex = currentDevices.indexWhere((d) => d.id == deviceId);
    
    if (deviceIndex >= 0) {
      final device = currentDevices[deviceIndex];
      currentDevices[deviceIndex] = RealNearbyDevice(
        id: device.id,
        name: device.name,
        type: device.type,
        distance: device.distance,
        signalStrength: device.signalStrength,
        batteryLevel: device.batteryLevel,
        lastSeen: DateTime.now(),
        status: status,
      );
      state = currentDevices;
    }
  }

  void _cleanupOldDevices() {
    final now = DateTime.now();
    state = state.where((device) {
      // Remove devices not seen in the last 5 minutes
      return now.difference(device.lastSeen).inMinutes < 5;
    }).toList();
  }

  Future<void> _saveDeviceToDatabase(RealNearbyDevice device) async {
    try {
      final database = ref.read(databaseProvider);
      await database.upsertDevice(
        device.id,
        device.name,
        device.type,
      );
    } catch (e) {
      // Handle database error silently
      debugPrint('Error saving device to database: $e');
    }
  }

  Future<void> startScanning() async {
    debugPrint('🔍 RealDevices: เริ่มสแกนหาอุปกรณ์ใกล้เคียง...');
    
    // Initialize if needed
    await _p2pService?.initialize();
    await _nearbyService?.initialize();
    
    // Start both services
    debugPrint('📡 เริ่ม P2P discovery...');
    await _p2pService?.startDiscovery();
    
    debugPrint('📡 เริ่ม Nearby discovery...');
    await _nearbyService?.startDiscovery();
    
    // Force a manual scan after a delay
    Future.delayed(const Duration(seconds: 3), () {
      debugPrint('🔄 Force refresh scan...');
      _triggerManualScan();
    });
  }

  void _triggerManualScan() {
    // This will trigger any pending callbacks or force service refresh
    debugPrint('🔄 Manual scan trigger...');
    // Force a state refresh to trigger UI updates
    state = [...state];
  }

  Future<void> stopScanning() async {
    await _p2pService?.stopDiscovery();
    await _nearbyService?.stopDiscovery();
  }

  Future<bool> connectToDevice(String deviceId) async {
    try {
      // P2PService handles connections automatically when peers are found
      // Update device status to connecting
      updateDeviceStatus(deviceId, DeviceConnectionStatus.connecting);
      
      // The actual connection will be handled by P2PService callbacks
      // When connection is established, the status will be updated via message subscription
      
      return true;
    } catch (e) {
      updateDeviceStatus(deviceId, DeviceConnectionStatus.disconnected);
      return false;
    }
  }

  void dispose() {
    _peerFoundSubscription?.cancel();
    _peerLostSubscription?.cancel();
    _messageSubscription?.cancel();
    _cleanupTimer?.cancel();
  }
}