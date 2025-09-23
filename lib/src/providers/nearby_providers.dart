import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nearby_service.dart';

final nearbyServiceProvider = Provider<NearbyService>((ref) {
  return NearbyService.instance;
});

final sosActiveProvider = NotifierProvider<SOSNotifier, bool>(() {
  return SOSNotifier();
});

final rescuerModeProvider = NotifierProvider<RescuerModeNotifier, bool>(() {
  return RescuerModeNotifier();
});

// State Notifiers
class SOSNotifier extends Notifier<bool> {
  @override
  bool build() => false;

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

class RescuerModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

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