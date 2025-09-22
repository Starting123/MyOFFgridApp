import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

class NearbyService {
  static final NearbyService _instance = NearbyService._internal();
  static NearbyService get instance => _instance;

  NearbyService._internal();

  final Nearby _nearby = Nearby();
  final String _serviceId = 'com.offgrid.sos';
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  final Set<String> _connectedEndpoints = {};

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  // Initialize and request permissions
  Future<bool> initialize() async {
    if (!await _nearby.checkLocationEnabled()) {
      return false;
    }
    
    final permissionStatus = await _nearby.askLocationPermission();
    if (!permissionStatus) {
      return false;
    }
    
    return true;
  }

  // Start advertising as an SOS device
  Future<void> startAdvertising(String deviceName) async {
    if (_isAdvertising) return;

    try {
      await _nearby.startAdvertising(
        deviceName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      _isAdvertising = true;
      debugPrint('Started advertising as: $deviceName');
    } catch (e) {
      debugPrint('Error advertising: $e');
      rethrow;
    }
  }

  // Start discovering nearby devices
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    try {
      await _nearby.startDiscovery(
        _serviceId,
        Strategy.P2P_CLUSTER,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );
      _isDiscovering = true;
      debugPrint('Started discovery');
    } catch (e) {
      debugPrint('Error discovering: $e');
      rethrow;
    }
  }

  // Send SOS broadcast to all connected endpoints
  Future<void> broadcastSOS({
    required String deviceId,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    final payload = {
      'type': 'sos',
      'deviceId': deviceId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    final jsonData = jsonEncode(payload);
    final bytes = Uint8List.fromList(utf8.encode(jsonData));

    for (final endpointId in _connectedEndpoints) {
      try {
        await _nearby.sendBytesPayload(endpointId, bytes);
      } catch (e) {
        debugPrint('Error sending to endpoint $endpointId: $e');
      }
    }
  }

  // Stop advertising
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    await _nearby.stopAdvertising();
    _isAdvertising = false;
  }

  // Stop discovery
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    await _nearby.stopDiscovery();
    _isDiscovering = false;
  }

  // Disconnect from all endpoints
  Future<void> disconnect() async {
    for (final endpointId in _connectedEndpoints.toList()) {
      await _nearby.disconnectFromEndpoint(endpointId);
    }
    _connectedEndpoints.clear();
    await stopAdvertising();
    await stopDiscovery();
  }

  // Private callback methods
  void _onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
    debugPrint('Connection initiated with $endpointId');
    // Auto accept connections
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (String endpointId, PayloadTransferUpdate update) {
        // Handle transfer updates if needed
        debugPrint('Payload transfer update from $endpointId: ${update.status}');
      },
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(endpointId);
      debugPrint('Connected to endpoint: $endpointId');
    }
  }

  void _onDisconnected(String endpointId) {
    _connectedEndpoints.remove(endpointId);
    debugPrint('Disconnected from endpoint: $endpointId');
  }

  void _onEndpointFound(String endpointId, String endpointName, String serviceId) {
    debugPrint('Endpoint found: $endpointId ($endpointName)');
    // Request connection
    _nearby.requestConnection(
      'Device ${DateTime.now().millisecondsSinceEpoch}',
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  void _onEndpointLost(String endpointId) {
    debugPrint('Endpoint lost: $endpointId');
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final String str = String.fromCharCodes(payload.bytes!);
      try {
        final data = jsonDecode(str) as Map<String, dynamic>;
        _messageController.add(data);
      } catch (e) {
        debugPrint('Error parsing payload: $e');
      }
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}