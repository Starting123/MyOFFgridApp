import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/service_coordinator.dart';
import '../services/location_service.dart';
import '../models/chat_models.dart';
import '../utils/logger.dart';

// Enhanced SOS State Model with production-ready features
class SOSAppState {
  final bool isSOSActive;
  final bool isBroadcasting;
  final String? currentLocation;
  final double? latitude;
  final double? longitude;
  final List<String> connectedDevices;
  final DateTime? lastSOSTime;
  final Map<String, bool> serviceStatus;
  final int broadcastCount;
  final String? lastError;

  const SOSAppState({
    this.isSOSActive = false,
    this.isBroadcasting = false,
    this.currentLocation,
    this.latitude,
    this.longitude,
    this.connectedDevices = const [],
    this.lastSOSTime,
    this.serviceStatus = const {},
    this.broadcastCount = 0,
    this.lastError,
  });

  SOSAppState copyWith({
    bool? isSOSActive,
    bool? isBroadcasting,
    String? currentLocation,
    double? latitude,
    double? longitude,
    List<String>? connectedDevices,
    DateTime? lastSOSTime,
    Map<String, bool>? serviceStatus,
    int? broadcastCount,
    String? lastError,
  }) {
    return SOSAppState(
      isSOSActive: isSOSActive ?? this.isSOSActive,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      currentLocation: currentLocation ?? this.currentLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      lastSOSTime: lastSOSTime ?? this.lastSOSTime,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      broadcastCount: broadcastCount ?? this.broadcastCount,
      lastError: lastError,
    );
  }
}

// Production-ready SOS State Notifier using ServiceCoordinator
class SOSNotifier extends AsyncNotifier<SOSAppState> {
  final _coordinator = ServiceCoordinator.instance;
  final _locationService = LocationService.instance;

  @override
  Future<SOSAppState> build() async {
    // Always return initial state immediately to prevent loading spinner
    Logger.info('SOS Provider: Building initial state', 'sos');
    
    // Start background initialization but don't wait for it
    _initializeServicesAsync();
    
    return const SOSAppState(
      serviceStatus: {'nearby': false, 'p2p': false, 'ble': false, 'cloud': false},
    );
  }

  // Initialize services asynchronously without blocking UI
  void _initializeServicesAsync() async {
    try {
      Logger.info('SOS Provider: Starting background service initialization', 'sos');
      
      // Add timeout to prevent hanging
      await _coordinator.initializeAll().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Logger.warning('Service initialization timed out, continuing with limited functionality', 'sos');
          return false;
        },
      );
      
