import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import '../services/p2p_service.dart';
import '../services/nearby_service.dart';
import '../data/db.dart';
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

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
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
      debugPrint('🆘 เปิด SOS Mode...');
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
      
      // Start advertising as SOS device
      debugPrint('📡 เริ่ม advertising...');
      await _p2pService?.startAdvertising(deviceName);
      await _nearbyService?.startAdvertising('SOS_$deviceName');
      
      // Broadcast SOS signal
      final sosData = {
        'type': 'sos',
        'active': true,
        'deviceId': 'device_${DateTime.now().millisecondsSinceEpoch}',
        'deviceName': deviceName,
        'deviceType': userInfo['deviceType'],
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Emergency: Need assistance',
        'priority': 'high',
      };
      
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
    } else {
      // Deactivate SOS
      state = false;
      
      // Broadcast SOS deactivation
      await _p2pService?.sendMessage('SOS deactivated by $deviceName');
      
      // Optionally stop advertising (or keep it for normal communication)
      // await _p2pService?.stopAdvertising();
      // await _nearbyService?.stopAdvertising();
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
      
      // Start rescuer mode - begin scanning for SOS signals
      debugPrint('🔍 เริ่มสแกนหา SOS signals...');
      await _p2pService?.startDiscovery();
      await _nearbyService?.startDiscovery();
      await _p2pService?.startAdvertising('Rescuer_$deviceName');
      await _nearbyService?.startAdvertising('Rescuer_$deviceName');
    } else {
      // Stop rescuer mode - stop scanning
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
    // Listen for peer discovery
    _peerFoundSubscription = _p2pService?.onPeerFound.listen((endpointId) {
      addOrUpdateDevice(RealNearbyDevice.fromEndpoint(
        endpointId: endpointId,
        deviceName: 'Device_$endpointId',
        status: DeviceConnectionStatus.discovered,
      ));
    });

    // Listen for peer lost
    _peerLostSubscription = _p2pService?.onPeerLost.listen((endpointId) {
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
      final deviceCompanion = DeviceCompanion(
        id: Value(device.id),
        name: Value(device.name),
        deviceType: Value(device.type),
        lastSeen: Value(device.lastSeen),
      );
      
      await database.upsertDevice(deviceCompanion);
    } catch (e) {
      // Handle database error silently
      debugPrint('Error saving device to database: $e');
    }
  }

  Future<void> startScanning() async {
    await _p2pService?.initialize();
    await _nearbyService?.initialize();
    
    await _p2pService?.startDiscovery();
    await _nearbyService?.startDiscovery();
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