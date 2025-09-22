import 'dart:convert';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/message_model.dart';
import '../utils/constants.dart';

class P2PSync {
  final Nearby nearby = Nearby();
  final Strategy strategy = Strategy.P2P_STAR;
  final String serviceId = 'com.offgrid.sos.sync';
  
  bool _advertising = false;
  bool _discovering = false;
  final Map<String, ConnectionInfo> _connections = {};

  Future<bool> _checkPermissions() async {
    final locationPermission = await Permission.location.request();
    if (locationPermission.isDenied) return false;

    final bluetoothPermission = await Permission.bluetooth.request();
    if (bluetoothPermission.isDenied) return false;

    return true;
  }

  Future<bool> startAdvertising(String userId) async {
    if (_advertising) return true;

    try {
      if (!await _checkPermissions()) return false;

      await nearby.startAdvertising(
        userId,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          _connections[id] = info;
          _onConnectionInitiated(id, info);
        },
        onConnectionResult: (String id, Status status) {
          _onConnectionResult(id, status);
        },
        onDisconnected: (String id) {
          _onDisconnected(id);
        },
      );
      
      _advertising = true;
      return true;
    } catch (e) {
      print('Error starting advertising: $e');
      return false;
    }
  }

  Future<bool> startDiscovery(String userId) async {
    if (_discovering) return true;

    try {
      if (!await _checkPermissions()) return false;

      await nearby.startDiscovery(
        userId,
        strategy,
        onEndpointFound: (String id, String userName, String serviceId) {
          _onEndpointFound(id, userName);
        },
        onEndpointLost: _onEndpointLost,
      );
      
      _discovering = true;
      return true;
    } catch (e) {
      print('Error starting discovery: $e');
      return false;
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    nearby.acceptConnection(
      id,
      onPayLoadRecieved: onPayLoadRecieved,
      onPayLoadTransferUpdate: onPayLoadTransferUpdate,
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status != Status.CONNECTED) {
      _connections.remove(id);
    }
  }

  void _onDisconnected(String id) {
    _connections.remove(id);
  }

  void _onEndpointFound(String id, String userName) {
    nearby.requestConnection(
      userName,
      id,
      onConnectionInitiated: (String id, ConnectionInfo info) {
        _connections[id] = info;
        _onConnectionInitiated(id, info);
      },
      onConnectionResult: (String id, Status status) {
        _onConnectionResult(id, status);
      },
      onDisconnected: (String id) {
        _onDisconnected(id);
      },
    );
  }

  void _onEndpointLost(String id) {
    _connections.remove(id);
  }

  void onPayLoadRecieved(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      final jsonStr = String.fromCharCodes(payload.bytes!);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // Handle received message based on type
      if (data['type'] == Constants.textMessage) {
        // Process text message
      } else if (data['type'] == Constants.sosMessage) {
        // Process SOS message with high priority
      }
    }
  }

  void onPayLoadTransferUpdate(String endpointId, PayloadTransferUpdate update) {
    if (update.status == PayloadStatus.SUCCESS) {
      // Handle successful transfer
    } else if (update.status == PayloadStatus.FAILURE) {
      // Handle transfer failure
    }
  }

  Future<bool> sendMessage(String endpointId, MessageModel message) async {
    if (!_connections.containsKey(endpointId)) return false;

    try {
      final jsonStr = jsonEncode({
        'id': message.id,
        'from': message.from,
        'to': message.to,
        'type': message.contentType,
        'content': message.content,
        'createdAt': message.createdAt.toIso8601String(),
      });

      final bytes = Uint8List.fromList(jsonStr.codeUnits);
      
      await nearby.sendBytesPayload(endpointId, bytes);
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (_advertising) {
      await nearby.stopAdvertising();
      _advertising = false;
    }
    if (_discovering) {
      await nearby.stopDiscovery();
      _discovering = false;
    }
    await nearby.stopAllEndpoints();
    _connections.clear();
  }
}