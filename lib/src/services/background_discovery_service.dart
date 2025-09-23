import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/nearby_service.dart';

// The callback function for background task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(DiscoveryTaskHandler());
}

// The task handler class
class DiscoveryTaskHandler extends TaskHandler {
  Timer? _discoveryTimer;
  Timer? _advertisingTimer;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Initialize nearby service
    final nearbyService = NearbyService.instance;
    await nearbyService.initialize();

    // Start periodic discovery and advertising
    _discoveryTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await nearbyService.stopDiscovery();
      await nearbyService.startDiscovery();
    });

    _advertisingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await nearbyService.stopAdvertising();
      await nearbyService.startAdvertising('Device-${DateTime.now().millisecondsSinceEpoch}');
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cleanup
    _discoveryTimer?.cancel();
    _advertisingTimer?.cancel();
    await NearbyService.instance.disconnect();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Could be used to send events/status back to UI
  }
}

// Helper class to manage foreground task
class BackgroundDiscoveryService {
  static final BackgroundDiscoveryService _instance = BackgroundDiscoveryService._internal();
  static BackgroundDiscoveryService get instance => _instance;

  BackgroundDiscoveryService._internal();

  Future<void> startDiscoveryService() async {
    // Required for iOS
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();

    // Configure the foreground task
    await _initForegroundTask();

    // Start the task
    await FlutterForegroundTask.startService(
      notificationTitle: 'Off-Grid SOS',
      notificationText: 'Looking for nearby devices...',
      callback: startCallback,
    );
  }

  Future<void> stopDiscoveryService() async {
    await FlutterForegroundTask.stopService();
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'offgrid_sos_discovery',
        channelName: 'Device Discovery',
        channelDescription: 'Running device discovery in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          // Add buttons to notification if needed
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // Milliseconds
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
}