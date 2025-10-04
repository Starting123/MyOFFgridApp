import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/enhanced_message_model.dart';
import '../services/nearby_service_fixed.dart' as NearbyServiceFixed;
import '../services/location_service.dart';
import '../services/enhanced_message_queue_service.dart';
import '../services/local_db_service.dart';
import '../utils/logger.dart';

enum SOSMode {
  victim,    // RED mode - person in distress
  rescuer,   // BLUE mode - person helping
  disabled   // Normal chat mode
}

enum SOSStatus {
  inactive,
  broadcasting,
  rescuerResponding,
  rescueInProgress,
  resolved
}

class SOSBroadcastService {
  static final SOSBroadcastService _instance = SOSBroadcastService._internal();
  static SOSBroadcastService get instance => _instance;
  SOSBroadcastService._internal();

  final NearbyServiceFixed.NearbyService _nearbyService = NearbyServiceFixed.NearbyService.instance;
  final LocationService _locationService = LocationService.instance;
  final MessageQueueService _messageQueue = MessageQueueService.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  SOSMode _currentMode = SOSMode.disabled;
  SOSStatus _currentSOSStatus = SOSStatus.inactive;
  Timer? _sosTimer;
  Timer? _locationTimer;
  String? _activeSosId;
  Function(Map<String, dynamic>)? _onStatusChanged;
  
  // Stream controllers for SOS events
  final StreamController<SOSBroadcast> _sosStreamController = StreamController<SOSBroadcast>.broadcast();
  final StreamController<SOSMode> _modeStreamController = StreamController<SOSMode>.broadcast();

  Stream<SOSBroadcast> get onSOSReceived => _sosStreamController.stream;
  Stream<SOSMode> get onModeChanged => _modeStreamController.stream;
  SOSMode get currentMode => _currentMode;

  /// Set callback for status changes (for UI updates)
  void setStatusChangeCallback(Function(Map<String, dynamic>) callback) {
    _onStatusChanged = callback;
  }

