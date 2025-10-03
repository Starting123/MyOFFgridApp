import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Production-ready WiFi Direct Service for Android
/// Provides high-bandwidth peer-to-peer communication without internet
class WiFiDirectService {
  static final WiFiDirectService _instance = WiFiDirectService._internal();
  static WiFiDirectService get instance => _instance;
  WiFiDirectService._internal();

  static const MethodChannel _channel = MethodChannel('wifi_direct_channel');
  
  bool _isInitialized = false;
  bool _isDiscovering = false;
  bool _isGroupOwner = false;
  
  // Stream controllers
  final StreamController<List<WiFiDirectDevice>> _peersController = 
      StreamController<List<WiFiDirectDevice>>.broadcast();
  final StreamController<WiFiDirectDevice> _peerFoundController = 
      StreamController<WiFiDirectDevice>.broadcast();
  final StreamController<String> _peerLostController = 
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<WiFiDirectConnectionInfo> _connectionController = 
      StreamController<WiFiDirectConnectionInfo>.broadcast();
  
  final List<WiFiDirectDevice> _peers = [];
  WiFiDirectDevice? _connectedPeer;
  WiFiDirectConnectionInfo? _connectionInfo;

  // Public streams
  Stream<List<WiFiDirectDevice>> get peersStream => _peersController.stream;
  Stream<WiFiDirectDevice> get onPeerFound => _peerFoundController.stream;
  Stream<String> get onPeerLost => _peerLostController.stream;
  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;
  Stream<WiFiDirectConnectionInfo> get onConnectionChanged => _connectionController.stream;
  
  List<WiFiDirectDevice> get availablePeers => List.unmodifiable(_peers);
  bool get isInitialized => _isInitialized;
  bool get isDiscovering => _isDiscovering;
  bool get isConnected => _connectedPeer != null;
  WiFiDirectDevice? get connectedPeer => _connectedPeer;

  /// Initialize WiFi Direct with permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      debugPrint('🔄 Initializing WiFi Direct service...');
      
      // Request necessary permissions
      await _requestPermissions();
      
      // Set up method call handler
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Initialize native WiFi Direct
      bool initialized = await _channel.invokeMethod('initialize') ?? false;
      
