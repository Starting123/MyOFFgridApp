import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

/// A service for handling peer-to-peer communication with optimizations
class P2PService {
  // Singleton instance
  static final P2PService _instance = P2PService._internal();
  static P2PService get instance => _instance;
  P2PService._internal();

  // Service instances and state
  final _nearbyService = Nearby();
  final _connectedPeers = <String, String>{}; // <peerId, deviceName>

  // Stream controllers
  final _onPeerFoundController = StreamController<String>.broadcast();
  final _onPeerLostController = StreamController<String>.broadcast();
  final _onDataReceivedController = StreamController<Map<String, dynamic>>.broadcast();

  // State flags
  bool _isDiscovering = false;
  bool _isAdvertising = false;

  // Stream getters
  Stream<String> get onPeerFound => _onPeerFoundController.stream;
  Stream<String> get onPeerLost => _onPeerLostController.stream;
  Stream<Map<String, dynamic>> get onDataReceived => _onDataReceivedController.stream;
  Set<String> get connectedPeers => _connectedPeers.keys.toSet();

  Future<bool> initialize() async {
    try {
      debugPrint('🔄 P2P Service: กำลังขอ permissions...');
      
      final permissions = await [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        if (Platform.isAndroid) Permission.nearbyWifiDevices,
      ].request();

      bool allGranted = permissions.values.every((status) => status.isGranted);
      if (!allGranted) {
        debugPrint('❌ P2P Service: ไม่ได้รับ permissions ทั้งหมด');
        permissions.forEach((permission, status) {
          if (!status.isGranted) {
            debugPrint('❌ ${permission.toString()}: ${status.toString()}');
          }
        });
        return false;
      }
      
      debugPrint('✅ P2P Service: ได้รับ permissions ครบแล้ว');

      debugPrint('✅ P2P Service initialized สำเร็จ');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing P2PService: $e');
      return false;
    }
  }

  Future<bool> startDiscovery() async {
    if (_isDiscovering) return true;
    
    try {
      _isDiscovering = await _nearbyService.startDiscovery(
        'com.example.offgrid_sos_app',
        Strategy.P2P_CLUSTER,
        onEndpointFound: (endpointId, endpointName, serviceId) {
          _onPeerFoundController.add(endpointId);
        },
        onEndpointLost: (endpointId) {
          if (endpointId != null) {
            _onPeerLostController.add(endpointId);
            _connectedPeers.remove(endpointId);
          }
        },
        serviceId: "com.example.offgrid_sos",
      );
      return _isDiscovering;
    } catch (e) {
      debugPrint('Error starting discovery: $e');
      _isDiscovering = false;
      return false;
    }
  }

  Future<bool> startAdvertising(String deviceName) async {
    if (_isAdvertising) return true;
    
    try {
      _isAdvertising = await _nearbyService.startAdvertising(
        deviceName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (endpointId, status) {
          if (status == Status.CONNECTED) {
            _connectedPeers[endpointId] = deviceName;
          } else {
            _connectedPeers.remove(endpointId);
          }
        },
        onDisconnected: (endpointId) {
          _connectedPeers.remove(endpointId);
          _onPeerLostController.add(endpointId);
        },
        serviceId: "com.example.offgrid_sos",
      );
      return _isAdvertising;
    } catch (e) {
      debugPrint('Error starting advertising: $e');
      _isAdvertising = false;
      return false;
    }
  }

  Future<void> _onConnectionInitiated(String endpointId, ConnectionInfo info) async {
    try {
      await _nearbyService.acceptConnection(
        endpointId,
        onPayLoadRecieved: (endpointId, payload) {
          _handlePayload(endpointId, payload);
        },
        onPayloadTransferUpdate: (endpointId, update) {
          // Handle transfer updates if needed
        },
      );
    } catch (e) {
      debugPrint('Error accepting connection: $e');
    }
  }

  void _handlePayload(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final String data = String.fromCharCodes(payload.bytes!);
      try {
        final Map<String, dynamic> jsonData = json.decode(data);
        _onDataReceivedController.add(jsonData);
      } catch (e) {
        debugPrint('Error parsing payload: $e');
      }
    }
  }

  Future<bool> sendMessage(String message, {String? targetPeerId}) async {
    final Map<String, dynamic> data = {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'message',
    };

    return _sendData(data, targetPeerId: targetPeerId);
  }

  Future<bool> sendSOS(String message, {String? targetPeerId}) async {
    final Map<String, dynamic> data = {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'sos',
    };

    return _sendData(data, targetPeerId: targetPeerId);
  }

  Future<bool> _sendData(Map<String, dynamic> data, {String? targetPeerId}) async {
    try {
      final List<int> bytes = utf8.encode(json.encode(data));
      final Uint8List payload = Uint8List.fromList(bytes);

      if (targetPeerId != null) {
        if (!_connectedPeers.containsKey(targetPeerId)) {
          return false;
        }
        await _nearbyService.sendBytesPayload(targetPeerId, payload);
      } else {
        for (final peerId in _connectedPeers.keys) {
          await _nearbyService.sendBytesPayload(peerId, payload);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error sending data: $e');
      return false;
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    try {
      await _nearbyService.stopDiscovery();
      _isDiscovering = false;
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    try {
      await _nearbyService.stopAdvertising();
      _isAdvertising = false;
    } catch (e) {
      debugPrint('Error stopping advertising: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await stopDiscovery();
      await stopAdvertising();
      for (final peerId in _connectedPeers.keys) {
        await _nearbyService.disconnectFromEndpoint(peerId);
      }
      _connectedPeers.clear();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  void dispose() {
    _onPeerFoundController.close();
    _onPeerLostController.close();
    _onDataReceivedController.close();
    disconnect();
  }
}