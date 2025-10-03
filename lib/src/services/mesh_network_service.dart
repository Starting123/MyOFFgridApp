import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/chat_models.dart';
import '../utils/logger.dart';

/// Production-ready Multi-hop Mesh Network Service
/// Handles message routing through intermediate devices with loop prevention
class MeshNetworkService {
  static final MeshNetworkService _instance = MeshNetworkService._internal();
  static MeshNetworkService get instance => _instance;
  MeshNetworkService._internal();

  // Routing table: deviceId -> List of next-hop devices
  final Map<String, List<String>> _routingTable = {};
  
  // Connected neighbors: deviceId -> connection info
  final Map<String, MeshNode> _neighbors = {};
  
  // Message cache to prevent loops (messageId -> timestamp)
  final Map<String, DateTime> _messageCache = {};
  
  // Network topology
  final Map<String, Set<String>> _networkTopology = {};
  
  // Stream controllers
  final StreamController<List<MeshNode>> _topologyController = 
      StreamController<List<MeshNode>>.broadcast();
  final StreamController<MeshMessage> _messageController = 
      StreamController<MeshMessage>.broadcast();
  
  // Configuration
  static const int maxTTL = 10;
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  
  Timer? _cleanupTimer;
  Timer? _heartbeatTimer;
  String? _myDeviceId;
  
  // Connection handler for sending messages through physical protocols
  Future<bool> Function(String deviceId, MeshMessage message, String connectionType)? _connectionHandler;

  // Public streams
  Stream<List<MeshNode>> get topologyStream => _topologyController.stream;
  Stream<MeshMessage> get messageStream => _messageController.stream;
  
  /// Set connection handler for sending messages through physical protocols
  void setConnectionHandler(Future<bool> Function(String deviceId, MeshMessage message, String connectionType) handler) {
    _connectionHandler = handler;
  }
  
  /// Initialize mesh network service
  Future<bool> initialize(String deviceId) async {
    try {
      _myDeviceId = deviceId;
      
      // Start periodic cleanup of old messages
      _cleanupTimer = Timer.periodic(cacheTimeout, (_) => _cleanupMessageCache());
      
      // Start heartbeat for topology updates
      _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) => _sendHeartbeat());
      
