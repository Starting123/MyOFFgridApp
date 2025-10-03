import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/service_coordinator.dart';

/// Production-ready device discovery provider using ServiceCoordinator's unified streams
/// Replaces mock data with real device discovery across all communication services
final nearbyDevicesWithSOSProvider = StreamProvider<List<NearbyDevice>>((ref) async* {
  final coordinator = ServiceCoordinator.instance;
  
  // Initialize the service coordinator if not already done
  if (!coordinator.isInitialized) {
    await coordinator.initializeAll();
  }
  
  // Use the unified device discovery stream from ServiceCoordinator
  yield* coordinator.deviceStream.map((devices) {
    // Apply SOS filtering and priority sorting
    final sortedDevices = devices.toList();
    
    // Sort by priority: SOS users first, then rescuers, then normal devices
    sortedDevices.sort((a, b) {
      if (a.isSOSActive && !b.isSOSActive) return -1;
      if (!a.isSOSActive && b.isSOSActive) return 1;
      if (a.isRescuerActive && !b.isRescuerActive) return -1;
      if (!a.isRescuerActive && b.isRescuerActive) return 1;
      return a.name.compareTo(b.name);
    });
    
    return sortedDevices;
  });
});

/// Provider for SOS-specific device filtering
final sosDevicesProvider = Provider<AsyncValue<List<NearbyDevice>>>((ref) {
  final devicesAsync = ref.watch(nearbyDevicesWithSOSProvider);
  return devicesAsync.when(
    data: (devices) => AsyncValue.data(
      devices.where((device) => device.isSOSActive).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for rescuer device filtering  
final rescuerDevicesProvider = Provider<AsyncValue<List<NearbyDevice>>>((ref) {
  final devicesAsync = ref.watch(nearbyDevicesWithSOSProvider);
  return devicesAsync.when(
    data: (devices) => AsyncValue.data(
      devices.where((device) => device.isRescuerActive).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for connected devices only
final connectedDevicesProvider = Provider<AsyncValue<List<NearbyDevice>>>((ref) {
  final devicesAsync = ref.watch(nearbyDevicesWithSOSProvider);
  return devicesAsync.when(
    data: (devices) => AsyncValue.data(
      devices.where((device) => device.isConnected).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Service status provider for UI indicators
final serviceStatusProvider = Provider<Map<String, bool>>((ref) {
  final coordinator = ServiceCoordinator.instance;
  return coordinator.getServiceStatus();
});

/// Device scanning state provider
final deviceScanningProvider = NotifierProvider<DeviceScanningNotifier, DeviceScanningState>(() {
  return DeviceScanningNotifier();
});

class DeviceScanningState {
  final bool isScanning;
  final String? error;
  final Map<String, bool> serviceStatus;
  final int deviceCount;

  const DeviceScanningState({
    required this.isScanning,
    this.error,
    required this.serviceStatus,
    required this.deviceCount,
  });

  DeviceScanningState copyWith({
    bool? isScanning,
    String? error,
    Map<String, bool>? serviceStatus,
    int? deviceCount,
  }) {
    return DeviceScanningState(
      isScanning: isScanning ?? this.isScanning,
      error: error ?? this.error,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      deviceCount: deviceCount ?? this.deviceCount,
    );
  }
}

class DeviceScanningNotifier extends Notifier<DeviceScanningState> {
  @override
  DeviceScanningState build() {
    return const DeviceScanningState(
      isScanning: false,
      serviceStatus: {},
      deviceCount: 0,
    );
  }
  
  final _coordinator = ServiceCoordinator.instance;
  
  Future<void> startScanning() async {
    state = state.copyWith(isScanning: true, error: null);
    
    try {
      // Initialize ServiceCoordinator with all services
      final success = await _coordinator.initializeAll();
      
      if (!success) {
        throw Exception('Failed to initialize communication services');
      }
      
      // Update service status
      final serviceStatus = _coordinator.getServiceStatus();
      state = state.copyWith(
        serviceStatus: serviceStatus,
        deviceCount: _coordinator.discoveredDevices.length,
      );
      
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Scanning failed: $e',
      );
      rethrow;
    }
  }
  
  Future<void> stopScanning() async {
    try {
      // ServiceCoordinator handles stopping discovery internally
      // We just update the UI state
      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Failed to stop scanning: $e',
      );
    }
  }
  
  void updateDeviceCount(int count) {
    state = state.copyWith(deviceCount: count);
  }
}

/// Message stream provider using ServiceCoordinator
final messageStreamProvider = StreamProvider<ChatMessage>((ref) {
  final coordinator = ServiceCoordinator.instance;
  return coordinator.messageStream;
});

/// Provider for sending messages through ServiceCoordinator
final messageSenderProvider = Provider<MessageSender>((ref) {
  return MessageSender();
});

class MessageSender {
  final _coordinator = ServiceCoordinator.instance;
  
  Future<bool> sendMessage(ChatMessage message) async {
    return await _coordinator.sendMessage(message);
  }
  
  Future<void> broadcastSOS(String message, {double? latitude, double? longitude}) async {
    await _coordinator.broadcastSOS(message, latitude, longitude);
  }
  
  Future<bool> connectToDevice(String deviceId) async {
    return await _coordinator.connectToDevice(deviceId);
  }
}