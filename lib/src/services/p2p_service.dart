import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

/// A service for handling peer-to-peer communication across different platforms.
/// Uses a strategy pattern to select the appropriate implementation based on platform:
/// - Android: Nearby Connections API (primary), with BLE fallback
/// - iOS: Multipeer Connectivity (placeholder for now), with BLE fallback
class P2PService {
  static final P2PService _instance = P2PService._internal();
  static P2PService get instance => _instance;

  P2PService._internal();

  final Nearby _nearby = Nearby();
  final Strategy _strategy = Strategy.P2P_POINT_TO_POINT;
  
  bool _isDiscovering = false;
  bool _isAdvertising = false;
  
  final _discoveryCallbacks = <Function(Map<String, dynamic>)>[];
  final _connectedPeers = <String, String>{}; // <peerId, username>

  // Stream controllers for different events
  final _onDeviceFoundController = StreamController<Map<String, dynamic>>.broadcast();
  final _onConnectionController = StreamController<Map<String, dynamic>>.broadcast();
  final _onDisconnectionController = StreamController<String>.broadcast();
  final _onDataReceivedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onDeviceFound => _onDeviceFoundController.stream;
  Stream<Map<String, dynamic>> get onConnection => _onConnectionController.stream;
  Stream<String> get onDisconnection => _onDisconnectionController.stream;
  Stream<Map<String, dynamic>> get onDataReceived => _onDataReceivedController.stream;

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      // Request location permissions for Android
      await _nearby.askLocationPermission();
    }
    // iOS: Would handle MultipeerConnectivity initialization here
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    try {
      if (Platform.isAndroid) {
        await _startAndroidDiscovery();
      } else if (Platform.isIOS) {
        await _startIOSDiscovery();
      }
      _isDiscovering = true;
    } catch (e) {
      debugPrint('Error starting discovery: $e');
      rethrow;
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;

    try {
      if (Platform.isAndroid) {
        await _nearby.stopDiscovery();
      } else if (Platform.isIOS) {
        // Stop iOS MultipeerConnectivity discovery
      }
      _isDiscovering = false;
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
      rethrow;
    }
  }

  Future<void> broadcast(Map<String, dynamic> payload) async {
    if (!_isAdvertising) {
      await _startAdvertising();
    }

    final encodedPayload = jsonEncode(payload);
    for (final peerId in _connectedPeers.keys) {
      try {
        await _nearby.sendBytesPayload(
          peerId,
          Uint8List.fromList(utf8.encode(encodedPayload)),
        );
      } catch (e) {
        debugPrint('Error sending to peer $peerId: $e');
      }
    }
  }

  Future<void> sendToPeer(String peerId, Map<String, dynamic> payload) async {
    if (!_connectedPeers.containsKey(peerId)) {
      throw Exception('Peer not connected: $peerId');
    }

    final encodedPayload = jsonEncode(payload);
    await _nearby.sendBytesPayload(
      peerId,
      Uint8List.fromList(utf8.encode(encodedPayload)),
    );
  }

  void onPacketReceived(Function(Map<String, dynamic>) callback) {
    _discoveryCallbacks.add(callback);
  }

  // Private methods for platform-specific implementations
  Future<void> _startAndroidDiscovery() async {
    await _nearby.startDiscovery(
      'com.offgrid.sos',
      Strategy.P2P_POINT_TO_POINT,
      onEndpointFound: (String id, String username, String serviceId) {
        _onDeviceFoundController.add({
          'id': id,
          'username': username,
          'serviceId': serviceId,
        });
      },
      onEndpointLost: (String id) {
        _connectedPeers.remove(id);
        _onDisconnectionController.add(id);
      },
      serviceId: 'com.offgrid.sos',
    );
  }

  Future<void> _startIOSDiscovery() async {
    // TODO: Implement MultipeerConnectivity for iOS
    throw UnimplementedError('iOS P2P discovery not yet implemented');
  }

  Future<void> _startAdvertising() async {
    if (_isAdvertising) return;

    try {
      if (Platform.isAndroid) {
        await _nearby.startAdvertising(
          'Device ${DateTime.now().millisecondsSinceEpoch}',
          Strategy.P2P_POINT_TO_POINT,
          onConnectionInitiated: (String id, ConnectionInfo info) async {
            // Auto-accept connections
            await _nearby.acceptConnection(
              id,
              onPayLoadRecieved: _onPayloadReceived,
              onPayloadTransferUpdate: (String id, PayloadTransferUpdate update) {
                // Handle transfer updates if needed
              },
            );
          },
          onConnectionResult: (String id, Status status) {
            if (status == Status.CONNECTED) {
              _connectedPeers[id] = 'Unknown';
              _onConnectionController.add({'id': id, 'status': 'connected'});
            }
          },
          onDisconnected: (String id) {
            _connectedPeers.remove(id);
            _onDisconnectionController.add(id);
          },
          serviceId: 'com.offgrid.sos',
        );
        _isAdvertising = true;
      } else if (Platform.isIOS) {
        // TODO: Implement MultipeerConnectivity advertising
      }
    } catch (e) {
      debugPrint('Error starting advertising: $e');
      rethrow;
    }
  }

  void _onPayloadReceived(String id, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final String str = String.fromCharCodes(payload.bytes!);
      try {
        final data = jsonDecode(str) as Map<String, dynamic>;
        for (final callback in _discoveryCallbacks) {
          callback(data);
        }
        _onDataReceivedController.add(data);
      } catch (e) {
        debugPrint('Error parsing payload: $e');
      }
    }
  }

  // BLE fallback methods for small payloads
  Future<void> _startBLEFallback() async {
    final ble.FlutterBluePlus flutterBlue = ble.FlutterBluePlus.instance;
    
    try {
      // Start scanning
      await flutterBlue.startScan(timeout: const Duration(seconds: 4));
      
      flutterBlue.scanResults.listen((results) {
        for (ble.ScanResult r in results) {
          if (r.device.name.startsWith('SOS_')) {
            // Found a potential SOS device
            _onDeviceFoundController.add({
              'id': r.device.id.id,
              'name': r.device.name,
              'rssi': r.rssi,
              'type': 'ble'
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting BLE scan: $e');
    }
  }

  void dispose() {
    _onDeviceFoundController.close();
    _onConnectionController.close();
    _onDisconnectionController.close();
    _onDataReceivedController.close();
  }
}