      Logger.info('🕸️ MeshNetworkService initialized for device: $deviceId');
      return true;
    } catch (e) {
      Logger.error('❌ Failed to initialize MeshNetworkService: $e');
      return false;
    }
  }

  /// Add a direct neighbor connection
  void addNeighbor(String deviceId, String deviceName, {
    required String connectionType,
    required int signalStrength,
  }) {
    final node = MeshNode(
      deviceId: deviceId,
      deviceName: deviceName,
      connectionType: connectionType,
      signalStrength: signalStrength,
      lastSeen: DateTime.now(),
      isDirectConnection: true,
    );
    
    _neighbors[deviceId] = node;
    _updateRoutingTable();
    _broadcastTopologyUpdate();
    
    Logger.info('🔗 Added mesh neighbor: $deviceName ($deviceId)');
  }

  /// Remove a neighbor (disconnected)
  void removeNeighbor(String deviceId) {
    _neighbors.remove(deviceId);
    _networkTopology.remove(deviceId);
    _updateRoutingTable();
    _broadcastTopologyUpdate();
    
    Logger.info('🔌 Removed mesh neighbor: $deviceId');
  }

  /// Route a message through the mesh network
  Future<bool> routeMessage(MeshMessage message) async {
    try {
      // Check if we've already processed this message (loop prevention)
      if (_isMessageProcessed(message.id)) {
        Logger.debug('🔄 Message already processed, skipping: ${message.id}');
        return false;
      }

      // Add to cache to prevent future loops
      _messageCache[message.id] = DateTime.now();

      // Check TTL
      if (message.ttl <= 0) {
        Logger.debug('⏰ Message TTL expired: ${message.id}');
        return false;
      }

      // If this message is for us, deliver it
      if (message.targetDeviceId == _myDeviceId || message.targetDeviceId == 'broadcast') {
        _deliverMessage(message);
        
        // Continue forwarding if it's a broadcast
        if (message.targetDeviceId == 'broadcast') {
          await _forwardMessage(message);
        }
        return true;
      }

      // Forward the message to next hop
      return await _forwardMessage(message);
    } catch (e) {
      Logger.error('❌ Error routing message: $e');
      return false;
    }
  }

  /// Send a message through the mesh
  Future<bool> sendMessage(ChatMessage chatMessage, {String? targetDeviceId}) async {
    final meshMessage = MeshMessage(
      id: '${_myDeviceId}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      sourceDeviceId: _myDeviceId!,
      targetDeviceId: targetDeviceId ?? 'broadcast',
      chatMessage: chatMessage,
      ttl: maxTTL,
      timestamp: DateTime.now(),
      routePath: [_myDeviceId!],
    );

    return await routeMessage(meshMessage);
  }

  /// Send SOS broadcast through mesh
  Future<bool> broadcastSOS(ChatMessage sosMessage) async {
    final meshMessage = MeshMessage(
      id: 'SOS_${_myDeviceId}_${DateTime.now().millisecondsSinceEpoch}',
      sourceDeviceId: _myDeviceId!,
      targetDeviceId: 'broadcast',
      chatMessage: sosMessage,
      ttl: maxTTL,
      timestamp: DateTime.now(),
      routePath: [_myDeviceId!],
      priority: MessagePriority.emergency,
    );

    Logger.info('🆘 Broadcasting SOS through mesh network');
    return await routeMessage(meshMessage);
  }

  /// Forward message to next hops
  Future<bool> _forwardMessage(MeshMessage message) async {
    if (message.ttl <= 1) {
      Logger.debug('⏰ Cannot forward - TTL too low: ${message.id}');
      return false;
    }

    final nextHops = _findNextHops(message.targetDeviceId);
    if (nextHops.isEmpty) {
      Logger.debug('🚫 No route found for message: ${message.id}');
      return false;
    }

    bool anySuccess = false;
    final forwardedMessage = message.copyWith(
      ttl: message.ttl - 1,
      routePath: [...message.routePath, _myDeviceId!],
    );

    for (final nextHop in nextHops) {
      // Don't forward back to sender
      if (message.routePath.contains(nextHop)) continue;

      try {
        final success = await _sendToNeighbor(nextHop, forwardedMessage);
        if (success) {
          anySuccess = true;
          Logger.debug('📤 Forwarded message ${message.id} to $nextHop');
        }
      } catch (e) {
        Logger.error('❌ Failed to forward to $nextHop: $e');
      }
    }

    return anySuccess;
  }

  /// Find next hops for a target device
  List<String> _findNextHops(String targetDeviceId) {
    if (targetDeviceId == 'broadcast') {
      // Broadcast to all direct neighbors
      return _neighbors.keys.toList();
    }

    // Use routing table to find path
    return _routingTable[targetDeviceId] ?? [];
  }

  /// Send message to a specific neighbor
  Future<bool> _sendToNeighbor(String neighborId, MeshMessage message) async {
    final neighbor = _neighbors[neighborId];
    if (neighbor == null) return false;

    try {
      // Serialize message
      final messageJson = jsonEncode(message.toJson());
      
      // Send through appropriate service based on connection type
      // This will be handled by ServiceCoordinator
      return await _sendThroughConnection(neighbor.connectionType, neighborId, messageJson);
    } catch (e) {
      Logger.error('❌ Failed to send to neighbor $neighborId: $e');
      return false;
    }
  }

  /// Send through specific connection type
  Future<bool> _sendThroughConnection(String connectionType, String deviceId, String data) async {
    if (_connectionHandler != null) {
      // Convert the data string back to MeshMessage for the handler
      try {
        final messageData = jsonDecode(data);
        final chatMessage = ChatMessage.fromJson(messageData['chatMessage']);
        final meshMessage = MeshMessage(
          id: messageData['id'],
          sourceDeviceId: messageData['sourceDeviceId'],
          targetDeviceId: messageData['targetDeviceId'],
          chatMessage: chatMessage,
          ttl: messageData['ttl'],
          timestamp: DateTime.parse(messageData['timestamp']),
          routePath: List<String>.from(messageData['routePath']),
        );
        return await _connectionHandler!(deviceId, meshMessage, connectionType);
      } catch (e) {
        Logger.error('❌ Failed to parse message for connection handler: $e');
        return false;
      }
    }
    
    Logger.debug('📡 No connection handler set, cannot send via $connectionType to $deviceId');
    return false;
  }

  /// Deliver message to local application
  void _deliverMessage(MeshMessage message) {
    Logger.info('📨 Delivering message: ${message.chatMessage.content}');
    _messageController.add(message);
  }

  /// Check if message was already processed
  bool _isMessageProcessed(String messageId) {
    return _messageCache.containsKey(messageId);
  }

  /// Update routing table based on network topology
  void _updateRoutingTable() {
    _routingTable.clear();
    
    // Use Dijkstra's algorithm for shortest path
    for (final targetDevice in _networkTopology.keys) {
      if (targetDevice == _myDeviceId) continue;
      
      final path = _findShortestPath(_myDeviceId!, targetDevice);
      if (path.isNotEmpty && path.length > 1) {
        _routingTable[targetDevice] = [path[1]]; // Next hop
      }
    }

    Logger.debug('🗺️ Routing table updated: ${_routingTable.length} routes');
  }

  /// Find shortest path using Dijkstra's algorithm
  List<String> _findShortestPath(String source, String target) {
    if (source == target) return [source];
    
    final visited = <String>{};
    final distances = <String, int>{};
    final previous = <String, String?>{};
    final queue = <String>[];

    // Initialize
    for (final device in _networkTopology.keys) {
      distances[device] = device == source ? 0 : double.maxFinite.toInt();
      previous[device] = null;
      queue.add(device);
    }

    while (queue.isNotEmpty) {
      // Find minimum distance node
      queue.sort((a, b) => distances[a]!.compareTo(distances[b]!));
      final current = queue.removeAt(0);
      
      if (visited.contains(current)) continue;
      visited.add(current);

      if (current == target) break;

      // Check neighbors
      final neighbors = _networkTopology[current] ?? <String>{};
      for (final neighbor in neighbors) {
        if (visited.contains(neighbor)) continue;
        
        final altDistance = distances[current]! + 1;
        if (altDistance < distances[neighbor]!) {
          distances[neighbor] = altDistance;
          previous[neighbor] = current;
        }
      }
    }

    // Reconstruct path
    final path = <String>[];
    String? current = target;
    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    return path.isEmpty || path.first != source ? [] : path;
  }

  /// Update network topology from neighbor information
  void updateTopology(String deviceId, List<String> neighborIds) {
    _networkTopology[deviceId] = neighborIds.toSet();
    _updateRoutingTable();
    _broadcastTopologyUpdate();
  }

  /// Send heartbeat to maintain topology
  void _sendHeartbeat() {
    if (_myDeviceId == null) return;
    
    final heartbeat = {
      'type': 'heartbeat',
      'deviceId': _myDeviceId,
      'timestamp': DateTime.now().toIso8601String(),
      'neighbors': _neighbors.keys.toList(),
    };

    // Broadcast heartbeat to neighbors
    for (final neighborId in _neighbors.keys) {
      _sendThroughConnection(_neighbors[neighborId]!.connectionType, neighborId, jsonEncode(heartbeat));
    }
  }

  /// Broadcast topology update
  void _broadcastTopologyUpdate() {
    final nodes = _neighbors.values.toList();
    _topologyController.add(nodes);
  }

  /// Clean up old messages from cache
  void _cleanupMessageCache() {
    final now = DateTime.now();
    _messageCache.removeWhere((messageId, timestamp) {
      return now.difference(timestamp) > cacheTimeout;
    });
    
    Logger.debug('🧹 Cleaned up message cache: ${_messageCache.length} messages remaining');
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    return {
      'directNeighbors': _neighbors.length,
      'routingTableEntries': _routingTable.length,
      'cachedMessages': _messageCache.length,
      'networkNodes': _networkTopology.length,
      'myDeviceId': _myDeviceId,
    };
  }

  /// Dispose of resources
  void dispose() {
    _cleanupTimer?.cancel();
    _heartbeatTimer?.cancel();
    _topologyController.close();
    _messageController.close();
    _neighbors.clear();
    _routingTable.clear();
    _messageCache.clear();
    _networkTopology.clear();
    
    Logger.info('🗑️ MeshNetworkService disposed');
  }
}

