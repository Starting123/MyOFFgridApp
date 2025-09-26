import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_models.dart';

class LocalDatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'offgrid_sos.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Messages table
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        senderName TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        content TEXT NOT NULL,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        metadata TEXT,
        filePath TEXT,
        latitude REAL,
        longitude REAL,
        isEmergency INTEGER NOT NULL DEFAULT 0,
        syncedToCloud INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Nearby devices table
    await db.execute('''
      CREATE TABLE nearby_devices(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role INTEGER NOT NULL,
        isSOSActive INTEGER NOT NULL DEFAULT 0,
        isRescuerActive INTEGER NOT NULL DEFAULT 0,
        lastSeen INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        signalStrength INTEGER NOT NULL DEFAULT 0,
        isConnected INTEGER NOT NULL DEFAULT 0,
        connectionType TEXT NOT NULL
      )
    ''');

    // Chat conversations table
    await db.execute('''
      CREATE TABLE conversations(
        id TEXT PRIMARY KEY,
        participantId TEXT NOT NULL,
        participantName TEXT NOT NULL,
        lastMessage TEXT,
        lastMessageTime INTEGER,
        unreadCount INTEGER NOT NULL DEFAULT 0,
        isEmergencyChat INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // File cache table for offline access
    await db.execute('''
      CREATE TABLE file_cache(
        id TEXT PRIMARY KEY,
        messageId TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileSize INTEGER NOT NULL,
        mimeType TEXT,
        downloadedAt INTEGER NOT NULL,
        FOREIGN KEY (messageId) REFERENCES messages (id)
      )
    ''');
  }

  // Message operations
  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'receiverId': message.receiverId,
        'content': message.content,
        'type': message.type.index,
        'status': message.status.index,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'metadata': message.metadata != null ? jsonEncode(message.metadata) : null,
        'filePath': message.filePath,
        'latitude': message.latitude,
        'longitude': message.longitude,
        'isEmergency': message.isEmergency ? 1 : 0,
        'syncedToCloud': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getMessagesForConversation(String participantId, {int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [participantId, _getCurrentDeviceId(), _getCurrentDeviceId(), participantId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ChatMessage(
        id: map['id'],
        senderId: map['senderId'],
        senderName: map['senderName'],
        receiverId: map['receiverId'],
        content: map['content'],
        type: MessageType.values[map['type']],
        status: MessageStatus.values[map['status']],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
        filePath: map['filePath'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        isEmergency: map['isEmergency'] == 1,
      );
    }).reversed.toList();
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<ChatMessage>> getPendingMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'status IN (?, ?)',
      whereArgs: [MessageStatus.sending.index, MessageStatus.failed.index],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ChatMessage(
        id: map['id'],
        senderId: map['senderId'],
        senderName: map['senderName'],
        receiverId: map['receiverId'],
        content: map['content'],
        type: MessageType.values[map['type']],
        status: MessageStatus.values[map['status']],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
        filePath: map['filePath'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        isEmergency: map['isEmergency'] == 1,
      );
    });
  }

  Future<List<ChatMessage>> getAllMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
      limit: 1000,
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ChatMessage(
        id: map['id'],
        senderId: map['senderId'],
        senderName: map['senderName'],
        receiverId: map['receiverId'],
        content: map['content'],
        type: MessageType.values[map['type']],
        status: MessageStatus.values[map['status']],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
        filePath: map['filePath'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        isEmergency: map['isEmergency'] == 1,
      );
    });
  }

  // Insert message with pending status for later delivery
  Future<void> insertPendingMessage(ChatMessage message) async {
    final messageWithPendingStatus = message.copyWith(status: MessageStatus.sending);
    await insertMessage(messageWithPendingStatus);
  }

  // Deliver pending messages (mark as sent when delivered)
  Future<List<ChatMessage>> deliverPendingMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'status = ?',
      whereArgs: [MessageStatus.sending.index],
      orderBy: 'timestamp ASC',
    );

    final pendingMessages = List.generate(maps.length, (i) {
      final map = maps[i];
      return ChatMessage(
        id: map['id'],
        senderId: map['senderId'],
        senderName: map['senderName'],
        receiverId: map['receiverId'],
        content: map['content'],
        type: MessageType.values[map['type']],
        status: MessageStatus.values[map['status']],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
        filePath: map['filePath'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        isEmergency: map['isEmergency'] == 1,
      );
    });

    // Mark pending messages as sent after successful delivery
    for (final message in pendingMessages) {
      await updateMessageStatus(message.id, MessageStatus.sent);
    }

    return pendingMessages;
  }

  // Mark message as synced to cloud
  Future<void> markMessageSynced(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'status': MessageStatus.synced.index,
        'syncedToCloud': 1,
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Get messages that need cloud sync
  Future<List<ChatMessage>> getUnsyncedMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'syncedToCloud = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ChatMessage(
        id: map['id'],
        senderId: map['senderId'],
        senderName: map['senderName'],
        receiverId: map['receiverId'],
        content: map['content'],
        type: MessageType.values[map['type']],
        status: MessageStatus.values[map['status']],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
        filePath: map['filePath'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        isEmergency: map['isEmergency'] == 1,
      );
    });
  }

  // Nearby devices operations
  Future<void> insertOrUpdateNearbyDevice(NearbyDevice device) async {
    final db = await database;
    await db.insert(
      'nearby_devices',
      {
        'id': device.id,
        'name': device.name,
        'role': device.role.index,
        'isSOSActive': device.isSOSActive ? 1 : 0,
        'isRescuerActive': device.isRescuerActive ? 1 : 0,
        'lastSeen': device.lastSeen.millisecondsSinceEpoch,
        'latitude': device.latitude,
        'longitude': device.longitude,
        'signalStrength': device.signalStrength,
        'isConnected': device.isConnected ? 1 : 0,
        'connectionType': device.connectionType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NearbyDevice>> getNearbyDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'nearby_devices',
      orderBy: 'lastSeen DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return NearbyDevice(
        id: map['id'],
        name: map['name'],
        role: DeviceRole.values[map['role']],
        isSOSActive: map['isSOSActive'] == 1,
        isRescuerActive: map['isRescuerActive'] == 1,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen']),
        latitude: map['latitude'],
        longitude: map['longitude'],
        signalStrength: map['signalStrength'],
        isConnected: map['isConnected'] == 1,
        connectionType: map['connectionType'],
      );
    });
  }

  Future<void> removeOldNearbyDevices(Duration maxAge) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    await db.delete(
      'nearby_devices',
      where: 'lastSeen < ?',
      whereArgs: [cutoffTime],
    );
  }

  // Conversation operations
  Future<void> updateConversation(String participantId, String participantName, 
      String lastMessage, DateTime lastMessageTime, {bool isEmergency = false}) async {
    final db = await database;
    await db.insert(
      'conversations',
      {
        'id': participantId,
        'participantId': participantId,
        'participantName': participantName,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
        'unreadCount': 0,
        'isEmergencyChat': isEmergency ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await database;
    return await db.query(
      'conversations',
      orderBy: 'lastMessageTime DESC',
    );
  }

  // Emergency operations
  Future<List<ChatMessage>> getEmergencyMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'isEmergency = 1',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ChatMessage(
        id: map['id'],
        senderId: map['senderId'],
        senderName: map['senderName'],
        receiverId: map['receiverId'],
        content: map['content'],
        type: MessageType.values[map['type']],
        status: MessageStatus.values[map['status']],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
        filePath: map['filePath'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        isEmergency: map['isEmergency'] == 1,
      );
    });
  }

  Future<List<NearbyDevice>> getSOSDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'nearby_devices',
      where: 'isSOSActive = 1',
      orderBy: 'lastSeen DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return NearbyDevice(
        id: map['id'],
        name: map['name'],
        role: DeviceRole.values[map['role']],
        isSOSActive: map['isSOSActive'] == 1,
        isRescuerActive: map['isRescuerActive'] == 1,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen']),
        latitude: map['latitude'],
        longitude: map['longitude'],
        signalStrength: map['signalStrength'],
        isConnected: map['isConnected'] == 1,
        connectionType: map['connectionType'],
      );
    });
  }

  Future<List<NearbyDevice>> getRescuerDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'nearby_devices',
      where: 'isRescuerActive = 1',
      orderBy: 'signalStrength DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return NearbyDevice(
        id: map['id'],
        name: map['name'],
        role: DeviceRole.values[map['role']],
        isSOSActive: map['isSOSActive'] == 1,
        isRescuerActive: map['isRescuerActive'] == 1,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen']),
        latitude: map['latitude'],
        longitude: map['longitude'],
        signalStrength: map['signalStrength'],
        isConnected: map['isConnected'] == 1,
        connectionType: map['connectionType'],
      );
    });
  }

  // File cache operations
  Future<void> cacheFile(String messageId, String filePath, int fileSize, String? mimeType) async {
    final db = await database;
    await db.insert(
      'file_cache',
      {
        'id': '$messageId-${DateTime.now().millisecondsSinceEpoch}',
        'messageId': messageId,
        'filePath': filePath,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCachedFilePath(String messageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'file_cache',
      where: 'messageId = ?',
      whereArgs: [messageId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['filePath'];
    }
    return null;
  }

  // Utility methods
  String _getCurrentDeviceId() {
    // This should be implemented to return current device ID
    // For now, return a placeholder
    return 'current_device_id';
  }

  Future<void> clearAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('nearby_devices');
    await db.delete('conversations');
    await db.delete('file_cache');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}