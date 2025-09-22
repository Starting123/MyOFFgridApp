import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nearby_service.dart';

final nearbyServiceProvider = Provider<NearbyService>((ref) {
  return NearbyService.instance;
});

final sosActiveProvider = StateNotifierProvider<SOSNotifier, bool>((ref) {
  return SOSNotifier(ref);
});

final rescuerModeProvider = StateNotifierProvider<RescuerModeNotifier, bool>((ref) {
  return RescuerModeNotifier(ref);
});

// State Notifiers
class SOSNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  SOSNotifier(this.ref) : super(false);

  Future<void> toggle() async {
    state = !state;
    final nearbyService = ref.read(nearbyServiceProvider);
    
    if (state) {
      await nearbyService.startAdvertising('SOS_Device');
      await nearbyService.broadcastSOS(
        deviceId: 'device_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Emergency: Need assistance',
        additionalData: {
          'type': 'emergency',
          'priority': 'high',
        },
      );
    } else {
      await nearbyService.stopAdvertising();
    }
  }
}

class RescuerModeNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  RescuerModeNotifier(this.ref) : super(false);

  Future<void> toggle() async {
    state = !state;
    final nearbyService = ref.read(nearbyServiceProvider);
    
    if (state) {
      await nearbyService.startDiscovery();
    } else {
      await nearbyService.stopDiscovery();
    }
  }
}