  /// Activate SOS victim mode (RED)
  Future<void> activateVictimMode({
    required String emergencyMessage,
    Duration broadcastInterval = const Duration(minutes: 2),
  }) async {
    Logger.warning('Activating SOS Victim Mode (RED)', 'sos');
    
    _currentMode = SOSMode.victim;
    _modeStreamController.add(_currentMode);
    
    // Generate unique SOS ID
    _activeSosId = 'SOS_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    
    // Start periodic SOS broadcasting
    _sosTimer = Timer.periodic(broadcastInterval, (_) async {
      await _broadcastSOS(emergencyMessage);
    });
    
    // Start location updates every 30 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _updateLocationBroadcast();
    });
    
    // Send initial SOS broadcast
    await _broadcastSOS(emergencyMessage);
    
    Logger.success('SOS Victim Mode activated - Broadcasting every ${broadcastInterval.inMinutes} minutes', 'sos');
  }

  /// Activate SOS rescuer mode (BLUE)
  Future<void> activateRescuerMode() async {
    Logger.info('Activating SOS Rescuer Mode (BLUE)', 'sos');
    
    _currentMode = SOSMode.rescuer;
    _modeStreamController.add(_currentMode);
    
    // Rescuers listen for SOS broadcasts and send acknowledgments
    Logger.success('SOS Rescuer Mode activated - Listening for SOS signals', 'sos');
  }

  /// Disable SOS mode (return to normal chat)
  void disableSOSMode() {
    Logger.info('Disabling SOS Mode - Returning to normal chat', 'sos');
    
    _currentMode = SOSMode.disabled;
    _modeStreamController.add(_currentMode);
    
    _sosTimer?.cancel();
    _locationTimer?.cancel();
    _sosTimer = null;
    _locationTimer = null;
    _activeSosId = null;
  }

  /// Broadcast SOS signal
  Future<void> _broadcastSOS(String message) async {
    try {
      // Get current location
      final position = await _locationService.getCurrentPosition();
      
      final sosBroadcast = SOSBroadcast(
        id: _activeSosId!,
        victimId: 'current_device', // In real app, use device ID
        message: message,
        latitude: position?.latitude,
        longitude: position?.longitude,
        timestamp: DateTime.now(),
        batteryLevel: await _getBatteryLevel(),
        isActive: true,
      );

      // Create SOS message
      final sosMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_device',
        senderName: 'Emergency Device',
        receiverId: 'broadcast',
        content: _formatSOSMessage(sosBroadcast),
        timestamp: DateTime.now(),
        type: MessageType.sos,
        status: MessageStatus.sending,
        latitude: sosBroadcast.latitude,
        longitude: sosBroadcast.longitude,
        isEmergency: true,
      );

      // Save to database and queue
      _messageQueue.enqueueMessage(sosMessage);
      await _localDb.insertMessage(sosMessage);

      // Broadcast via NearbyService
      await _nearbyService.sendMessageLegacy(
        _formatSOSMessage(sosBroadcast),
        type: 'sos_broadcast'
      );

      Logger.warning('SOS Broadcast sent: ${sosBroadcast.message}', 'sos');
      
    } catch (e) {
      Logger.error('Failed to broadcast SOS: $e', 'sos');
    }
  }

  /// Update location in ongoing SOS broadcast
  Future<void> _updateLocationBroadcast() async {
    if (_activeSosId == null) return;
    
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        await _nearbyService.sendMessageLegacy(
          'SOS_LOCATION_UPDATE|${_activeSosId}|${position.latitude}|${position.longitude}|${DateTime.now().toIso8601String()}',
          type: 'sos_location'
        );
        Logger.info('SOS Location updated: ${position.latitude}, ${position.longitude}', 'sos');
      }
    } catch (e) {
      Logger.error('Failed to update SOS location: $e', 'sos');
    }
  }

  /// Handle incoming SOS broadcast
  void handleIncomingSOSBroadcast(String message) {
    try {
      Logger.warning('Received SOS Broadcast: $message', 'sos');
      
      if (message.startsWith('SOS_BROADCAST|')) {
        final sosBroadcast = _parseSOSBroadcast(message);
        _sosStreamController.add(sosBroadcast);
        
        // If in rescuer mode, send acknowledgment
        if (_currentMode == SOSMode.rescuer) {
          _sendSOSAcknowledgment(sosBroadcast);
        }
      } else if (message.startsWith('SOS_LOCATION_UPDATE|')) {
        _handleSOSLocationUpdate(message);
      } else if (message.startsWith('SOS_ACK|')) {
        _handleSOSAcknowledgment(message);
      }
      
    } catch (e) {
      Logger.error('Error handling SOS broadcast: $e', 'sos');
    }
  }

  /// Send acknowledgment to SOS victim
  Future<void> _sendSOSAcknowledgment(SOSBroadcast sosBroadcast) async {
    try {
      final ackMessage = 'SOS_ACK|${sosBroadcast.id}|RESCUER_RESPONDING|${DateTime.now().toIso8601String()}';
      await _nearbyService.sendMessageLegacy(ackMessage, type: 'sos_ack');
      Logger.info('SOS Acknowledgment sent for: ${sosBroadcast.id}', 'sos');
    } catch (e) {
      Logger.error('Failed to send SOS acknowledgment: $e', 'sos');
    }
  }

  /// Handle SOS acknowledgment (for victims)
  void _handleSOSAcknowledgment(String message) {
    Logger.success('Received SOS Acknowledgment: $message', 'sos');
    
    // Show UI notification that help is coming
    _showSystemNotification(
      title: 'Help is Coming!',
      body: 'A rescuer has acknowledged your SOS signal and is on the way.',
      isUrgent: true,
    );
    
    // Update SOS status to show rescuer is responding
    _currentSOSStatus = SOSStatus.rescuerResponding;
    _updateSOSUI();
  }

  /// Handle SOS location update
  void _handleSOSLocationUpdate(String message) {
    Logger.info('Received SOS Location Update: $message', 'sos');
    
    try {
      final data = jsonDecode(message);
      final latitude = data['latitude']?.toDouble();
      final longitude = data['longitude']?.toDouble();
      final rescuerName = data['rescuerName'] ?? 'Rescuer';
      
      if (latitude != null && longitude != null) {
        // Update rescuer location on victim's map interface
        _updateRescuerLocationOnMap(
          rescuerName: rescuerName,
          latitude: latitude,
          longitude: longitude,
        );
        
        // Show notification with rescuer proximity
        _showSystemNotification(
          title: 'Rescuer Location Update',
          body: '$rescuerName is approaching your location.',
          isUrgent: false,
        );
      }
    } catch (e) {
      Logger.error('Failed to parse SOS location update: $e', 'sos');
    }
  }

  /// Show system notification to user
  void _showSystemNotification({
    required String title,
    required String body,
    bool isUrgent = false,
  }) {
    // In a real app, this would use flutter_local_notifications
    // For now, we'll use the status callback to update UI
    Logger.info('NOTIFICATION: $title - $body', 'sos');
    
    // Trigger UI update through status callback
    _onStatusChanged?.call({
      'type': 'notification',
      'title': title,
      'body': body,
      'urgent': isUrgent,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Update rescuer location on map (called from location updates)
  void _updateRescuerLocationOnMap({
    required String rescuerName,
    required double latitude,
    required double longitude,
  }) {
    Logger.info('Updating rescuer location: $rescuerName at ($latitude, $longitude)', 'sos');
    
    // Update rescuer location in the UI
    _onStatusChanged?.call({
      'type': 'rescuer_location',
      'rescuer_name': rescuerName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Update SOS UI with current status
  void _updateSOSUI() {
    _onStatusChanged?.call({
      'type': 'sos_status',
      'status': _currentSOSStatus.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Format SOS message for transmission
  String _formatSOSMessage(SOSBroadcast broadcast) {
    return 'SOS_BROADCAST|${broadcast.id}|${broadcast.message}|${broadcast.latitude ?? 'unknown'}|${broadcast.longitude ?? 'unknown'}|${broadcast.timestamp.toIso8601String()}|${broadcast.batteryLevel ?? 'unknown'}';
  }

  /// Parse incoming SOS broadcast
  SOSBroadcast _parseSOSBroadcast(String message) {
    final parts = message.split('|');
    if (parts.length >= 6) {
      return SOSBroadcast(
        id: parts[1],
        victimId: 'remote_device',
        message: parts[2],
        latitude: double.tryParse(parts[3]),
        longitude: double.tryParse(parts[4]),
        timestamp: DateTime.tryParse(parts[5]) ?? DateTime.now(),
        batteryLevel: int.tryParse(parts[6]),
        isActive: true,
      );
    }
    throw Exception('Invalid SOS broadcast format');
  }

  /// Get device battery level
  Future<int?> _getBatteryLevel() async {
    try {
      // For now, return null to indicate battery level not available
      // In a real implementation, you would use a battery plugin like 'battery_plus'
      // Example: Battery battery = Battery(); return await battery.batteryLevel;
      return null;
    } catch (e) {
      Logger.error('Error getting battery level: $e', 'sos');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _sosTimer?.cancel();
    _locationTimer?.cancel();
    _sosStreamController.close();
    _modeStreamController.close();
  }
}

/// SOS Broadcast data model
class SOSBroadcast {
  final String id;
  final String victimId;
  final String message;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final int? batteryLevel;
  final bool isActive;

  const SOSBroadcast({
    required this.id,
    required this.victimId,
    required this.message,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.batteryLevel,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'victimId': victimId,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'batteryLevel': batteryLevel,
      'isActive': isActive,
    };
  }

  factory SOSBroadcast.fromJson(Map<String, dynamic> json) {
    return SOSBroadcast(
      id: json['id'],
      victimId: json['victimId'],
      message: json['message'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      batteryLevel: json['batteryLevel'],
      isActive: json['isActive'] ?? true,
    );
  }
}