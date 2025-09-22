import 'dart:async';import 'dart:async';

import 'dart:convert';import 'dart:convert';

import 'dart:io';import 'dart:io';

import 'dart:typed_data';import 'dart:typed_data';

import 'package:flutter/foundation.dart';import 'package:flutter/foundation.dart';

import 'package:nearby_connections/nearby_connections.dart';import 'package:nearby_connections/nearby_connections.dart';

import 'package:permission_handler/permission_handler.dart';import 'package:permission_handler/permission_handler.dart';



/// A service for handling peer-to-peer communication with optimizations

class P2PService {

  static final P2PService _instance = P2PService._internal();/// A service for handling peer-to-peer communicationimport 'package:flutter/foundation.dart';import 'dart:convert';import 'dart:io';import 'dart:convert';

  static P2PService get instance => _instance;

class P2PService {

  P2PService._internal();

  static final P2PService _instance = P2PService._internal();import 'package:nearby_connections/nearby_connections.dart';

  final Nearby _nearby = Nearby();

  bool _isDiscovering = false;  static P2PService get instance => _instance;

  bool _isAdvertising = false;

  final _connectedPeers = <String>{};import 'package:permission_handler/permission_handler.dart';import 'package:flutter/foundation.dart';



  // Rate limiting settings  P2PService._internal();

  static const Duration _rateLimitWindow = Duration(seconds: 1);

  static const int _maxMessagesPerWindow = 50;

  final _messageCounters = <String, List<DateTime>>{};

  final Nearby _nearby = Nearby();

  // Batching settings

