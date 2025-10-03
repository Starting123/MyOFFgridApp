import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_models.dart';

class LocalDatabaseService {
  static Database? _database;
  static const int _currentVersion = 2; // Updated version for migrations
  
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
      version: _currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables for new database
  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  /// Handle database migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToVersion2(db);
    }
  }

  /// Create all database tables
  Future<void> _createAllTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        role TEXT NOT NULL,
        profileImageUrl TEXT,
        lastSeen INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isOnline INTEGER NOT NULL DEFAULT 0,
        isSyncedToCloud INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Devices table (enhanced nearby_devices)
    await db.execute('''
      CREATE TABLE devices(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        role INTEGER NOT NULL,
        userId TEXT,
        isSOSActive INTEGER NOT NULL DEFAULT 0,
        isRescuerActive INTEGER NOT NULL DEFAULT 0,
        lastSeen INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        signalStrength INTEGER NOT NULL DEFAULT 0,
        isConnected INTEGER NOT NULL DEFAULT 0,
        connectionType TEXT NOT NULL,
        batteryLevel INTEGER,
        capabilities TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Enhanced Messages table with mesh routing fields
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        senderName TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        type INTEGER NOT NULL,
        body TEXT NOT NULL,
        filePath TEXT,
        timestamp INTEGER NOT NULL,
        status INTEGER NOT NULL,
        metadata TEXT,
        latitude REAL,
        longitude REAL,
        isEmergency INTEGER NOT NULL DEFAULT 0,
        ttl INTEGER,
        hopCount INTEGER DEFAULT 0,
        requiresAck INTEGER NOT NULL DEFAULT 0,
        visitedNodes TEXT,
        syncedToCloud INTEGER NOT NULL DEFAULT 0,
        chatId TEXT,
        FOREIGN KEY (senderId) REFERENCES users (id),
        FOREIGN KEY (receiverId) REFERENCES users (id)
      )
    ''');

    // Queue items table for reliable message delivery
    await db.execute('''
      CREATE TABLE queue_items(
        id TEXT PRIMARY KEY,
        messageId TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        maxAttempts INTEGER NOT NULL DEFAULT 3,
        nextAttemptAt INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        data TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        errorMessage TEXT,
        FOREIGN KEY (messageId) REFERENCES messages (id)
      )
    ''');

    // Sync logs table for cloud synchronization tracking
    await db.execute('''
      CREATE TABLE sync_logs(
        id TEXT PRIMARY KEY,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        operation TEXT NOT NULL,
        status INTEGER NOT NULL,
        syncedAt INTEGER NOT NULL,
        errorMessage TEXT,
        retryCount INTEGER NOT NULL DEFAULT 0,
        data TEXT
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

    // Blocked users table
    await db.execute('''
      CREATE TABLE blocked_users(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        blocked_at INTEGER NOT NULL,
        UNIQUE(user_id)
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  /// Create database indexes for performance
  Future<void> _createIndexes(Database db) async {
    // Messages indexes
    await db.execute('CREATE INDEX idx_messages_chat_id ON messages(chatId)');
    await db.execute('CREATE INDEX idx_messages_sender_receiver ON messages(senderId, receiverId)');
    await db.execute('CREATE INDEX idx_messages_timestamp ON messages(timestamp)');
    await db.execute('CREATE INDEX idx_messages_status ON messages(status)');
    await db.execute('CREATE INDEX idx_messages_emergency ON messages(isEmergency)');
    
    // Queue items indexes
    await db.execute('CREATE INDEX idx_queue_items_next_attempt ON queue_items(nextAttemptAt)');
    await db.execute('CREATE INDEX idx_queue_items_status ON queue_items(status)');
    
    // Sync logs indexes
    await db.execute('CREATE INDEX idx_sync_logs_entity ON sync_logs(entityType, entityId)');
    await db.execute('CREATE INDEX idx_sync_logs_status ON sync_logs(status)');
    
    // Devices indexes
    await db.execute('CREATE INDEX idx_devices_user_id ON devices(userId)');
    await db.execute('CREATE INDEX idx_devices_last_seen ON devices(lastSeen)');
  }

  /// Migration to version 2 - add missing fields
  Future<void> _migrateToVersion2(Database db) async {
    // Add missing columns to existing messages table
    try {
      await db.execute('ALTER TABLE messages ADD COLUMN ttl INTEGER');
    } catch (e) {
      // Column might already exist
    }
    
    try {
      await db.execute('ALTER TABLE messages ADD COLUMN hopCount INTEGER DEFAULT 0');
    } catch (e) {
      // Column might already exist
    }
    
    try {
      await db.execute('ALTER TABLE messages ADD COLUMN requiresAck INTEGER NOT NULL DEFAULT 0');
    } catch (e) {
      // Column might already exist
    }
    
    try {
      await db.execute('ALTER TABLE messages ADD COLUMN visitedNodes TEXT');
    } catch (e) {
      // Column might already exist
    }
    
    try {
      await db.execute('ALTER TABLE messages ADD COLUMN chatId TEXT');
    } catch (e) {
      // Column might already exist
    }
    
    try {
      // Rename content to body if content exists
      await db.execute('ALTER TABLE messages RENAME COLUMN content TO body');
    } catch (e) {
      // Column might already be renamed or not exist
    }

    // Create new tables if they don't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        role TEXT NOT NULL,
        profileImageUrl TEXT,
        lastSeen INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isOnline INTEGER NOT NULL DEFAULT 0,
        isSyncedToCloud INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS devices(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        role INTEGER NOT NULL,
        userId TEXT,
        isSOSActive INTEGER NOT NULL DEFAULT 0,
        isRescuerActive INTEGER NOT NULL DEFAULT 0,
        lastSeen INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        signalStrength INTEGER NOT NULL DEFAULT 0,
        isConnected INTEGER NOT NULL DEFAULT 0,
        connectionType TEXT NOT NULL,
        batteryLevel INTEGER,
        capabilities TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS queue_items(
        id TEXT PRIMARY KEY,
        messageId TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        maxAttempts INTEGER NOT NULL DEFAULT 3,
        nextAttemptAt INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        data TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        errorMessage TEXT,
        FOREIGN KEY (messageId) REFERENCES messages (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_logs(
        id TEXT PRIMARY KEY,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        operation TEXT NOT NULL,
        status INTEGER NOT NULL,
        syncedAt INTEGER NOT NULL,
        errorMessage TEXT,
        retryCount INTEGER NOT NULL DEFAULT 0,
        data TEXT
      )
    ''');

    // Create indexes for new tables
    await _createIndexes(db);
  }

  // ========== MESSAGE OPERATIONS ==========

  /// Insert message with all new fields
  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'receiverId': message.receiverId,
        'type': message.type.index,
        'body': message.content, // Map content to body
        'filePath': message.filePath,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'status': message.status.index,
        'metadata': message.metadata != null ? jsonEncode(message.metadata) : null,
        'latitude': message.latitude,
        'longitude': message.longitude,
        'isEmergency': message.isEmergency ? 1 : 0,
        'ttl': message.ttl,
        'hopCount': message.hopCount ?? 0,
        'requiresAck': message.requiresAck ? 1 : 0,
        'visitedNodes': null, // Will be populated during routing
        'syncedToCloud': 0,
        'chatId': _generateChatId(message.senderId, message.receiverId),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Watch messages for a specific chat - returns real-time stream
  Stream<List<ChatMessage>> watchMessagesForChat(String chatId) async* {
    // Create initial query
    yield await _getMessagesForChatId(chatId);
    
    // Listen for changes (simplified - in real implementation you'd use database triggers)
    while (true) {
      await Future.delayed(const Duration(seconds: 1)); // Poll every second
      yield await _getMessagesForChatId(chatId);
    }
  }

  /// Get messages for a specific chat ID
  Future<List<ChatMessage>> _getMessagesForChatId(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
      limit: 100,
    );

    return _mapToMessages(maps);
  }

  /// Get messages for conversation (backward compatibility)
  Future<List<ChatMessage>> getMessagesForConversation(String participantId, {int limit = 50}) async {
    final chatId = _generateChatId(_getCurrentDeviceId(), participantId);
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return _mapToMessages(maps).reversed.toList();
  }

  /// Update message with visited nodes for mesh routing
  Future<void> updateMessageRouting(String messageId, {
    int? ttl,
    int? hopCount,
    List<String>? visitedNodes,
  }) async {
    final db = await database;
    final updateData = <String, dynamic>{};
    
    if (ttl != null) updateData['ttl'] = ttl;
    if (hopCount != null) updateData['hopCount'] = hopCount;
    if (visitedNodes != null) updateData['visitedNodes'] = jsonEncode(visitedNodes);
    
    if (updateData.isNotEmpty) {
      await db.update(
        'messages',
        updateData,
        where: 'id = ?',
        whereArgs: [messageId],
      );
    }
  }

  /// Update message status
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Get pending messages for retry
  Future<List<ChatMessage>> getPendingMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'status IN (?, ?)',
      whereArgs: [MessageStatus.sending.index, MessageStatus.failed.index],
      orderBy: 'timestamp ASC',
    );

    return _mapToMessages(maps);
  }

  /// Get all messages
  Future<List<ChatMessage>> getAllMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
      limit: 1000,
    );

    return _mapToMessages(maps);
  }

  /// Map database results to ChatMessage objects
  List<ChatMessage> _mapToMessages(List<Map<String, dynamic>> maps) {
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ChatMessage(
        id: map['id'],
        senderId: map['senderId'],
        senderName: map['senderName'],
        receiverId: map['receiverId'],
        content: map['body'] ?? map['content'] ?? '', // Handle both old and new column names
        type: MessageType.values[map['type']],
        status: MessageStatus.values[map['status']],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
        filePath: map['filePath'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        isEmergency: map['isEmergency'] == 1,
        ttl: map['ttl'],
        hopCount: map['hopCount'] ?? 0,
        requiresAck: (map['requiresAck'] ?? 0) == 1,
      );
    });
  }

  // ========== QUEUE OPERATIONS ==========

  /// Add message to retry queue
  Future<void> addToQueue(String messageId, Map<String, dynamic> data, {int priority = 0}) async {
    final db = await database;
    await db.insert(
      'queue_items',
      {
        'id': 'queue_${DateTime.now().millisecondsSinceEpoch}',
        'messageId': messageId,
        'priority': priority,
        'attempts': 0,
        'maxAttempts': 3,
        'nextAttemptAt': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'data': jsonEncode(data),
        'status': 0, // Pending
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get pending queue items
  Future<List<Map<String, dynamic>>> getPendingQueueItems() async {
    final db = await database;
    return await db.query(
      'queue_items',
      where: 'status = 0 AND nextAttemptAt <= ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
      orderBy: 'priority DESC, createdAt ASC',
    );
  }

  /// Update queue item after attempt
  Future<void> updateQueueItem(String queueId, {bool success = false, String? errorMessage}) async {
    final db = await database;
    if (success) {
      await db.update(
        'queue_items',
        {'status': 1}, // Completed
        where: 'id = ?',
        whereArgs: [queueId],
      );
    } else {
      await db.execute('''
        UPDATE queue_items 
        SET attempts = attempts + 1,
            nextAttemptAt = ?,
            errorMessage = ?
        WHERE id = ?
      ''', [
        DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch,
        errorMessage,
        queueId,
      ]);
    }
  }

  // ========== SYNC LOG OPERATIONS ==========

  /// Add sync log entry
  Future<void> addSyncLog(String entityType, String entityId, String operation, 
      {bool success = true, String? errorMessage, Map<String, dynamic>? data}) async {
    final db = await database;
    await db.insert(
      'sync_logs',
      {
        'id': 'sync_${DateTime.now().millisecondsSinceEpoch}',
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation,
        'status': success ? 1 : 0,
        'syncedAt': DateTime.now().millisecondsSinceEpoch,
        'errorMessage': errorMessage,
        'retryCount': 0,
        'data': data != null ? jsonEncode(data) : null,
      },
    );
  }

  /// Get failed sync logs for retry
  Future<List<Map<String, dynamic>>> getFailedSyncLogs() async {
    final db = await database;
    return await db.query(
      'sync_logs',
      where: 'status = 0 AND retryCount < 3',
      orderBy: 'syncedAt ASC',
    );
  }

  // ========== USER OPERATIONS ==========

  /// Insert or update user
  Future<void> insertOrUpdateUser(Map<String, dynamic> userData) async {
    final db = await database;
    await db.insert(
      'users',
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    return maps.isNotEmpty ? maps.first : null;
  }

  // ========== DEVICE OPERATIONS ==========

  /// Insert or update device
  Future<void> insertOrUpdateDevice(Map<String, dynamic> deviceData) async {
    final db = await database;
    await db.insert(
      'devices',
      deviceData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get devices by user ID
  Future<List<Map<String, dynamic>>> getDevicesByUserId(String userId) async {
    final db = await database;
    return await db.query(
      'devices',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'lastSeen DESC',
    );
  }

  // ========== UTILITY METHODS ==========

  /// Generate chat ID from two user IDs
  String _generateChatId(String userId1, String userId2) {
    final List<String> ids = [userId1, userId2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  /// Get current device ID
  String _getCurrentDeviceId() {
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Mark message as synced to cloud
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

  /// Get unsynced messages
  Future<List<ChatMessage>> getUnsyncedMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'syncedToCloud = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );

    return _mapToMessages(maps);
  }

  /// Clear all data
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('users');
    await db.delete('devices');
    await db.delete('queue_items');
    await db.delete('sync_logs');
    await db.delete('conversations');
    await db.delete('file_cache');
    await db.delete('blocked_users');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Legacy methods for backward compatibility
  Future<void> insertOrUpdateNearbyDevice(NearbyDevice device) async {
    await insertOrUpdateDevice({
      'id': device.id,
      'name': device.name,
      'type': 'nearby',
      'role': device.role.index,
      'isSOSActive': device.isSOSActive ? 1 : 0,
      'isRescuerActive': device.isRescuerActive ? 1 : 0,
      'lastSeen': device.lastSeen.millisecondsSinceEpoch,
      'latitude': device.latitude,
      'longitude': device.longitude,
      'signalStrength': device.signalStrength,
      'isConnected': device.isConnected ? 1 : 0,
      'connectionType': device.connectionType,
    });
  }

  Future<List<NearbyDevice>> getNearbyDevices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devices',
      where: 'type = ?',
      whereArgs: ['nearby'],
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

  // Additional legacy methods...
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

  Future<List<ChatMessage>> getEmergencyMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'isEmergency = 1',
      orderBy: 'timestamp DESC',
    );

    return _mapToMessages(maps);
  }

  Future<void> removeOldNearbyDevices(Duration maxAge) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    await db.delete(
      'devices',
      where: 'lastSeen < ? AND type = ?',
      whereArgs: [cutoffTime, 'nearby'],
    );
  }

  Future<List<NearbyDevice>> getSOSDevices() async {
    final devices = await getNearbyDevices();
    return devices.where((device) => device.isSOSActive).toList();
  }

  Future<List<NearbyDevice>> getRescuerDevices() async {
    final devices = await getNearbyDevices();
    return devices.where((device) => device.isRescuerActive).toList();
  }

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

  Future<void> clearAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  Future<void> addBlockedUser(String userId, String userName) async {
    final db = await database;
    await db.insert(
      'blocked_users',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': userId,
        'user_name': userName,
        'blocked_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isUserBlocked(String userId) async {
    final db = await database;
    final result = await db.query(
      'blocked_users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final db = await database;
    return await db.query('blocked_users', orderBy: 'blocked_at DESC');
  }

  Future<void> unblockUser(String userId) async {
    final db = await database;
    await db.delete(
      'blocked_users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}