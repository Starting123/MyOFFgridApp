import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/background_discovery_service.dart';

class BackgroundServiceManager {
  static final BackgroundServiceManager _instance = BackgroundServiceManager._internal();
  static BackgroundServiceManager get instance => _instance;

  BackgroundServiceManager._internal();
  
  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  // Helper method to check if background service is running
  Future<bool> checkIfServiceRunning() async {
    _isServiceRunning = await FlutterForegroundTask.isRunningService;
    return _isServiceRunning;
  }

  // Start the background service if not already running
  Future<void> startServiceIfNeeded() async {
    final isRunning = await checkIfServiceRunning();
    if (!isRunning) {
      await BackgroundDiscoveryService.instance.startDiscoveryService();
      _isServiceRunning = true;
    }
  }

  // Stop the background service if running
  Future<void> stopService() async {
    final isRunning = await checkIfServiceRunning();
    if (isRunning) {
      await BackgroundDiscoveryService.instance.stopDiscoveryService();
      _isServiceRunning = false;
    }
  }
}