  static const Duration _batchWindow = Duration(milliseconds: 100);  bool _isDiscovering = false;class P2PService {import 'package:nearby_connections/nearby_connections.dart';import 'package:flutter/foundation.dart';import 'dart:io';

  final _batchedMessages = <String, List<Map<String, dynamic>>>{};

  final _batchTimers = <String, Timer>{};  bool _isAdvertising = false;



  // Retry settings    static final P2PService _instance = P2PService._internal();

  static const int _maxRetries = 3;

  static const Duration _baseRetryDelay = Duration(milliseconds: 100);  final _connectedPeers = <String>{};



  // Stream controllers  static P2PService get instance => _instance;import 'package:permission_handler/permission_handler.dart';

  final _onDeviceFoundController = StreamController<Map<String, dynamic>>.broadcast();

  final _onConnectionController = StreamController<Map<String, dynamic>>.broadcast();  // Stream controllers for communication

  final _onDisconnectionController = StreamController<String>.broadcast();

  final _onMessageController = StreamController<Map<String, dynamic>>.broadcast();  final _onDeviceFoundController = StreamController<Map<String, dynamic>>.broadcast();



  Stream<Map<String, dynamic>> get onDeviceFound => _onDeviceFoundController.stream;  final _onConnectionController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onConnection => _onConnectionController.stream;

  Stream<String> get onDisconnection => _onDisconnectionController.stream;  final _onDisconnectionController = StreamController<String>.broadcast();  P2PService._internal();import 'package:nearby_connections/nearby_connections.dart';

  Stream<Map<String, dynamic>> get onMessage => _onMessageController.stream;

  final _onDataReceivedController = StreamController<Map<String, dynamic>>.broadcast();

  Future<void> initialize() async {

    final permissions = await [

      Permission.location,

      Permission.nearbyWifiDevices,  // Expose streams

      Permission.bluetoothScan,

      Permission.bluetoothConnect,  Stream<Map<String, dynamic>> get onDeviceFound => _onDeviceFoundController.stream;  final Nearby _nearby = Nearby();/// A service for handling peer-to-peer communication across different platforms.

      Permission.bluetoothAdvertise,

    ].request();  Stream<Map<String, dynamic>> get onConnection => _onConnectionController.stream;



    if (permissions.values.any((status) => status.isDenied)) {  Stream<String> get onDisconnection => _onDisconnectionController.stream;  bool _isDiscovering = false;

      throw Exception('Required permissions not granted');

    }  Stream<Map<String, dynamic>> get onDataReceived => _onDataReceivedController.stream;

  }

  bool _isAdvertising = false;/// Uses Nearby Connections API on Android and MultipeerConnectivity on iOS.import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;import 'package:flutter/foundation.dart';

  Future<void> startDiscovery() async {

    if (_isDiscovering) return;  Future<void> initialize() async {



    try {    if (Platform.isAndroid) {  

      bool success = await _nearby.startDiscovery(

        'com.offgrid.sos',      await [

        Strategy.P2P_CLUSTER,

        onEndpointFound: (String id, String name, String serviceId) {        Permission.location,  final _connectedPeers = <String>{};class P2PService {

          _onDeviceFoundController.add({

            'id': id,        Permission.bluetooth,

            'name': name,

            'serviceId': serviceId,        Permission.bluetoothConnect,

          });

        },        Permission.bluetoothScan,

        onEndpointLost: (String id) {

          debugPrint('Lost endpoint: $id');        Permission.bluetoothAdvertise,  Future<void> initialize() async {  static final P2PService _instance = P2PService._internal();import 'package:permission_handler/permission_handler.dart';import 'package:nearby_connections/nearby_connections.dart';

        },

      );      ].request();



      _isDiscovering = success;    }    if (Platform.isAndroid) {

    } catch (e) {

      debugPrint('Error starting discovery: $e');  }

      rethrow;

    }      await [  static P2PService get instance => _instance;

  }

  Future<void> startDiscovery() async {

  Future<void> stopDiscovery() async {

    if (!_isDiscovering) return;    if (_isDiscovering) return;        Permission.location,

    await _nearby.stopDiscovery();

    _isDiscovering = false;

  }

    try {        Permission.bluetooth,import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

  Future<void> startAdvertising() async {

    if (_isAdvertising) return;      _isDiscovering = true;



    try {      await _nearby.startDiscovery(        Permission.bluetoothConnect,

      bool success = await _nearby.startAdvertising(

        'Device-${DateTime.now().millisecondsSinceEpoch}',        'com.example.offgrid_sos_app',

        Strategy.P2P_CLUSTER,

        onConnectionInitiated: (String id, ConnectionInfo info) async {        Strategy.P2P_POINT_TO_POINT,        Permission.bluetoothScan,  P2PService._internal();

          _onConnectionController.add({

            'id': id,        onEndpointFound: (String id, String name, String serviceId) {

            'endpoint': info.endpointName,

            'authToken': info.authenticationToken,          _onDeviceFoundController.add({        Permission.bluetoothAdvertise,

          });

          await _nearby.acceptConnection(            'id': id,

            id,

            onPayLoadRecieved: _onPayloadReceived,            'name': name,      ].request();/// A service for handling peer-to-peer communication across different platforms.

            onPayloadTransferUpdate: _onPayloadTransferUpdate,

          );            'serviceId': serviceId,

        },

        onConnectionResult: (String id, Status status) {          });    }

          if (status == Status.CONNECTED) {

            _connectedPeers.add(id);        },

          }

        },        onEndpointLost: (String id) {  }  final Nearby _nearby = Nearby();

        onDisconnected: (String id) {

          _connectedPeers.remove(id);          _connectedPeers.remove(id);

          _onDisconnectionController.add(id);

        },          _onDisconnectionController.add(id);

      );

        },

      _isAdvertising = success;

    } catch (e) {      );  Future<void> startDiscovery() async {  bool _isDiscovering = false;/// Uses Nearby Connections API on Android and MultipeerConnectivity on iOS./// A service for handling peer-to-peer communication across different platforms.

      debugPrint('Error starting advertising: $e');

      rethrow;    } catch (e) {

    }

  }      debugPrint('Error starting discovery: $e');    if (_isDiscovering) return;



  Future<void> stopAdvertising() async {      _isDiscovering = false;

    if (!_isAdvertising) return;

    await _nearby.stopAdvertising();      rethrow;  bool _isAdvertising = false;

    _isAdvertising = false;

  }    }



  Future<void> sendMessage(String peerId, Map<String, dynamic> message) async {  }    try {

    if (!_connectedPeers.contains(peerId)) {

      throw Exception('Peer not connected');

    }

  Future<void> stopDiscovery() async {      _isDiscovering = true;  class P2PService {/// Uses a strategy pattern to select the appropriate implementation based on platform:

    // Check rate limiting

    if (!_checkRateLimit(peerId)) {    if (!_isDiscovering) return;

      throw Exception('Rate limit exceeded for peer');

    }    await _nearby.stopDiscovery();      await _nearby.startDiscovery(



    // Add message to batch    _isDiscovering = false;

    _batchedMessages.putIfAbsent(peerId, () => []);

    _batchedMessages[peerId]!.add(message);  }        'com.example.offgrid_sos_app',  final _connectedPeers = <String, String>{}; // <peerId, username>



    // Start or reset batch timer

    _batchTimers[peerId]?.cancel();

    _batchTimers[peerId] = Timer(_batchWindow, () => _sendBatch(peerId));  Future<void> startAdvertising() async {        Strategy.P2P_POINT_TO_POINT,

  }

    if (_isAdvertising) return;

  bool _checkRateLimit(String peerId) {

    final now = DateTime.now();        onEndpointFound: (id, name, serviceId) {  static final P2PService _instance = P2PService._internal();/// - Android: Nearby Connections API (primary), with BLE fallback

    _messageCounters.putIfAbsent(peerId, () => []);

        try {

    // Remove old timestamps

    _messageCounters[peerId]!.removeWhere(      _isAdvertising = true;          debugPrint('Found endpoint: $id');

      (timestamp) => now.difference(timestamp) > _rateLimitWindow

    );      await _nearby.startAdvertising(



    // Check if under limit        'Device ${DateTime.now().millisecondsSinceEpoch}',        },  // Stream controllers for different events

    if (_messageCounters[peerId]!.length >= _maxMessagesPerWindow) {

      return false;        Strategy.P2P_POINT_TO_POINT,

    }

        onConnectionInitiated: (String id, ConnectionInfo info) {        onEndpointLost: (id) {

    // Add new timestamp

    _messageCounters[peerId]!.add(now);          _onConnectionController.add({

    return true;

  }            'id': id,          _connectedPeers.remove(id);  final _onDeviceFoundController = StreamController<Map<String, dynamic>>.broadcast();  static P2PService get instance => _instance;/// - iOS: Multipeer Connectivity (placeholder for now), with BLE fallback



  Future<void> _sendBatch(String peerId) async {            'endpointName': info.endpointName,

    final messages = _batchedMessages[peerId];

    if (messages == null || messages.isEmpty) return;            'authenticationToken': info.authenticationToken,        },



    // Clear batch          });

    _batchedMessages[peerId] = [];

        },      );  final _onConnectionController = StreamController<Map<String, dynamic>>.broadcast();

    // Compress batch

    final batch = {        onConnectionResult: (String id, Status status) {

      'type': 'batch',

      'messages': messages,          if (status == Status.CONNECTED) {    } catch (e) {

      'timestamp': DateTime.now().toIso8601String(),

    };            _connectedPeers.add(id);

    

    final jsonStr = json.encode(batch);          }      debugPrint('Error starting discovery: $e');  final _onDisconnectionController = StreamController<String>.broadcast();class P2PService {

    final compressed = GZipCodec().encode(utf8.encode(jsonStr));

        },

    // Send compressed batch

    try {        onDisconnected: (String id) {      _isDiscovering = false;

      await _nearby.sendBytesPayload(

        peerId,          _connectedPeers.remove(id);

        Uint8List.fromList(compressed),

      );          _onDisconnectionController.add(id);      rethrow;  final _onDataReceivedController = StreamController<Map<String, dynamic>>.broadcast();

    } catch (e) {

      debugPrint('Error sending batch: $e');        },

      // Add failed messages back to batch for retry

      _batchedMessages[peerId] = [...messages];      );    }

      _scheduleRetry(peerId);

    }    } catch (e) {

  }

      debugPrint('Error starting advertising: $e');  }  P2PService._internal();  static final P2PService _instance = P2PService._internal();

  void _scheduleRetry(String peerId, {int attempt = 0}) {

    if (attempt >= _maxRetries) {      _isAdvertising = false;

      debugPrint('Max retries exceeded for peer: $peerId');

      return;      rethrow;

    }

    }

    final delay = _baseRetryDelay * (1 << attempt); // Exponential backoff

    Timer(delay, () {  }  Future<void> stopDiscovery() async {  Stream<Map<String, dynamic>> get onDeviceFound => _onDeviceFoundController.stream;

      if (_batchedMessages[peerId]?.isNotEmpty == true) {

        _sendBatch(peerId).catchError((e) {

          debugPrint('Retry attempt $attempt failed: $e');

          _scheduleRetry(peerId, attempt: attempt + 1);  Future<void> stopAdvertising() async {    if (!_isDiscovering) return;

        });

      }    if (!_isAdvertising) return;

    });

  }    await _nearby.stopAdvertising();    await _nearby.stopDiscovery();  Stream<Map<String, dynamic>> get onConnection => _onConnectionController.stream;  static P2PService get instance => _instance;



  void _onPayloadReceived(String peerId, Payload payload) {    _isAdvertising = false;

    if (payload.type == PayloadType.BYTES) {

      _processPayload(peerId, payload.bytes!);  }    _isDiscovering = false;

    }

  }



  void _onPayloadTransferUpdate(String peerId, PayloadTransferUpdate update) {  Future<bool> sendMessage(String peerId, Map<String, dynamic> message) async {  }  Stream<String> get onDisconnection => _onDisconnectionController.stream;

    if (update.status == PayloadStatus.FAILURE) {

      debugPrint('Failed to transfer payload to $peerId');    try {

      // Handle failed transfer - possibly trigger a retry

    }      final payload = Uint8List.fromList(utf8.encode(jsonEncode(message)));

  }

      await _nearby.sendBytesPayload(peerId, payload);

  void _processPayload(String peerId, Uint8List payload) {

    try {      return true;  Future<void> startAdvertising() async {  Stream<Map<String, dynamic>> get onDataReceived => _onDataReceivedController.stream;  final Nearby _nearby = Nearby();

      // Decompress payload

      final decompressed = GZipCodec().decode(payload);    } catch (e) {

      final jsonStr = utf8.decode(decompressed);

      final data = json.decode(jsonStr) as Map<String, dynamic>;      debugPrint('Error sending message: $e');    if (_isAdvertising) return;



      if (data['type'] == 'batch') {      return false;

        // Process batch messages

        final messages = List<Map<String, dynamic>>.from(data['messages']);    }

        for (final message in messages) {

          _onMessageController.add({  }

            'peerId': peerId,

            'data': message,    try {

          });

        }  Future<void> disconnect(String peerId) async {

      } else {

        // Process single message    try {      _isAdvertising = true;  Future<void> initialize() async {  bool _isDiscovering = false;  P2PService._internal();

        _onMessageController.add({

          'peerId': peerId,      await _nearby.disconnectFromEndpoint(peerId);

          'data': data,

        });      _connectedPeers.remove(peerId);      await _nearby.startAdvertising(

      }

    } catch (e) {    } catch (e) {

      debugPrint('Error processing payload: $e');

    }      debugPrint('Error disconnecting: $e');        'Device ${DateTime.now().millisecondsSinceEpoch}',    if (Platform.isAndroid) {

  }

      rethrow;

  void dispose() {

    _onDeviceFoundController.close();    }        Strategy.P2P_POINT_TO_POINT,

    _onConnectionController.close();

    _onDisconnectionController.close();  }

    _onMessageController.close();

            onConnectionInitiated: (id, info) {      await [  bool _isAdvertising = false;

    for (final timer in _batchTimers.values) {

      timer.cancel();  void dispose() {

    }

    _batchTimers.clear();    _onDeviceFoundController.close();          debugPrint('Connection initiated: $id');

    _batchedMessages.clear();

    _messageCounters.clear();    _onConnectionController.close();

    

    stopDiscovery();    _onDisconnectionController.close();        },        Permission.location,

    stopAdvertising();

  }    _onDataReceivedController.close();

}
  }        onConnectionResult: (id, status) {

}
          if (status == Status.CONNECTED) {        Permission.bluetooth,    final Nearby _nearby = Nearby();

            _connectedPeers.add(id);

          }        Permission.bluetoothConnect,

        },

        onDisconnected: (id) {        Permission.bluetoothScan,  final _connectedPeers = <String, String>{}; // <peerId, username>  final Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

          _connectedPeers.remove(id);

        },        Permission.bluetoothAdvertise,

      );

    } catch (e) {      ].request();  

      debugPrint('Error starting advertising: $e');

      _isAdvertising = false;    }

      rethrow;

    }  }  // Stream controllers for different events  bool _isDiscovering = false;

  }



  Future<void> stopAdvertising() async {

    if (!_isAdvertising) return;  Future<void> startDiscovery() async {  final _onDeviceFoundController = StreamController<Map<String, dynamic>>.broadcast();  bool _isAdvertising = false;

    await _nearby.stopAdvertising();

    _isAdvertising = false;    if (_isDiscovering) return;

  }

  final _onConnectionController = StreamController<Map<String, dynamic>>.broadcast();  

  Future<bool> sendMessage(String peerId, Map<String, dynamic> message) async {

    try {    try {

      final payload = Uint8List.fromList(utf8.encode(jsonEncode(message)));

      await _nearby.sendBytesPayload(peerId, payload);      _isDiscovering = true;  final _onDisconnectionController = StreamController<String>.broadcast();  final _discoveryCallbacks = <Function(Map<String, dynamic>)>[];

      return true;

    } catch (e) {      await _nearby.startDiscovery(

      debugPrint('Error sending message: $e');

      return false;        'com.example.offgrid_sos_app',  final _onDataReceivedController = StreamController<Map<String, dynamic>>.broadcast();  final _connectedPeers = <String, String>{}; // <peerId, username>

    }

  }        Strategy.P2P_POINT_TO_POINT,



  Future<void> disconnect(String peerId) async {        onEndpointFound: (id, name, serviceId) {

    try {

      await _nearby.disconnectFromEndpoint(peerId);          _onDeviceFoundController.add({

      _connectedPeers.remove(peerId);

    } catch (e) {            'id': id,  Stream<Map<String, dynamic>> get onDeviceFound => _onDeviceFoundController.stream;  // Stream controllers for different events

      debugPrint('Error disconnecting: $e');

      rethrow;            'name': name,

    }

  }            'serviceId': serviceId,  Stream<Map<String, dynamic>> get onConnection => _onConnectionController.stream;  final _onDeviceFoundController = StreamController<Map<String, dynamic>>.broadcast();

}
          });

        },  Stream<String> get onDisconnection => _onDisconnectionController.stream;  final _onConnectionController = StreamController<Map<String, dynamic>>.broadcast();

        onEndpointLost: (id) {

          _connectedPeers.remove(id);  Stream<Map<String, dynamic>> get onDataReceived => _onDataReceivedController.stream;  final _onDisconnectionController = StreamController<String>.broadcast();

          _onDisconnectionController.add(id);

        },  final _onDataReceivedController = StreamController<Map<String, dynamic>>.broadcast();

      );

    } catch (e) {  Future<void> initialize() async {

      debugPrint('Error starting discovery: $e');

      _isDiscovering = false;    if (Platform.isAndroid) {  Stream<Map<String, dynamic>> get onDeviceFound => _onDeviceFoundController.stream;

      rethrow;

    }      await [  Stream<Map<String, dynamic>> get onConnection => _onConnectionController.stream;

  }

        Permission.location,  Stream<String> get onDisconnection => _onDisconnectionController.stream;

  Future<void> stopDiscovery() async {

    if (!_isDiscovering) return;        Permission.bluetooth,  Stream<Map<String, dynamic>> get onDataReceived => _onDataReceivedController.stream;

    await _nearby.stopDiscovery();

    _isDiscovering = false;        Permission.bluetoothConnect,

  }

        Permission.bluetoothScan,  Future<void> initialize() async {

  Future<void> startAdvertising() async {

    if (_isAdvertising) return;        Permission.bluetoothAdvertise,    if (Platform.isAndroid) {



    try {      ].request();      // Request location permissions for Android

      _isAdvertising = true;

      await _nearby.startAdvertising(    }      await _nearby.askLocationPermission();

        'Device ${DateTime.now().millisecondsSinceEpoch}',

        Strategy.P2P_POINT_TO_POINT,  }    }

        onConnectionInitiated: (id, info) {

          _onConnectionController.add({    // iOS: Would handle MultipeerConnectivity initialization here

            'id': id,

            'endpointName': info.endpointName,  Future<void> startDiscovery() async {  }

            'authenticationToken': info.authenticationToken,

          });    if (_isDiscovering) return;

        },

        onConnectionResult: (id, status) {  Future<void> startDiscovery() async {

          if (status == Status.CONNECTED) {

            _connectedPeers[id] = id;    try {    if (_isDiscovering) return;

          }

        },      _isDiscovering = true;

        onDisconnected: (id) {

          _connectedPeers.remove(id);      await _nearby.startDiscovery(    try {

          _onDisconnectionController.add(id);

        },        "com.example.offgrid_sos_app",      if (Platform.isAndroid) {

      );

    } catch (e) {        Strategy.P2P_POINT_TO_POINT,        await _startAndroidDiscovery();

      debugPrint('Error starting advertising: $e');

      _isAdvertising = false;        onEndpointFound: (String id, String name, String serviceId) {      } else if (Platform.isIOS) {

      rethrow;

    }          _onDeviceFoundController.add({        await _startIOSDiscovery();

  }

            'id': id,      }

  Future<void> stopAdvertising() async {

    if (!_isAdvertising) return;            'name': name,      _isDiscovering = true;

    await _nearby.stopAdvertising();

    _isAdvertising = false;            'serviceId': serviceId,    } catch (e) {

  }

          });      debugPrint('Error starting discovery: $e');

  Future<bool> sendMessage(String peerId, Map<String, dynamic> message) async {

    try {        },      rethrow;

      final payload = Uint8List.fromList(utf8.encode(jsonEncode(message)));

      await _nearby.sendBytesPayload(peerId, payload);        onEndpointLost: (String id) {    }

      return true;

    } catch (e) {          _connectedPeers.remove(id);  }

      debugPrint('Error sending message: $e');

      return false;          _onDisconnectionController.add(id);

    }

  }        },  Future<void> stopDiscovery() async {



  Future<void> disconnect(String peerId) async {        serviceId: "com.example.offgrid_sos_app",    if (!_isDiscovering) return;

    try {

      await _nearby.disconnectFromEndpoint(peerId);      );

      _connectedPeers.remove(peerId);

    } catch (e) {    } catch (e) {    try {

      debugPrint('Error disconnecting: $e');

      rethrow;      debugPrint('Error starting discovery: $e');      if (Platform.isAndroid) {

    }

  }      _isDiscovering = false;        await _nearby.stopDiscovery();



  void dispose() {      rethrow;      } else if (Platform.isIOS) {

    _onDeviceFoundController.close();

    _onConnectionController.close();    }        // Stop iOS MultipeerConnectivity discovery

    _onDisconnectionController.close();

    _onDataReceivedController.close();  }      }

  }

}      _isDiscovering = false;

  Future<void> stopDiscovery() async {    } catch (e) {

    if (!_isDiscovering) return;      debugPrint('Error stopping discovery: $e');

    await _nearby.stopDiscovery();      rethrow;

    _isDiscovering = false;    }

  }  }



  Future<void> startAdvertising() async {  Future<void> broadcast(Map<String, dynamic> payload) async {

    if (_isAdvertising) return;    if (!_isAdvertising) {

      await _startAdvertising();

    try {    }

      _isAdvertising = true;

      await _nearby.startAdvertising(    final encodedPayload = jsonEncode(payload);

        "Device ${DateTime.now().millisecondsSinceEpoch}",    for (final peerId in _connectedPeers.keys) {

        Strategy.P2P_POINT_TO_POINT,      try {

        onConnectionInitiated: (String id, ConnectionInfo info) {        await _nearby.sendBytesPayload(

          _onConnectionController.add({          peerId,

            'id': id,          Uint8List.fromList(utf8.encode(encodedPayload)),

            'endpointName': info.endpointName,        );

            'authenticationToken': info.authenticationToken,      } catch (e) {

          });        debugPrint('Error sending to peer $peerId: $e');

        },      }

        onConnectionResult: (String id, Status status) {    }

          if (status == Status.CONNECTED) {  }

            _connectedPeers[id] = id;

          }  Future<void> sendToPeer(String peerId, Map<String, dynamic> payload) async {

        },    if (!_connectedPeers.containsKey(peerId)) {

        onDisconnected: (String id) {      throw Exception('Peer not connected: $peerId');

          _connectedPeers.remove(id);    }

          _onDisconnectionController.add(id);

        },    final encodedPayload = jsonEncode(payload);

        serviceId: "com.example.offgrid_sos_app",    await _nearby.sendBytesPayload(

      );      peerId,

    } catch (e) {      Uint8List.fromList(utf8.encode(encodedPayload)),

      debugPrint('Error starting advertising: $e');    );

      _isAdvertising = false;  }

      rethrow;

    }  void onPacketReceived(Function(Map<String, dynamic>) callback) {

  }    _discoveryCallbacks.add(callback);

  }

  Future<void> stopAdvertising() async {

    if (!_isAdvertising) return;  // Private methods for platform-specific implementations

    await _nearby.stopAdvertising();  Future<void> _startAndroidDiscovery() async {

    _isAdvertising = false;    await _nearby.startDiscovery(

  }      'com.offgrid.sos',

      Strategy.P2P_POINT_TO_POINT,

  Future<bool> sendMessage(String peerId, Map<String, dynamic> message) async {      onEndpointFound: (String id, String username, String serviceId) {

    try {        _onDeviceFoundController.add({

      final payload = Uint8List.fromList(utf8.encode(message.toString()));          'id': id,

      await _nearby.sendBytesPayload(peerId, payload);          'username': username,

      return true;          'serviceId': serviceId,

    } catch (e) {        });

      debugPrint('Error sending message: $e');      },

      return false;      onEndpointLost: (String id) {

    }        _connectedPeers.remove(id);

  }        _onDisconnectionController.add(id);

      },

  Future<void> disconnect(String peerId) async {      serviceId: 'com.offgrid.sos',

    try {    );

      await _nearby.disconnectFromEndpoint(peerId);  }

      _connectedPeers.remove(peerId);

    } catch (e) {  Future<void> _startIOSDiscovery() async {

      debugPrint('Error disconnecting: $e');    // TODO: Implement MultipeerConnectivity for iOS

      rethrow;    throw UnimplementedError('iOS P2P discovery not yet implemented');

    }  }

  }

  Future<void> _startAdvertising() async {

  void dispose() {    if (_isAdvertising) return;

    _onDeviceFoundController.close();

    _onConnectionController.close();    try {

    _onDisconnectionController.close();      if (Platform.isAndroid) {

    _onDataReceivedController.close();        await _nearby.startAdvertising(

  }          'Device ${DateTime.now().millisecondsSinceEpoch}',

}          Strategy.P2P_POINT_TO_POINT,
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