import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/enhanced_db.dart';
import '../services/nearby_service.dart';
import '../services/enhanced_message_queue_service.dart';
import '../services/sos_broadcast_service.dart';
import '../services/enhanced_cloud_sync.dart';
import '../services/encryption_service.dart';
import '../services/location_service.dart';


// Core Service Providers
final enhancedDatabaseProvider = Provider<EnhancedAppDatabase>((ref) {
  return EnhancedAppDatabase();
});

final nearbyServiceProvider = Provider<NearbyService>((ref) {
  return NearbyService.instance;
});

final messageQueueServiceProvider = Provider<MessageQueueService>((ref) {
  return MessageQueueService.instance;
});

final sosServiceProvider = Provider<SOSBroadcastService>((ref) {
  return SOSBroadcastService.instance;
});

final cloudSyncProvider = Provider<EnhancedCloudSync>((ref) {
  return EnhancedCloudSync.instance;
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService.instance;
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

// App State Providers
final appConnectionStatusProvider = Provider<bool>((ref) {
  final nearbyService = ref.watch(nearbyServiceProvider);
  return nearbyService.connectedEndpoints.isNotEmpty;
});

final cloudSyncStatusProvider = Provider<bool>((ref) {
  final cloudSync = ref.watch(cloudSyncProvider);
  return cloudSync.isOnline;
});

// Message Statistics Provider
final messageStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final cloudSync = ref.watch(cloudSyncProvider);
  return await cloudSync.getSyncStats();
});

// Combined App State Provider
class AppState {
  final bool isConnected;
  final bool isOnline;
  final int messageCount;
  final SOSMode sosMode;
  final bool hasLocationPermission;
  final String? error;

  const AppState({
    this.isConnected = false,
    this.isOnline = false,
    this.messageCount = 0,
    this.sosMode = SOSMode.disabled,
    this.hasLocationPermission = false,
    this.error,
  });

  AppState copyWith({
    bool? isConnected,
    bool? isOnline,
    int? messageCount,
    SOSMode? sosMode,
    bool? hasLocationPermission,
    String? error,
  }) {
    return AppState(
      isConnected: isConnected ?? this.isConnected,
      isOnline: isOnline ?? this.isOnline,
      messageCount: messageCount ?? this.messageCount,
      sosMode: sosMode ?? this.sosMode,
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      error: error ?? this.error,
    );
  }
}

final appStateProvider = FutureProvider<AppState>((ref) async {
  final nearbyService = ref.watch(nearbyServiceProvider);
  final cloudSync = ref.watch(cloudSyncProvider);
  final locationService = ref.watch(locationServiceProvider);
  final sosService = ref.watch(sosServiceProvider);
  final messageQueue = ref.watch(messageQueueServiceProvider);

  // Get all the current states
  final isConnected = nearbyService.connectedEndpoints.isNotEmpty;
  final isOnline = cloudSync.isOnline;
  final messages = await messageQueue.getAllMessages();
  final messageCount = messages.length;
  final sosMode = sosService.currentMode;
  
  // Check location permission
  final position = await locationService.getCurrentPosition();
  final hasLocationPermission = position != null;

  return AppState(
    isConnected: isConnected,
    isOnline: isOnline,
    messageCount: messageCount,
    sosMode: sosMode,
    hasLocationPermission: hasLocationPermission,
  );
});

// Device Registration Provider
final deviceRegistryProvider = Provider<DeviceRegistryService>((ref) {
  return DeviceRegistryService.instance;
});

// Auto-sync Provider - Manages automatic cloud synchronization
final autoSyncProvider = Provider<void>((ref) {
  final cloudSync = ref.watch(cloudSyncProvider);
  
  // Start auto sync when provider is initialized
  cloudSync.startAutoSync();
  
  // Cleanup when provider is disposed
  ref.onDispose(() {
    cloudSync.stopAutoSync();
  });
});

// Background service management
final backgroundServiceProvider = Provider<void>((ref) {
  // Initialize background services when needed
  ref.onDispose(() {
    // Cleanup resources when app is closing
    final nearbyService = ref.read(nearbyServiceProvider);
    final cloudSync = ref.read(cloudSyncProvider);
    final sosService = ref.read(sosServiceProvider);
    
    nearbyService.disconnect();
    cloudSync.dispose();
    sosService.dispose();
  });
});