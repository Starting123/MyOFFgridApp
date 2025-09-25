import 'dart:async';
import 'dart:math';
import '../models/enhanced_message_model.dart';
import '../services/nearby_service.dart';
import '../services/location_service.dart';
import '../services/enhanced_message_queue_service.dart';

enum SOSMode {
  victim,    // RED mode - person in distress
  rescuer,   // BLUE mode - person helping
  disabled   // Normal chat mode
}

class SOSBroadcastService {
  static final SOSBroadcastService _instance = SOSBroadcastService._internal();
  static SOSBroadcastService get instance => _instance;
  SOSBroadcastService._internal();

  final NearbyService _nearbyService = NearbyService.instance;
  final LocationService _locationService = LocationService.instance;
  final MessageQueueService _messageQueue = MessageQueueService.instance;

  SOSMode _currentMode = SOSMode.disabled;
  Timer? _sosTimer;
  Timer? _locationTimer;
  String? _activeSosId;
  
  // Stream controllers for SOS events
  final StreamController<SOSBroadcast> _sosStreamController = StreamController<SOSBroadcast>.broadcast();
  final StreamController<SOSMode> _modeStreamController = StreamController<SOSMode>.broadcast();

  Stream<SOSBroadcast> get onSOSReceived => _sosStreamController.stream;
  Stream<SOSMode> get onModeChanged => _modeStreamController.stream;
  SOSMode get currentMode => _currentMode;

  /// Activate SOS victim mode (RED)
  Future<void> activateVictimMode({
    required String emergencyMessage,
    Duration broadcastInterval = const Duration(minutes: 2),
  }) async {
    print('🚨 Activating SOS Victim Mode (RED)');
    
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
    
    print('🚨 SOS Victim Mode activated - Broadcasting every ${broadcastInterval.inMinutes} minutes');
  }

  /// Activate SOS rescuer mode (BLUE)
  Future<void> activateRescuerMode() async {
    print('🔵 Activating SOS Rescuer Mode (BLUE)');
    
    _currentMode = SOSMode.rescuer;
    _modeStreamController.add(_currentMode);
    
    // Rescuers listen for SOS broadcasts and send acknowledgments
    print('🔵 SOS Rescuer Mode activated - Listening for SOS signals');
  }

  /// Disable SOS mode (return to normal chat)
  void disableSOSMode() {
    print('⚪ Disabling SOS Mode - Returning to normal chat');
    
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
      final sosMessage = EnhancedMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_device',
        content: _formatSOSMessage(sosBroadcast),
        timestamp: DateTime.now(),
        type: MessageType.sos,
        status: MessageStatus.pending,
        isSOS: true,
        isEncrypted: false, // Emergency messages are not encrypted
        latitude: sosBroadcast.latitude,
        longitude: sosBroadcast.longitude,
      );

      // Save to database
      await _messageQueue.insertPendingMessage(sosMessage);

      // Broadcast via NearbyService
      await _nearbyService.sendMessage(
        _formatSOSMessage(sosBroadcast),
        type: 'sos_broadcast'
      );

      print('🚨 SOS Broadcast sent: ${sosBroadcast.message}');
      
    } catch (e) {
      print('❌ Failed to broadcast SOS: $e');
    }
  }

  /// Update location in ongoing SOS broadcast
  Future<void> _updateLocationBroadcast() async {
    if (_activeSosId == null) return;
    
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        await _nearbyService.sendMessage(
          'SOS_LOCATION_UPDATE|${_activeSosId}|${position.latitude}|${position.longitude}|${DateTime.now().toIso8601String()}',
          type: 'sos_location'
        );
        print('📍 SOS Location updated: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('❌ Failed to update SOS location: $e');
    }
  }

  /// Handle incoming SOS broadcast
  void handleIncomingSOSBroadcast(String message) {
    try {
      print('🚨 Received SOS Broadcast: $message');
      
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
      print('❌ Error handling SOS broadcast: $e');
    }
  }

  /// Send acknowledgment to SOS victim
  Future<void> _sendSOSAcknowledgment(SOSBroadcast sosBroadcast) async {
    try {
      final ackMessage = 'SOS_ACK|${sosBroadcast.id}|RESCUER_RESPONDING|${DateTime.now().toIso8601String()}';
      await _nearbyService.sendMessage(ackMessage, type: 'sos_ack');
      print('🔵 SOS Acknowledgment sent for: ${sosBroadcast.id}');
    } catch (e) {
      print('❌ Failed to send SOS acknowledgment: $e');
    }
  }

  /// Handle SOS acknowledgment (for victims)
  void _handleSOSAcknowledgment(String message) {
    print('✅ Received SOS Acknowledgment: $message');
    // TODO: Show UI notification that help is coming
  }

  /// Handle SOS location update
  void _handleSOSLocationUpdate(String message) {
    print('📍 Received SOS Location Update: $message');
    // TODO: Update victim's location on rescuer's map
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

  /// Get device battery level (placeholder)
  Future<int?> _getBatteryLevel() async {
    // TODO: Implement battery level detection
    return 85; // Mock battery level
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