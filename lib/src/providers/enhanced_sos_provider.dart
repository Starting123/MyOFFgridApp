import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sos_broadcast_service.dart';

// SOS State Model
class SOSAppState {
  final bool isSOSActive;
  final bool isBroadcasting;
  final String? currentLocation;
  final List<String> connectedDevices;
  final DateTime? lastSOSTime;

  const SOSAppState({
    this.isSOSActive = false,
    this.isBroadcasting = false,
    this.currentLocation,
    this.connectedDevices = const [],
    this.lastSOSTime,
  });

  SOSAppState copyWith({
    bool? isSOSActive,
    bool? isBroadcasting,
    String? currentLocation,
    List<String>? connectedDevices,
    DateTime? lastSOSTime,
  }) {
    return SOSAppState(
      isSOSActive: isSOSActive ?? this.isSOSActive,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      currentLocation: currentLocation ?? this.currentLocation,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      lastSOSTime: lastSOSTime ?? this.lastSOSTime,
    );
  }
}

// SOS State Notifier
class SOSNotifier extends AsyncNotifier<SOSAppState> {
  SOSBroadcastService? _sosService;

  @override
  Future<SOSAppState> build() async {
    _sosService = SOSBroadcastService.instance;
    return const SOSAppState();
  }

  Future<void> toggleSOS() async {
    final currentState = state.value ?? const SOSAppState();
    
    if (currentState.isSOSActive) {
      await _stopSOS();
    } else {
      await _startSOS();
    }
  }

  Future<void> _startSOS() async {
    try {
      state = const AsyncValue.loading();
      
      if (_sosService != null) {
        await _sosService!.activateVictimMode(emergencyMessage: 'Emergency SOS');
      }
      
      final newState = SOSAppState(
        isSOSActive: true,
        isBroadcasting: true,
        lastSOSTime: DateTime.now(),
        currentLocation: 'Current Location', // Replace with actual location
      );
      
      state = AsyncValue.data(newState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _stopSOS() async {
    try {
      state = const AsyncValue.loading();
      
      if (_sosService != null) {
        _sosService!.disableSOSMode();
      }
      
      const newState = SOSAppState(
        isSOSActive: false,
        isBroadcasting: false,
      );
      
      state = const AsyncValue.data(newState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Public methods for the UI to call
  Future<void> activateVictimMode({String? emergencyMessage}) async {
    await _startSOS();
  }

  Future<void> disableSOSMode() async {
    await _stopSOS();
  }
}

// SOS Provider
final sosProvider = AsyncNotifierProvider<SOSNotifier, SOSAppState>(() {
  return SOSNotifier();
});