/// Mesh network node representation
class MeshNode {
  final String deviceId;
  final String deviceName;
  final String connectionType;
  final int signalStrength;
  final DateTime lastSeen;
  final bool isDirectConnection;

  const MeshNode({
    required this.deviceId,
    required this.deviceName,
    required this.connectionType,
    required this.signalStrength,
    required this.lastSeen,
    required this.isDirectConnection,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'connectionType': connectionType,
    'signalStrength': signalStrength,
    'lastSeen': lastSeen.toIso8601String(),
    'isDirectConnection': isDirectConnection,
  };

  factory MeshNode.fromJson(Map<String, dynamic> json) => MeshNode(
    deviceId: json['deviceId'],
    deviceName: json['deviceName'],
    connectionType: json['connectionType'],
    signalStrength: json['signalStrength'],
    lastSeen: DateTime.parse(json['lastSeen']),
    isDirectConnection: json['isDirectConnection'],
  );
}

/// Mesh message wrapper for routing
class MeshMessage {
  final String id;
  final String sourceDeviceId;
  final String targetDeviceId;
  final ChatMessage chatMessage;
  final int ttl;
  final DateTime timestamp;
  final List<String> routePath;
  final MessagePriority priority;

  const MeshMessage({
    required this.id,
    required this.sourceDeviceId,
    required this.targetDeviceId,
    required this.chatMessage,
    required this.ttl,
    required this.timestamp,
    required this.routePath,
    this.priority = MessagePriority.normal,
  });

