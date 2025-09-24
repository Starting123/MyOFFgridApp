import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service for mesh networking to relay messages through intermediate nodes
class MeshNetworkingService {
  static final MeshNetworkingService _instance = MeshNetworkingService._internal();
  static MeshNetworkingService get instance => _instance;
  MeshNetworkingService._internal();

  final Set<String> _knownNodes = <String>{};
  final Map<String, DateTime> _nodeLastSeen = <String, DateTime>{};
  final Map<String, Set<String>> _nodeConnections = <String, Set<String>>{};
  final Map<String, MeshMessage> _messageCache = <String, MeshMessage>{};
  final Map<String, int> _messageTtl = <String, int>{};
  final Queue<MeshMessage> _outgoingQueue = Queue<MeshMessage>();
  
  String? _nodeId;
  bool _isActive = false;
  
  // Configuration
  static const int maxTtl = 10; // Maximum hops for message propagation
  static const int nodeTimeoutMinutes = 30; // Node considered offline after 30 minutes
  static const int maxCacheSize = 1000; // Maximum cached messages
  static const Duration heartbeatInterval = Duration(minutes: 5);
  static const Duration retransmissionDelay = Duration(seconds: 30);

  // Event listeners
  final List<Function(MeshMessage)> _messageReceivedListeners = [];
  final List<Function(String)> _nodeJoinedListeners = [];
  final List<Function(String)> _nodeLeftListeners = [];
  final List<Function(List<String>)> _topologyChangedListeners = [];

  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;

  /// Initialize mesh networking with unique node ID
  Future<void> initialize(String nodeId) async {
    _nodeId = nodeId;
    _knownNodes.add(nodeId);
    _nodeLastSeen[nodeId] = DateTime.now();
    _nodeConnections[nodeId] = <String>{};
    
    _isActive = true;
    
    // Start periodic tasks
    _startHeartbeat();
    _startCleanupTimer();
    
    debugPrint('Mesh networking initialized for node: $nodeId');
  }

