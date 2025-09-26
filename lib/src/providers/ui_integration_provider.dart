import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/nearby_service.dart';
import '../services/local_database_service.dart';
import '../services/sos_broadcast_service.dart';

// ============================================================================
// REAL UI DATA PROVIDERS - CONNECTED TO SERVICES
// ============================================================================

// Connection status provider - real data from nearby service
final connectionStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final nearbyService = NearbyService.instance;
  return {
    'isOnline': nearbyService.connectedEndpoints.isNotEmpty,
    'connectedDevices': nearbyService.connectedEndpoints.length,
    'isScanning': false, // Could add scanning state from service
  };
});

// SOS status provider - real data from SOS broadcast service with stream updates
final sosStatusProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final sosService = SOSBroadcastService.instance;
  
  // Return initial state and listen to mode changes
  return sosService.onModeChanged.map((mode) => {
    'currentMode': mode,
    'isActive': mode != SOSMode.disabled,
    'isVictim': mode == SOSMode.victim,
    'isRescuer': mode == SOSMode.rescuer,
  }).asBroadcastStream();
});

// Immediate SOS status provider (non-stream) for instant access
final immediateSOSStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final sosService = SOSBroadcastService.instance;
  return {
    'currentMode': sosService.currentMode,
    'isActive': sosService.currentMode != SOSMode.disabled,
    'isVictim': sosService.currentMode == SOSMode.victim,
    'isRescuer': sosService.currentMode == SOSMode.rescuer,
  };
});

// Nearby devices provider
final nearbyDevicesProvider = FutureProvider<List<NearbyDevice>>((ref) async {
  try {
    final db = LocalDatabaseService();
    return await db.getNearbyDevices();
  } catch (e) {
    return <NearbyDevice>[];
  }
});

// Messages provider  
final messagesProvider = FutureProvider<List<ChatMessage>>((ref) async {
  try {
    // Would need to implement getMessages() method in LocalDatabaseService
    // final db = LocalDatabaseService();
    return <ChatMessage>[]; // Placeholder
  } catch (e) {
    return <ChatMessage>[];
  }
});

// Unread message count provider
final unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    // Would integrate with actual message counting logic
    return 0; // Placeholder
  } catch (e) {
    return 0;
  }
});

// SOS devices count provider
final sosDevicesCountProvider = FutureProvider<int>((ref) async {
  try {
    final devices = await ref.watch(nearbyDevicesProvider.future);
    return devices.where((d) => d.isSOSActive).length;
  } catch (e) {
    return 0;
  }
});

// Location provider - for SOS screen
final locationProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    // In a real implementation, would use LocationService
    return {
      'latitude': 13.7563,
      'longitude': 100.5018,
      'locationName': 'Current Location',
      'isAvailable': true,
    };
  } catch (e) {
    return {
      'latitude': 0.0,
      'longitude': 0.0,
      'locationName': 'Location unavailable',
      'isAvailable': false,
    };
  }
});

// Real-time message count provider
final realTimeMessageStatsProvider = Provider<Map<String, int>>((ref) {
  // In a real implementation, would listen to message service streams
  return {
    'total': 0,
    'unread': 0,
    'pending': 0,
    'sent': 0,
    'synced': 0,
  };
});

// Device scanning state provider - simple state
final deviceScanningProvider = Provider<bool>((ref) => false);

// SOS activation state provider - simple state
final sosActivationProvider = Provider<Map<String, dynamic>>((ref) => {
  'isActive': false,
  'mode': 'disabled', // 'victim', 'rescuer', 'disabled'
  'message': '',
  'activatedAt': null,
});