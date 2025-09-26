import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/nearby_service.dart';

// Enhanced nearby provider for device discovery with SOS filtering
final nearbyDevicesWithSOSProvider = StreamProvider<List<NearbyDevice>>((ref) async* {
  final nearbyService = NearbyService.instance;
  
  // Mock stream for now - replace with actual service implementation
  yield* Stream.periodic(const Duration(seconds: 5), (index) {
    return [
      NearbyDevice(
        id: 'device_$index',
        name: 'SOS User $index',
        role: DeviceRole.sosUser,
        isSOSActive: true,
        isRescuerActive: false,
        isConnected: false,
        signalStrength: -50 + (index * 5),
        lastSeen: DateTime.now(),
        connectionType: 'bluetooth',
      ),
    ];
  });
});

// Provider for starting/stopping device scanning
final deviceScanningProvider = NotifierProvider<DeviceScanningNotifier, bool>(() {
  return DeviceScanningNotifier();
});

class DeviceScanningNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  final _nearbyService = NearbyService.instance;
  
  Future<void> startScanning() async {
    state = true;
    try {
      await _nearbyService.initialize();
      // Start scanning logic here
    } catch (e) {
      state = false;
      rethrow;
    }
  }
  
  Future<void> stopScanning() async {
    try {
      // Stop scanning logic here
    } finally {
      state = false;
    }
  }
}