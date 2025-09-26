import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/nearby_service.dart';
import '../services/sos_broadcast_service.dart';

// Enhanced nearby devices provider that shows SOS status
final nearbyDevicesWithSOSProvider = StreamProvider<List<NearbyDevice>>((ref) {
  final controller = StreamController<List<NearbyDevice>>();
  
  final nearbyService = NearbyService.instance;
  final sosService = SOSBroadcastService.instance;
  
  // Listen to device discovery
  StreamSubscription? deviceSubscription;
  StreamSubscription? sosSubscription;
  
  final List<NearbyDevice> devices = [];
  
  void updateDevices() {
    controller.add(List.from(devices));
  }
  
  // Listen to nearby device discovery
  deviceSubscription = nearbyService.onDeviceFound.listen((deviceData) {
    final deviceId = deviceData['id'] ?? '';
    final deviceName = deviceData['name'] ?? 'Unknown Device';
    
    // Check if device already exists
    final existingIndex = devices.indexWhere((d) => d.id == deviceId);
    
    final device = NearbyDevice(
      id: deviceId,
      name: deviceName,
      role: DeviceRole.normal, // Will be updated when SOS status is received
      isSOSActive: false,
      isRescuerActive: false,
      lastSeen: DateTime.now(),
      signalStrength: deviceData['signalStrength'] ?? -50,
      isConnected: nearbyService.connectedEndpoints.contains(deviceId),
      connectionType: 'nearby',
    );
    
    if (existingIndex >= 0) {
      devices[existingIndex] = device;
    } else {
      devices.add(device);
    }
    
    updateDevices();
  });
  
  // Listen to SOS broadcasts to update device roles
  sosSubscription = sosService.onSOSReceived.listen((sosBroadcast) {
    final deviceIndex = devices.indexWhere((d) => d.id == sosBroadcast.victimId);
    if (deviceIndex >= 0) {
      devices[deviceIndex] = devices[deviceIndex].copyWith(
        role: DeviceRole.sosUser,
        isSOSActive: true,
        latitude: sosBroadcast.latitude,
        longitude: sosBroadcast.longitude,
        lastSeen: DateTime.now(),
      );
      updateDevices();
    }
  });
  
  // Clean up on dispose
  ref.onDispose(() {
    deviceSubscription?.cancel();
    sosSubscription?.cancel();
    controller.close();
  });
  
  return controller.stream;
});

// Provider for current device SOS status
final currentDeviceSOSProvider = StreamProvider<SOSMode>((ref) {
  return SOSBroadcastService.instance.onModeChanged;
});

// Provider to check if any nearby devices are in SOS mode
final nearbySOSDevicesCountProvider = Provider<AsyncValue<int>>((ref) {
  final devicesAsync = ref.watch(nearbyDevicesWithSOSProvider);
  
  return devicesAsync.when(
    data: (devices) => AsyncValue.data(
      devices.where((d) => d.isSOSActive).length
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});