      if (initialized) {
        _isInitialized = true;
        debugPrint('✅ WiFi Direct service initialized successfully');
        return true;
      } else {
        debugPrint('❌ WiFi Direct initialization failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ WiFi Direct initialization error: $e');
      return false;
    }
  }

  /// Request required permissions for WiFi Direct
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.location,
      Permission.nearbyWifiDevices,
      // Note: ACCESS_WIFI_STATE and CHANGE_WIFI_STATE are normal permissions
      // declared in AndroidManifest.xml, not runtime permissions
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    for (var entry in statuses.entries) {
      if (!entry.value.isGranted) {
        debugPrint('⚠️ ${entry.key} permission not granted: ${entry.value}');
      }
    }
  }

  /// Start peer discovery
  Future<bool> startDiscovery() async {
    if (!_isInitialized) {
      debugPrint('❌ WiFi Direct not initialized');
      return false;
    }
    
    if (_isDiscovering) {
      debugPrint('ℹ️ WiFi Direct discovery already active');
      return true;
    }

    try {
      bool started = await _channel.invokeMethod('startDiscovery') ?? false;
      _isDiscovering = started;
      
      if (started) {
        debugPrint('🔍 WiFi Direct peer discovery started');
      } else {
        debugPrint('❌ Failed to start WiFi Direct discovery');
      }
      
      return started;
    } catch (e) {
      debugPrint('❌ Error starting WiFi Direct discovery: $e');
      return false;
    }
  }

  /// Stop peer discovery
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    
    try {
      await _channel.invokeMethod('stopDiscovery');
      _isDiscovering = false;
      debugPrint('⏹️ WiFi Direct discovery stopped');
    } catch (e) {
      debugPrint('❌ Error stopping WiFi Direct discovery: $e');
    }
  }

  /// Connect to a peer
  Future<bool> connectToPeer(WiFiDirectDevice device) async {
    if (!_isInitialized) return false;
    
    try {
      bool connected = await _channel.invokeMethod('connectToPeer', {
        'deviceAddress': device.deviceAddress,
      }) ?? false;
      
      if (connected) {
        debugPrint('🔗 Initiating connection to ${device.deviceName}');
      } else {
        debugPrint('❌ Failed to initiate connection to ${device.deviceName}');
      }
      
      return connected;
    } catch (e) {
      debugPrint('❌ Error connecting to peer: $e');
      return false;
    }
  }

  /// Disconnect from current peer
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _connectedPeer = null;
      _connectionInfo = null;
      debugPrint('🔌 Disconnected from WiFi Direct peer');
    } catch (e) {
      debugPrint('❌ Error disconnecting: $e');
    }
  }

  /// Send text message to connected peer
  Future<bool> sendMessage(String message) async {
    final messageBytes = utf8.encode(message);
    return sendData(Uint8List.fromList(messageBytes));
  }

  /// Send raw data to connected peer
  Future<bool> sendData(Uint8List data) async {
    if (!isConnected || _connectionInfo == null) {
      debugPrint('❌ No active WiFi Direct connection');
      return false;
    }
    
    try {
      bool sent = await _channel.invokeMethod('sendData', {
        'data': data,
        'targetAddress': _connectionInfo!.groupOwnerAddress,
      }) ?? false;
      
      if (sent) {
        debugPrint('📤 Data sent via WiFi Direct (${data.length} bytes)');
      } else {
        debugPrint('❌ Failed to send data via WiFi Direct');
      }
      
      return sent;
    } catch (e) {
      debugPrint('❌ Error sending data: $e');
      return false;
    }
  }

  /// Handle method calls from native Android code
  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onPeersChanged':
          _handlePeersChanged(call.arguments);
          break;
        case 'onConnectionChanged':
          _handleConnectionChanged(call.arguments);
          break;
        case 'onDataReceived':
          _handleDataReceived(call.arguments);
          break;
        default:
          debugPrint('⚠️ Unknown method call: ${call.method}');
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling method call: $e');
    }
  }

  void _handlePeersChanged(dynamic arguments) {
    try {
      final List<dynamic> peersList = arguments['peers'] ?? [];
      _peers.clear();
      
      for (var peerData in peersList) {
        final device = WiFiDirectDevice.fromMap(peerData);
        _peers.add(device);
        _peerFoundController.add(device);
      }
      
      _peersController.add(List.from(_peers));
      debugPrint('📡 WiFi Direct peers updated: ${_peers.length} devices');
    } catch (e) {
      debugPrint('❌ Error handling peers changed: $e');
    }
  }

  void _handleConnectionChanged(dynamic arguments) {
    try {
      final connectionData = arguments as Map<String, dynamic>;
      _connectionInfo = WiFiDirectConnectionInfo.fromMap(connectionData);
      _isGroupOwner = _connectionInfo!.isGroupOwner;
      
      if (_connectionInfo!.isConnected) {
        // Find connected peer
        _connectedPeer = _peers.firstWhere(
          (peer) => peer.deviceAddress == connectionData['peerAddress'],
          orElse: () => WiFiDirectDevice(
            deviceAddress: connectionData['peerAddress'] ?? 'unknown',
            deviceName: connectionData['peerName'] ?? 'Unknown Device',
            status: 'CONNECTED',
          ),
        );
        debugPrint('✅ WiFi Direct connected to ${_connectedPeer?.deviceName}');
      } else {
        _connectedPeer = null;
        debugPrint('🔌 WiFi Direct disconnected');
      }
      
      _connectionController.add(_connectionInfo!);
    } catch (e) {
      debugPrint('❌ Error handling connection changed: $e');
    }
  }

  void _handleDataReceived(dynamic arguments) {
    try {
      final messageData = {
        'data': arguments['data'],
        'senderAddress': arguments['senderAddress'],
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _messageController.add(messageData);
      debugPrint('📨 Data received via WiFi Direct');
    } catch (e) {
      debugPrint('❌ Error handling received data: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _peersController.close();
    _peerFoundController.close();
    _peerLostController.close();
    _messageController.close();
    _connectionController.close();
    _peers.clear();
  }
}

/// WiFi Direct connection information
class WiFiDirectConnectionInfo {
  final bool isConnected;
  final bool isGroupOwner;
  final String groupOwnerAddress;
  final int groupOwnerPort;
  
  const WiFiDirectConnectionInfo({
    required this.isConnected,
    required this.isGroupOwner,
    required this.groupOwnerAddress,
    this.groupOwnerPort = 8888,
  });
  
  factory WiFiDirectConnectionInfo.fromMap(Map<String, dynamic> map) {
    return WiFiDirectConnectionInfo(
      isConnected: map['isConnected'] ?? false,
      isGroupOwner: map['isGroupOwner'] ?? false,
      groupOwnerAddress: map['groupOwnerAddress'] ?? '',
      groupOwnerPort: map['groupOwnerPort'] ?? 8888,
    );
  }
}

/// WiFi Direct device information
class WiFiDirectDevice {
  final String deviceAddress;
  final String deviceName;
  final String status;

  WiFiDirectDevice({
    required this.deviceAddress,
    required this.deviceName,
    required this.status,
  });

  factory WiFiDirectDevice.fromMap(Map<String, dynamic> map) {
    return WiFiDirectDevice(
      deviceAddress: map['deviceAddress'] ?? '',
      deviceName: map['deviceName'] ?? 'Unknown Device',
      status: map['status'] ?? 'AVAILABLE',
    );
  }
}