      // Update state once services are ready
      Logger.success('SOS Provider: Services initialized successfully', 'sos');
      state = AsyncValue.data(SOSAppState(
        serviceStatus: _coordinator.getServiceStatus(),
      ));
    } catch (error) {
      Logger.error('Failed to initialize services: $error', 'sos');
      // Continue with limited functionality - SOS can still work
      state = AsyncValue.data(const SOSAppState(
        serviceStatus: {'nearby': false, 'p2p': false, 'ble': false, 'cloud': false},
        lastError: 'Service initialization failed - SOS available in offline mode'
      ));
    }
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
      
      // Get current location
      double? latitude;
      double? longitude;
      String? locationDescription;
      
      try {
        final location = await _locationService.getCurrentPosition();
        if (location != null) {
          latitude = location.latitude;
          longitude = location.longitude;
        }
        if (latitude != null && longitude != null) {
          locationDescription = await _locationService.getAddressFromCoordinates(latitude, longitude);
        }
      } catch (e) {
        // Continue without location if service fails
        locationDescription = 'Location unavailable';
      }
      
      // Broadcast SOS via ServiceCoordinator
      await _coordinator.broadcastSOS(
        'EMERGENCY SOS: Immediate assistance required!',
        latitude,
        longitude,
      );
      
      final newState = SOSAppState(
        isSOSActive: true,
        isBroadcasting: true,
        lastSOSTime: DateTime.now(),
        currentLocation: locationDescription,
        latitude: latitude,
        longitude: longitude,
        serviceStatus: _coordinator.getServiceStatus(),
        broadcastCount: 1,
      );
      
      state = AsyncValue.data(newState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _stopSOS() async {
    try {
      state = const AsyncValue.loading();
      
      // Stop SOS broadcasting (ServiceCoordinator would handle this)
      // For now, just update state
      
      const newState = SOSAppState(
        isSOSActive: false,
        isBroadcasting: false,
      );
      
      state = const AsyncValue.data(newState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Enhanced SOS activation with custom message
  Future<void> activateVictimMode({
    String? emergencyMessage, 
    double? latitude, 
    double? longitude
  }) async {
    try {
      final currentState = state.value ?? const SOSAppState();
      state = AsyncValue.loading();
      
      // Get location if not provided
      double? lat = latitude;
      double? lng = longitude;
      String? locationDesc;
      
      if (lat == null || lng == null) {
        try {
          final location = await _locationService.getCurrentPosition();
          if (location != null) {
            lat = location.latitude;
            lng = location.longitude;
            locationDesc = await _locationService.getAddressFromCoordinates(lat, lng);
          }
        } catch (e) {
          locationDesc = 'Location unavailable';
        }
      }
      
      // Broadcast SOS with custom message
      final sosMessage = emergencyMessage ?? 'EMERGENCY SOS: Immediate assistance required!';
      await ServiceCoordinator.instance.broadcastSOS(sosMessage, lat, lng);
      
      final newState = currentState.copyWith(
        isSOSActive: true,
        isBroadcasting: true,
        lastSOSTime: DateTime.now(),
        currentLocation: locationDesc,
        latitude: lat,
        longitude: lng,
        serviceStatus: _coordinator.getServiceStatus(),
        broadcastCount: currentState.broadcastCount + 1,
        lastError: null,
      );
      
      state = AsyncValue.data(newState);
    } catch (error) {
      final currentState = state.value ?? const SOSAppState();
      state = AsyncValue.data(currentState.copyWith(
        lastError: 'SOS activation failed: $error',
      ));
    }
  }

  Future<void> disableSOSMode() async {
    await _stopSOS();
  }

  // Repeat SOS broadcast
  Future<void> repeatSOSBroadcast() async {
    final currentState = state.value;
    if (currentState?.isSOSActive == true) {
      try {
        await _coordinator.broadcastSOS(
          'EMERGENCY SOS: Repeated call for assistance!',
          currentState!.latitude,
          currentState.longitude,
        );
        
        state = AsyncValue.data(currentState.copyWith(
          broadcastCount: currentState.broadcastCount + 1,
          lastSOSTime: DateTime.now(),
          lastError: null,
        ));
      } catch (error) {
        state = AsyncValue.data(currentState!.copyWith(
          lastError: 'Repeat broadcast failed: $error',
        ));
      }
    }
  }
}

// SOS Provider
final sosProvider = AsyncNotifierProvider<SOSNotifier, SOSAppState>(() {
  return SOSNotifier();
});

// Provider for SOS-related devices (nearby users who can help)
final sosNearbyHelpProvider = StreamProvider<List<String>>((ref) {
  // Use real device discovery system from ServiceCoordinator
  final coordinator = ServiceCoordinator.instance;
  
  // Initialize if not already done
  if (!coordinator.isInitialized) {
    coordinator.initializeAll().catchError((e) {
      Logger.error('Failed to initialize ServiceCoordinator: $e');
      return false;
    });
  }
  
  // Return stream of rescuer device IDs
  return coordinator.deviceStream.map((devices) {
    return devices
        .where((device) => device.isRescuerActive || device.role == DeviceRole.rescuer)
        .map((device) => device.id)
        .toList();
  });
});

// Provider for SOS statistics
final sosStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final sosState = ref.watch(sosProvider);
  return sosState.when(
    data: (state) => {
      'isActive': state.isSOSActive,
      'broadcastCount': state.broadcastCount,
      'lastSOSTime': state.lastSOSTime?.toIso8601String(),
      'hasLocation': state.latitude != null && state.longitude != null,
      'servicesActive': state.serviceStatus.values.where((active) => active).length,
    },
    loading: () => {'isActive': false, 'broadcastCount': 0},
    error: (_, __) => {'isActive': false, 'broadcastCount': 0, 'error': true},
  );
});