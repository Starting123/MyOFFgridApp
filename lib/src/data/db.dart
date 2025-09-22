import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'db.g.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  TextColumn get fromId => text()();
  TextColumn get toId => text()();
  TextColumn get type => text()();
  TextColumn get body => text()();
  TextColumn get filePath => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get ttl => integer().withDefault(const Constant(24))();
  IntColumn get hopCount => integer().withDefault(const Constant(0))();
}

class QueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text()();
  TextColumn get targetId => text()();
  DateTimeColumn get nextAttempt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
}

class SyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text()();
  TextColumn get operation => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get status => text()();
  TextColumn get error => text().nullable()();
}

@DriftDatabase(tables: [Messages, QueueItems, SyncLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
  );

  // Message operations
  Future<int> insertMessage(Map<String, dynamic> message) {
    return into(messages).insert(MessagesCompanion.insert(
      messageId: message['messageId'] as String,
      fromId: message['fromId'] as String,
      toId: message['toId'] as String,
      type: message['type'] as String,
      body: message['body'] as String,
      filePath: Value(message['filePath'] as String?),
      timestamp: Value(DateTime.now()),
      status: Value(message['status'] as String? ?? 'pending'),
      ttl: Value(message['ttl'] as int? ?? 24),
      hopCount: Value(message['hopCount'] as int? ?? 0)
    ));
  }

  Future<Message?> getMessage(String messageId) =>
    (select(messages)..where((m) => m.messageId.equals(messageId)))
    .getSingleOrNull();

  Future<bool> messageExists(String messageId) async =>
    await getMessage(messageId) != null;

  Future<List<Message>> getAllMessages() =>
    select(messages).get();

  Future<bool> updateMessage(Map<String, dynamic> message) async {
    final rowsAffected = await (update(messages)..where((m) => m.messageId.equals(message['messageId'] as String)))
        .write(MessagesCompanion(
          status: Value(message['status'] as String),
          body: Value(message['body'] as String),
          filePath: Value(message['filePath'] as String?),
          ttl: Value(message['ttl'] as int? ?? 24),
          hopCount: Value(message['hopCount'] as int? ?? 0)
        ));
    return rowsAffected > 0;
  }

  Stream<List<Message>> watchChatMessages(String otherUserId) =>
    (select(messages)
      ..where((m) => m.fromId.equals(otherUserId) | m.toId.equals(otherUserId))
      ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
    .watch();

  Future<List<Message>> getPendingMessages() =>
    (select(messages)..where((m) => m.status.equals('pending')))
    .get();

  Future<bool> markMessageStatus(String messageId, String status) async {
    final rowsAffected = await (update(messages)..where((m) => m.messageId.equals(messageId)))
        .write(MessagesCompanion(status: Value(status)));
    return rowsAffected > 0;
  }

  // Queue operations
  Future<int> insertQueueItem(Map<String, dynamic> item) {
    return into(queueItems).insert(QueueItemsCompanion.insert(
      messageId: item['messageId'] as String,
      targetId: item['targetId'] as String,
      nextAttempt: Value(item['nextAttempt'] as DateTime? ?? DateTime.now()),
      attempts: Value(item['attempts'] as int? ?? 0),
      status: Value(item['status'] as String? ?? 'pending')
    ));
  }

  Future<List<QueueItem>> getQueueItemsDue() =>
    (select(queueItems)
      ..where((q) => q.nextAttempt.isSmallerThanValue(DateTime.now()))
      ..orderBy([(q) => OrderingTerm(expression: q.attempts)]))
    .get();

  Future<List<QueueItem>> getPendingQueueItems() =>
    (select(queueItems)..where((q) => q.status.equals('pending')))
    .get();

  Future<bool> updateQueueItemStatus(int id, String status) async {
    final rowsAffected = await (update(queueItems)..where((q) => q.id.equals(id)))
        .write(QueueItemsCompanion(status: Value(status)));
    return rowsAffected > 0;
  }

  // Sync log operations
  Future<int> insertSyncLog(Map<String, dynamic> log) {
    return into(syncLogs).insert(SyncLogsCompanion.insert(
      messageId: log['messageId'] as String,
      operation: log['operation'] as String,
      timestamp: Value(DateTime.now()),
      status: log['status'] as String,
      error: Value(log['error'] as String?)
    ));
  }

  Stream<List<SyncLog>> watchRecentLogs() =>
    (select(syncLogs)
      ..orderBy([(l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc)])
      ..limit(100))
    .watch();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'messages.sqlite'));
    return NativeDatabase(file);
  });
}
