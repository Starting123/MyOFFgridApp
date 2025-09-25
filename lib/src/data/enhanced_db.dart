import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/enhanced_message_model.dart';

part 'enhanced_db.g.dart';

// Enhanced Messages table with status tracking
class EnhancedMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  TextColumn get senderId => text()();
  TextColumn get receiverId => text().nullable()();
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get type => intEnum<MessageType>()();
  IntColumn get status => intEnum<MessageStatus>()();
  BoolColumn get isSos => boolean().withDefault(const Constant(false))();
  BoolColumn get isEncrypted => boolean().withDefault(const Constant(false))();
  TextColumn get filePath => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get encryptionKey => text().nullable()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get deliveredTo => text().nullable()(); // JSON array as string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Device registry table
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get deviceType => text()(); // 'sos' or 'rescuer'
  DateTimeColumn get lastSeen => dateTime()();
  BoolColumn get isOnline => boolean().withDefault(const Constant(false))();
  TextColumn get publicKey => text().nullable()(); // For encryption
  
  @override
  Set<Column> get primaryKey => {id};
}

// Message delivery tracking
class MessageDeliveries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text()();
  TextColumn get deviceId => text()();
  DateTimeColumn get deliveredAt => dateTime()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();
}

// SOS Broadcasts tracking
class SosBroadcasts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sosId => text().unique()();
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get message => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get acknowledgedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [EnhancedMessages, Devices, MessageDeliveries, SosBroadcasts])
class EnhancedAppDatabase extends _$EnhancedAppDatabase {
  EnhancedAppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ============ MESSAGE OPERATIONS ============
  
  /// Insert a new message with pending status
  Future<int> insertPendingMessage(EnhancedMessageModel message) async {
    final companion = EnhancedMessagesCompanion(
      messageId: Value(message.id),
      senderId: Value(message.senderId),
      receiverId: Value(message.receiverId),
      content: Value(message.content),
      timestamp: Value(message.timestamp),
      type: Value(message.type),
      status: Value(MessageStatus.pending),
      isSos: Value(message.isSOS),
      isEncrypted: Value(message.isEncrypted),
      filePath: Value(message.filePath),
      thumbnailPath: Value(message.thumbnailPath),
      latitude: Value(message.latitude),
      longitude: Value(message.longitude),
      encryptionKey: Value(message.encryptionKey),
    );
    
    return await into(enhancedMessages).insert(companion);
  }

  /// Get all messages for display
  Future<List<EnhancedMessage>> getAllMessages() => 
      (select(enhancedMessages)..orderBy([(m) => OrderingTerm.asc(m.timestamp)])).get();

  /// Get pending messages that need to be sent
  Future<List<EnhancedMessage>> getPendingMessages() =>
      (select(enhancedMessages)..where((m) => m.status.equals(MessageStatus.pending.index))).get();

  /// Get messages that need cloud sync
  Future<List<EnhancedMessage>> getUnsyncedMessages() =>
      (select(enhancedMessages)..where((m) => m.syncedAt.isNull())).get();

  /// Mark message as sent
  Future<bool> markMessageSent(String messageId) async {
    final result = await (update(enhancedMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(EnhancedMessagesCompanion(
          status: const Value(MessageStatus.sent),
          updatedAt: Value(DateTime.now()),
        ));
    return result > 0;
  }

  /// Mark message as delivered to specific device
  Future<bool> markMessageDelivered(String messageId, String deviceId) async {
    // Insert delivery record
    await into(messageDeliveries).insert(MessageDeliveriesCompanion(
      messageId: Value(messageId),
      deviceId: Value(deviceId),
      deliveredAt: Value(DateTime.now()),
    ));

    // Update message status
    final result = await (update(enhancedMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(EnhancedMessagesCompanion(
          status: const Value(MessageStatus.delivered),
          deliveredAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
    return result > 0;
  }

  /// Mark message as synced to cloud
  Future<bool> markMessageSynced(String messageId) async {
    final result = await (update(enhancedMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(EnhancedMessagesCompanion(
          status: const Value(MessageStatus.synced),
          syncedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
    return result > 0;
  }

  /// Mark message as failed
  Future<bool> markMessageFailed(String messageId) async {
    final result = await (update(enhancedMessages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(EnhancedMessagesCompanion(
          status: const Value(MessageStatus.failed),
          updatedAt: Value(DateTime.now()),
        ));
    return result > 0;
  }

  // ============ DEVICE OPERATIONS ============
  
  /// Register or update a nearby device
  Future<void> upsertDevice(String deviceId, String name, String deviceType, {String? publicKey}) async {
    await into(devices).insertOnConflictUpdate(DevicesCompanion(
      id: Value(deviceId),
      name: Value(name),
      deviceType: Value(deviceType),
      lastSeen: Value(DateTime.now()),
      isOnline: const Value(true),
      publicKey: Value(publicKey),
    ));
  }

  /// Get all online devices
  Future<List<Device>> getOnlineDevices() =>
      (select(devices)..where((d) => d.isOnline.equals(true))).get();

  /// Mark device as offline
  Future<void> markDeviceOffline(String deviceId) async {
    await (update(devices)..where((d) => d.id.equals(deviceId)))
        .write(const DevicesCompanion(isOnline: Value(false)));
  }

  // ============ SOS OPERATIONS ============
  
  /// Insert SOS broadcast
  Future<int> insertSosBroadcast({
    required String sosId,
    required String deviceId,
    required String deviceName,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    return await into(sosBroadcasts).insert(SosBroadcastsCompanion(
      sosId: Value(sosId),
      deviceId: Value(deviceId),
      deviceName: Value(deviceName),
      message: Value(message),
      latitude: Value(latitude),
      longitude: Value(longitude),
      timestamp: Value(DateTime.now()),
    ));
  }

  /// Get active SOS broadcasts
  Future<List<SosBroadcast>> getActiveSosBroadcasts() =>
      (select(sosBroadcasts)..where((s) => s.isActive.equals(true))).get();

  /// Acknowledge SOS broadcast
  Future<void> acknowledgeSos(String sosId) async {
    await (update(sosBroadcasts)..where((s) => s.sosId.equals(sosId)))
        .write(SosBroadcastsCompanion(
          isActive: const Value(false),
          acknowledgedAt: Value(DateTime.now()),
        ));
  }

  // ============ UTILITY OPERATIONS ============
  
  /// Clean old messages (keep last 1000)
  Future<void> cleanOldMessages() async {
    await customStatement('''
      DELETE FROM enhanced_messages 
      WHERE id NOT IN (
        SELECT id FROM enhanced_messages 
        ORDER BY timestamp DESC 
        LIMIT 1000
      )
    ''');
  }

  /// Get message statistics
  Future<Map<String, int>> getMessageStats() async {
    final result = await customSelect('''
      SELECT 
        status,
        COUNT(*) as count
      FROM enhanced_messages 
      GROUP BY status
    ''').get();

    final stats = <String, int>{};
    for (final row in result) {
      final statusIndex = row.read<int>('status');
      final count = row.read<int>('count');
      final status = MessageStatus.values[statusIndex];
      stats[status.toString()] = count;
    }
    return stats;
  }
}

// Database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'enhanced_offgrid_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}