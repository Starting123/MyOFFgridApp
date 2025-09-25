import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sos_broadcast_service.dart';
import '../services/nearby_service.dart';
import '../services/location_service.dart';
import '../services/enhanced_message_queue_service.dart';
import '../models/enhanced_message_model.dart';

/// SOS Application State
class SOSAppState {
  final SOSMode currentMode;
  final bool isSOSActive;
  final List<SOSBroadcast> activeSOS;
  final List<Map<String, dynamic>> nearbyDevices;
  final int connectedDevicesCount;
  final bool isLocationEnabled;
  final String? lastLocation;
  final String? error;

  const SOSAppState({
    this.currentMode = SOSMode.disabled,
    this.isSOSActive = false,
    this.activeSOS = const [],
    this.nearbyDevices = const [],
    this.connectedDevicesCount = 0,
    this.isLocationEnabled = false,
    this.lastLocation,
    this.error,
  });

  SOSAppState copyWith({
    SOSMode? currentMode,
    bool? isSOSActive,
    List<SOSBroadcast>? activeSOS,
    List<Map<String, dynamic>>? nearbyDevices,
    int? connectedDevicesCount,
    bool? isLocationEnabled,
    String? lastLocation,
    String? error,
  }) {
    return SOSAppState(
      currentMode: currentMode ?? this.currentMode,
      isSOSActive: isSOSActive ?? this.isSOSActive,
      activeSOS: activeSOS ?? this.activeSOS,
      nearbyDevices: nearbyDevices ?? this.nearbyDevices,
      connectedDevicesCount: connectedDevicesCount ?? this.connectedDevicesCount,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      lastLocation: lastLocation ?? this.lastLocation,
      error: error ?? this.error,
    );
  }
}

/// SOS State Notifier for managing SOS functionality
class SOSNotifier extends AsyncNotifier<SOSAppState> {
  final SOSBroadcastService _sosService = SOSBroadcastService.instance;
  final NearbyService _nearbyService = NearbyService.instance;
  final LocationService _locationService = LocationService.instance;
  final MessageQueueService _messageQueue = MessageQueueService.instance;

  StreamSubscription? _sosSubscription;
  StreamSubscription? _modeSubscription;
  StreamSubscription? _deviceFoundSubscription;
  StreamSubscription? _deviceLostSubscription;
  Timer? _statusUpdateTimer;

  @override
  Future<SOSAppState> build() async {
    // Initialize services
    final locationEnabled = await _checkLocationPermission();
    
    // Listen to SOS events
    _sosSubscription = _sosService.onSOSReceived.listen(_handleSOSReceived);
    _modeSubscription = _sosService.onModeChanged.listen(_handleModeChanged);
    
    // Listen to device discovery
    _deviceFoundSubscription = _nearbyService.onDeviceFound.listen(_handleDeviceFound);
    _deviceLostSubscription = _nearbyService.onDeviceLost.listen(_handleDeviceLost);
    
    // Setup periodic status updates
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateStatus());
    