  /// Start heartbeat to maintain node presence
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) {
      _sendHeartbeat();
    });
  }

  /// Start cleanup timer for expired nodes and messages
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _cleanupExpiredData();
    });
  }

  /// Send heartbeat to announce node presence
  void _sendHeartbeat() {
    if (!_isActive || _nodeId == null) return;

    final heartbeat = MeshMessage(
      id: 'heartbeat_${_nodeId}_${DateTime.now().millisecondsSinceEpoch}',
      type: MeshMessageType.heartbeat,
      sourceNode: _nodeId!,
      targetNode: 'broadcast',
      payload: jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'connections': _nodeConnections[_nodeId!]?.toList() ?? [],
      }),
      ttl: 2, // Heartbeats don't need to travel far
      timestamp: DateTime.now(),
    );

    broadcastMessage(heartbeat);
  }

  /// Add a direct connection to another node
  void addDirectConnection(String nodeId) {
    if (_nodeId == null || nodeId == _nodeId) return;

    _nodeConnections[_nodeId!] ??= <String>{};
    _nodeConnections[_nodeId!]!.add(nodeId);
    
    if (!_knownNodes.contains(nodeId)) {
      _knownNodes.add(nodeId);
      _notifyNodeJoined(nodeId);
    }
    
    _nodeLastSeen[nodeId] = DateTime.now();
    _notifyTopologyChanged();
    
    debugPrint('Direct connection added to node: $nodeId');
  }

  /// Remove direct connection to another node
  void removeDirectConnection(String nodeId) {
    if (_nodeId == null) return;

    _nodeConnections[_nodeId!]?.remove(nodeId);
    _notifyTopologyChanged();
    
    debugPrint('Direct connection removed from node: $nodeId');
  }

  /// Send message through mesh network
  Future<bool> sendMessage(String messageContent, String targetNodeId) async {
    if (!_isActive || _nodeId == null) return false;

    final meshMessage = MeshMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      type: MeshMessageType.userMessage,
      sourceNode: _nodeId!,
      targetNode: targetNodeId,
      payload: messageContent,
      ttl: maxTtl,
      timestamp: DateTime.now(),
    );

    return await routeMessage(meshMessage);
  }

  /// Broadcast message to all reachable nodes
  void broadcastMessage(MeshMessage message) {
    if (!_isActive || _nodeId == null) return;

    _cacheMessage(message);
    _outgoingQueue.add(message);
    
    // Simulate sending to directly connected nodes
    final directConnections = _nodeConnections[_nodeId!] ?? <String>{};
    for (String nodeId in directConnections) {
      _simulateSendToNode(nodeId, message);
    }
  }

  /// Route message to target node through optimal path
  Future<bool> routeMessage(MeshMessage message) async {
    if (!_isActive || message.ttl <= 0) return false;

    // Check if message already processed
    if (_messageCache.containsKey(message.id)) {
      return false; // Avoid loops
    }

    _cacheMessage(message);

    // If this is the target node, deliver message
    if (message.targetNode == _nodeId || message.targetNode == 'broadcast') {
      _deliverMessage(message);
      
      // Continue broadcasting if it's a broadcast message
      if (message.targetNode == 'broadcast') {
        _forwardMessage(message);
      }
      
      return true;
    }

    // Forward message towards target
    return _forwardMessage(message);
  }

  /// Forward message to next hop
  bool _forwardMessage(MeshMessage message) {
    if (message.ttl <= 1) return false;

    // Create forwarded message with reduced TTL
    final forwardedMessage = message.copyWith(
      ttl: message.ttl - 1,
      path: [...message.path, _nodeId!],
    );

    // Find best next hop
    String? nextHop = _findNextHop(message.targetNode);
    
    if (nextHop != null) {
      _simulateSendToNode(nextHop, forwardedMessage);
      return true;
    } else {
      // No direct route, broadcast to all connections
      final directConnections = _nodeConnections[_nodeId!] ?? <String>{};
      bool sent = false;
      
      for (String nodeId in directConnections) {
        if (!forwardedMessage.path.contains(nodeId)) {
          _simulateSendToNode(nodeId, forwardedMessage);
          sent = true;
        }
      }
      
      return sent;
    }
  }

  /// Find next hop towards target node
  String? _findNextHop(String targetNode) {
    // Simple implementation - return direct connection if available
    final directConnections = _nodeConnections[_nodeId!] ?? <String>{};
    
    if (directConnections.contains(targetNode)) {
      return targetNode;
    }
    
    // In a real implementation, this would use routing protocols
    // For now, just return the first available connection
    return directConnections.isNotEmpty ? directConnections.first : null;
  }

  /// Simulate sending message to specific node
  void _simulateSendToNode(String nodeId, MeshMessage message) {
    // In a real implementation, this would use the actual communication layer
    // (WiFi Direct, Bluetooth, etc.)
    debugPrint('Sending message ${message.id} to node $nodeId');
    
    // Simulate delay and potential delivery
    Timer(const Duration(milliseconds: 100), () {
      if (_knownNodes.contains(nodeId)) {
        debugPrint('Message ${message.id} delivered to $nodeId');
      }
    });
  }

  /// Deliver message to local node
  void _deliverMessage(MeshMessage message) {
    debugPrint('Message delivered locally: ${message.id}');
    
    if (message.type == MeshMessageType.userMessage) {
      // Notify listeners about received user message
      for (var listener in _messageReceivedListeners) {
        listener(message);
      }
    } else if (message.type == MeshMessageType.heartbeat) {
      _processHeartbeat(message);
    }
  }

  /// Process heartbeat message
  void _processHeartbeat(MeshMessage message) {
    String sourceNode = message.sourceNode;
    
    if (!_knownNodes.contains(sourceNode)) {
      _knownNodes.add(sourceNode);
      _notifyNodeJoined(sourceNode);
    }
    
    _nodeLastSeen[sourceNode] = DateTime.now();
    
    // Update topology information
    try {
      Map<String, dynamic> data = jsonDecode(message.payload);
      List<String> connections = List<String>.from(data['connections'] ?? []);
      _nodeConnections[sourceNode] = connections.toSet();
      _notifyTopologyChanged();
    } catch (e) {
      debugPrint('Error processing heartbeat: $e');
    }
  }

  /// Cache message to prevent loops
  void _cacheMessage(MeshMessage message) {
    if (_messageCache.length >= maxCacheSize) {
      // Remove oldest message
      String oldestKey = _messageCache.keys.first;
      _messageCache.remove(oldestKey);
      _messageTtl.remove(oldestKey);
    }
    
    _messageCache[message.id] = message;
    _messageTtl[message.id] = message.ttl;
  }

  /// Clean up expired nodes and messages
  void _cleanupExpiredData() {
    final now = DateTime.now();
    final expiredNodes = <String>[];
    
    // Find expired nodes
    _nodeLastSeen.forEach((nodeId, lastSeen) {
      if (nodeId != _nodeId && 
          now.difference(lastSeen).inMinutes > nodeTimeoutMinutes) {
        expiredNodes.add(nodeId);
      }
    });
    
    // Remove expired nodes
    for (String nodeId in expiredNodes) {
      _knownNodes.remove(nodeId);
      _nodeLastSeen.remove(nodeId);
      _nodeConnections.remove(nodeId);
      _notifyNodeLeft(nodeId);
    }
    
    if (expiredNodes.isNotEmpty) {
      _notifyTopologyChanged();
      debugPrint('Cleaned up ${expiredNodes.length} expired nodes');
    }
  }

  /// Get network topology
  Map<String, dynamic> getNetworkTopology() {
    return {
      'nodeId': _nodeId,
      'knownNodes': _knownNodes.toList(),
      'connections': Map<String, List<String>>.fromEntries(
        _nodeConnections.entries.map(
          (entry) => MapEntry(entry.key, entry.value.toList()),
        ),
      ),
      'lastSeen': Map<String, String>.fromEntries(
        _nodeLastSeen.entries.map(
          (entry) => MapEntry(entry.key, entry.value.toIso8601String()),
        ),
      ),
    };
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    return {
      'totalNodes': _knownNodes.length,
      'directConnections': _nodeConnections[_nodeId]?.length ?? 0,
      'cachedMessages': _messageCache.length,
      'queuedMessages': _outgoingQueue.length,
      'isActive': _isActive,
    };
  }

  // Event listener management
  void addMessageReceivedListener(Function(MeshMessage) listener) {
    _messageReceivedListeners.add(listener);
  }

  void removeMessageReceivedListener(Function(MeshMessage) listener) {
    _messageReceivedListeners.remove(listener);
  }

  void addNodeJoinedListener(Function(String) listener) {
    _nodeJoinedListeners.add(listener);
  }

  void removeNodeJoinedListener(Function(String) listener) {
    _nodeJoinedListeners.remove(listener);
  }

  void addNodeLeftListener(Function(String) listener) {
    _nodeLeftListeners.add(listener);
  }

  void removeNodeLeftListener(Function(String) listener) {
    _nodeLeftListeners.remove(listener);
  }

  void addTopologyChangedListener(Function(List<String>) listener) {
    _topologyChangedListeners.add(listener);
  }

  void removeTopologyChangedListener(Function(List<String>) listener) {
    _topologyChangedListeners.remove(listener);
  }

  // Event notification methods
  void _notifyNodeJoined(String nodeId) {
    for (var listener in _nodeJoinedListeners) {
      listener(nodeId);
    }
  }

  void _notifyNodeLeft(String nodeId) {
    for (var listener in _nodeLeftListeners) {
      listener(nodeId);
    }
  }

  void _notifyTopologyChanged() {
    List<String> nodes = _knownNodes.toList();
    for (var listener in _topologyChangedListeners) {
      listener(nodes);
    }
  }

  /// Shutdown mesh networking
  void shutdown() {
    _isActive = false;
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    
    _knownNodes.clear();
    _nodeLastSeen.clear();
    _nodeConnections.clear();
    _messageCache.clear();
    _messageTtl.clear();
    _outgoingQueue.clear();
    
    _messageReceivedListeners.clear();
    _nodeJoinedListeners.clear();
    _nodeLeftListeners.clear();
    _topologyChangedListeners.clear();
    
    debugPrint('Mesh networking shutdown');
  }
}