  MeshMessage copyWith({
    String? id,
    String? sourceDeviceId,
    String? targetDeviceId,
    ChatMessage? chatMessage,
    int? ttl,
    DateTime? timestamp,
    List<String>? routePath,
    MessagePriority? priority,
  }) => MeshMessage(
    id: id ?? this.id,
    sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
    targetDeviceId: targetDeviceId ?? this.targetDeviceId,
    chatMessage: chatMessage ?? this.chatMessage,
    ttl: ttl ?? this.ttl,
    timestamp: timestamp ?? this.timestamp,
    routePath: routePath ?? this.routePath,
    priority: priority ?? this.priority,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceDeviceId': sourceDeviceId,
    'targetDeviceId': targetDeviceId,
    'chatMessage': chatMessage.toJson(),
    'ttl': ttl,
    'timestamp': timestamp.toIso8601String(),
    'routePath': routePath,
    'priority': priority.index,
  };

  factory MeshMessage.fromJson(Map<String, dynamic> json) => MeshMessage(
    id: json['id'],
    sourceDeviceId: json['sourceDeviceId'],
    targetDeviceId: json['targetDeviceId'],
    chatMessage: ChatMessage.fromJson(json['chatMessage']),
    ttl: json['ttl'],
    timestamp: DateTime.parse(json['timestamp']),
    routePath: List<String>.from(json['routePath']),
    priority: MessagePriority.values[json['priority'] ?? 0],
  );
}

/// Message priority levels
enum MessagePriority {
  normal,
  high,
  emergency,
}