    return SOSAppState(
      isLocationEnabled: locationEnabled,
      connectedDevicesCount: _nearbyService.connectedEndpoints.length,
    );
  }

  /// Check location permission
  Future<bool> _checkLocationPermission() async {
    final position = await _locationService.getCurrentPosition();
    return position != null;
  }

  /// Handle incoming SOS broadcast
  void _handleSOSReceived(SOSBroadcast sosBroadcast) {
    final currentState = state.value;
    if (currentState == null) return;
    
    final updatedSOS = List<SOSBroadcast>.from(currentState.activeSOS);
    
    // Remove existing SOS from same device and add new one
    updatedSOS.removeWhere((sos) => sos.victimId == sosBroadcast.victimId);
    updatedSOS.add(sosBroadcast);
    
    state = AsyncValue.data(currentState.copyWith(activeSOS: updatedSOS));
    
    print('🚨 Received SOS from ${sosBroadcast.victimId}: ${sosBroadcast.message}');
  }

  /// Handle SOS mode changes
  void _handleModeChanged(SOSMode newMode) {
    final currentState = state.value;
    if (currentState == null) return;
    
    state = AsyncValue.data(currentState.copyWith(
      currentMode: newMode,
      isSOSActive: newMode == SOSMode.victim,
    ));
    
    print('🔄 SOS Mode changed to: $newMode');
  }

  /// Handle device discovery
  void _handleDeviceFound(Map<String, dynamic> deviceInfo) {
    final currentState = state.value;
    if (currentState == null) return;
    
    final updatedDevices = List<Map<String, dynamic>>.from(currentState.nearbyDevices);
    
    // Remove existing device with same ID and add updated one
    updatedDevices.removeWhere((device) => device['endpointId'] == deviceInfo['endpointId']);
    updatedDevices.add(deviceInfo);
    
    state = AsyncValue.data(currentState.copyWith(
      nearbyDevices: updatedDevices,
      connectedDevicesCount: _nearbyService.connectedEndpoints.length,
    ));
    
    print('📱 Device found: ${deviceInfo['endpointName']}');
  }

  /// Handle device lost
  void _handleDeviceLost(String endpointId) {
    final currentState = state.value;
    if (currentState == null) return;
    
    final updatedDevices = currentState.nearbyDevices
        .where((device) => device['endpointId'] != endpointId)
        .toList();
    
    state = AsyncValue.data(currentState.copyWith(
      nearbyDevices: updatedDevices,
      connectedDevicesCount: _nearbyService.connectedEndpoints.length,
    ));
    
    print('📱 Device lost: $endpointId');
  }

  /// Update status periodically
  Future<void> _updateStatus() async {
    final currentState = state.value;
    if (currentState == null) return;
    
    final locationEnabled = await _checkLocationPermission();
    String? lastLocation;
    
    if (locationEnabled) {
      lastLocation = await _locationService.getEmergencyLocationString();
    }
    
    state = AsyncValue.data(currentState.copyWith(
      isLocationEnabled: locationEnabled,
      lastLocation: lastLocation,
      connectedDevicesCount: _nearbyService.connectedEndpoints.length,
    ));
  }

  /// Activate SOS Victim Mode (RED)
  Future<void> activateVictimMode(String emergencyMessage) async {
    final currentState = state.value;
    if (currentState == null) return;
    
    try {
      await _sosService.activateVictimMode(emergencyMessage: emergencyMessage);
      state = AsyncValue.data(currentState.copyWith(error: null));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to activate SOS: $e'));
    }
  }

  /// Activate SOS Rescuer Mode (BLUE)
  Future<void> activateRescuerMode() async {
    final currentState = state.value;
    if (currentState == null) return;
    
    try {
      await _sosService.activateRescuerMode();
      state = AsyncValue.data(currentState.copyWith(error: null));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to activate Rescuer mode: $e'));
    }
  }

  /// Disable SOS Mode
  void disableSOSMode() {
    final currentState = state.value;
    if (currentState == null) return;
    
    _sosService.disableSOSMode();
    state = AsyncValue.data(currentState.copyWith(error: null));
  }

  /// Send emergency message to specific SOS victim
  Future<void> respondToSOS(SOSBroadcast sosBroadcast, String responseMessage) async {
    final currentState = state.value;
    if (currentState == null) return;
    
    try {
      // Create response message
      final message = EnhancedMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'rescuer',
        receiverId: sosBroadcast.victimId,
        content: '🔵 RESCUER RESPONSE: $responseMessage',
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.pending,
      );
      
      // Queue message
      await _messageQueue.insertPendingMessage(message);
      
      // Send via NearbyService
      await _nearbyService.sendMessage(message.content, type: 'rescuer_response');
      
      state = AsyncValue.data(currentState.copyWith(error: null));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to respond to SOS: $e'));
    }
  }

  /// Start device discovery
  Future<void> startDiscovery() async {
    final currentState = state.value;
    if (currentState == null) return;
    
    try {
      if (!await _nearbyService.initialize()) {
        state = AsyncValue.data(currentState.copyWith(error: 'Failed to initialize Nearby Service'));
        return;
      }
      
      await _nearbyService.startDiscovery();
      await _nearbyService.startAdvertising('SOS Device');
      
      state = AsyncValue.data(currentState.copyWith(error: null));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to start discovery: $e'));
    }
  }

  /// Stop device discovery
  Future<void> stopDiscovery() async {
    final currentState = state.value;
    if (currentState == null) return;
    
    try {
      await _nearbyService.stopDiscovery();
      await _nearbyService.stopAdvertising();
      
      state = AsyncValue.data(currentState.copyWith(
        nearbyDevices: [],
        connectedDevicesCount: 0,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to stop discovery: $e'));
    }
  }

  /// Clear error message
  void clearError() {
    final currentState = state.value;
    if (currentState == null) return;
    
    state = AsyncValue.data(currentState.copyWith(error: null));
  }

  void dispose() {
    _sosSubscription?.cancel();
    _modeSubscription?.cancel();
    _deviceFoundSubscription?.cancel();
    _deviceLostSubscription?.cancel();
    _statusUpdateTimer?.cancel();
  }
}

/// Provider for SOS state management
final sosProvider = AsyncNotifierProvider<SOSNotifier, SOSAppState>(() {
  return SOSNotifier();
});

/// Provider for current SOS mode
final currentSOSModeProvider = Provider<SOSMode>((ref) {
  final sosState = ref.watch(sosProvider);
  return sosState.when(
    data: (state) => state.currentMode,
    loading: () => SOSMode.disabled,
    error: (_, __) => SOSMode.disabled,
  );
});

/// Provider for active SOS broadcasts
final activeSOSProvider = Provider<List<SOSBroadcast>>((ref) {
  final sosState = ref.watch(sosProvider);
  return sosState.when(
    data: (state) => state.activeSOS,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for nearby devices
final nearbyDevicesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final sosState = ref.watch(sosProvider);
  return sosState.when(
    data: (state) => state.nearbyDevices,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for connection status
final connectionStatusProvider = Provider<int>((ref) {
  final sosState = ref.watch(sosProvider);
  return sosState.when(
    data: (state) => state.connectedDevicesCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});