/// Mesh network message
class MeshMessage {
  final String id;
  final MeshMessageType type;
  final String sourceNode;
  final String targetNode;
  final String payload;
  final int ttl;
  final DateTime timestamp;
  final List<String> path;

  MeshMessage({
    required this.id,
    required this.type,
    required this.sourceNode,
    required this.targetNode,
    required this.payload,
    required this.ttl,
    required this.timestamp,
    this.path = const [],
  });

  MeshMessage copyWith({
    String? id,
    MeshMessageType? type,
    String? sourceNode,
    String? targetNode,
    String? payload,
    int? ttl,
    DateTime? timestamp,
    List<String>? path,
  }) {
    return MeshMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      sourceNode: sourceNode ?? this.sourceNode,
      targetNode: targetNode ?? this.targetNode,
      payload: payload ?? this.payload,
      ttl: ttl ?? this.ttl,
      timestamp: timestamp ?? this.timestamp,
      path: path ?? this.path,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'sourceNode': sourceNode,
      'targetNode': targetNode,
      'payload': payload,
      'ttl': ttl,
      'timestamp': timestamp.toIso8601String(),
      'path': path,
    };
  }

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'],
      type: MeshMessageType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => MeshMessageType.userMessage,
      ),
      sourceNode: json['sourceNode'],
      targetNode: json['targetNode'],
      payload: json['payload'],
      ttl: json['ttl'],
      timestamp: DateTime.parse(json['timestamp']),
      path: List<String>.from(json['path'] ?? []),
    );
  }
}

/// Types of mesh messages
enum MeshMessageType {
  userMessage,
  heartbeat,
  routingUpdate,
  acknowledgment,
}