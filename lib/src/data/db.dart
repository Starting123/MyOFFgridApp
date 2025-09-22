import 'dart:io';import 'dart:io';

import 'package:drift/drift.dart';import 'package:drift/drift.dart';

import 'package:drift/native.dart';import 'package:drift/native.dart';

import 'package:path_provider/path_provider.dart';import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as p;import 'package:path/path.dart' as p;



part 'db.g.dart';

part 'db.g.dart';

class Messages extends Table {

  IntColumn get id => integer().autoIncrement()();part 'db.g.dart';

  TextColumn get messageId => text().unique()();

  TextColumn get fromId => text()();class Messages extends Table {

  TextColumn get toId => text()();  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text()();  TextColumn get messageId => text().unique()();

  TextColumn get body => text()();  TextColumn get fromId => text()();

  TextColumn get filePath => text().nullable()();  TextColumn get toId => text()();

  DateTimeColumn get timestamp => dateTime()();  TextColumn get type => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();  TextColumn get body => text()();

  IntColumn get ttl => integer().withDefault(const Constant(24))();  TextColumn get filePath => text().nullable()();

  IntColumn get hopCount => integer().withDefault(const Constant(0))();  DateTimeColumn get timestamp => dateTime()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  @override  IntColumn get ttl => integer().withDefault(const Constant(24))();

  List<String> get customConstraints => [  IntColumn get hopCount => integer().withDefault(const Constant(0))();

    'CONSTRAINT message_unique_id UNIQUE (messageId)',

  ];  @override

}  List<String> get customConstraints => [

    'CONSTRAINT message_idx UNIQUE (messageId)',

class QueueItems extends Table {    'CREATE INDEX message_status_idx ON messages(status)',

  IntColumn get id => integer().autoIncrement()();    'CREATE INDEX message_timestamp_idx ON messages(timestamp)',

  TextColumn get messageId => text().references(Messages, #messageId)();  ];

  TextColumn get targetId => text()();}

  DateTimeColumn get nextAttempt => dateTime()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();class QueueItems extends Table {

  TextColumn get status => text().withDefault(const Constant('pending'))();  IntColumn get id => integer().autoIncrement()();

}  TextColumn get messageId => text()();

  TextColumn get targetId => text()();

class SyncLogs extends Table {  DateTimeColumn get nextAttempt => dateTime()();

  IntColumn get id => integer().autoIncrement()();  IntColumn get attempts => integer().withDefault(const Constant(0))();

  TextColumn get messageId => text().references(Messages, #messageId)();  TextColumn get status => text().withDefault(const Constant('pending'))();

  TextColumn get operation => text()();

  DateTimeColumn get timestamp => dateTime()();  @override

  TextColumn get status => text()();  List<String> get customConstraints => [

  TextColumn get error => text().nullable()();    'FOREIGN KEY (messageId) REFERENCES messages(messageId) ON DELETE CASCADE',

}    'CREATE INDEX queue_message_idx ON queue_items(messageId)',

    'CREATE INDEX queue_status_idx ON queue_items(status)',

@DriftDatabase(tables: [Messages, QueueItems, SyncLogs])    'CREATE INDEX queue_next_attempt_idx ON queue_items(nextAttempt)',

class AppDatabase extends _$AppDatabase {  ];

  AppDatabase() : super(_openConnection());}



  @overrideclass SyncLogs extends Table {

  int get schemaVersion => 1;  IntColumn get id => integer().autoIncrement()();

  TextColumn get messageId => text()();

  @override  TextColumn get operation => text()();

  MigrationStrategy get migration {  DateTimeColumn get timestamp => dateTime()();

    return MigrationStrategy(  TextColumn get status => text()();

      onCreate: (m) async {  TextColumn get error => text().nullable()();

        await m.createAll();

        await customStatement('PRAGMA foreign_keys = ON');  @override

      },  List<String> get customConstraints => [

      beforeOpen: (details) async {    'FOREIGN KEY (messageId) REFERENCES messages(messageId) ON DELETE CASCADE',

        await customStatement('PRAGMA foreign_keys = ON');    'CREATE INDEX sync_message_idx ON sync_logs(messageId)',

      },    'CREATE INDEX sync_timestamp_idx ON sync_logs(timestamp)',

    );  ];

  }}



  Future<int> createMessage(MessagesCompanion message) => @DriftDatabase(tables: [Messages, QueueItems, SyncLogs])

    into(messages).insert(message);class AppDatabase extends _$AppDatabase {

  AppDatabase() : super(_openConnection());

  Future<Message?> getMessage(String messageId) =>

    (select(messages)..where((m) => m.messageId.equals(messageId)))  @override

        .getSingleOrNull();  int get schemaVersion => 1;



  Future<List<Message>> getUnsentMessages() =>  @override

    (select(messages)..where((m) => m.status.equals('pending')))  MigrationStrategy get migration {

        .get();    return MigrationStrategy(

      onCreate: (m) async {

  Future<bool> updateMessageStatus(String messageId, String status) async {        await m.createAll();

    final count = await (update(messages)..where((m) => m.messageId.equals(messageId)))        await customStatement('PRAGMA foreign_keys = ON');

        .write(MessagesCompanion(status: Value(status)));      },

    return count > 0;      onUpgrade: (m, from, to) async {

  }        if (from < 1) {

          // Add future migrations here

  Future<void> deleteMessage(String messageId) async {        }

    await (delete(messages)..where((m) => m.messageId.equals(messageId))).go();      },

  }      beforeOpen: (details) async {

        await customStatement('PRAGMA foreign_keys = ON');

  Future<int> queueMessage(QueueItemsCompanion item) =>      },

    into(queueItems).insert(item);    );

  }

  Future<List<QueueItem>> getPendingQueueItems() =>

    (select(queueItems)  // Batch operations for better performance

      ..where((q) => q.status.equals('pending'))  Future<void> batchInsertMessages(List<Map<String, dynamic>> messages) async {

      ..orderBy([(q) => OrderingTerm(expression: q.nextAttempt)]))    await batch((batch) {

    .get();      batch.insertAll(

        this.messages,

  Stream<List<QueueItem>> watchPendingQueueItems() =>        messages.map((msg) => MessagesCompanion.insert(

    (select(queueItems)          messageId: msg['messageId'] as String,

      ..where((q) => q.status.equals('pending'))          fromId: msg['fromId'] as String,

      ..orderBy([(q) => OrderingTerm(expression: q.nextAttempt)]))          toId: msg['toId'] as String,

    .watch();          type: msg['type'] as String,

          body: msg['body'] as String,

  Future<void> logSync(          filePath: Value(msg['filePath'] as String?),

    String messageId,          timestamp: DateTime.now(),

    String operation,          status: const Value('pending'),

    String status, {          ttl: const Value(24),

    String? error,          hopCount: const Value(0),

  }) =>        )).toList(),

    into(syncLogs).insert(      );

      SyncLogsCompanion.insert(    });

        messageId: messageId,  }

        operation: operation,

        timestamp: DateTime.now(),  // Transaction support for atomic operations

        status: status,  Future<void> insertMessageWithQueue(

        error: Value(error),    Map<String, dynamic> message,

      ),    String targetId,

    );  ) async {

    await transaction(() async {

  Future<void> cleanup() async {      final messageId = message['messageId'] as String;

    final now = DateTime.now();      

    await (delete(messages)..where((m) =>      // Insert message

      m.timestamp.isSmallerThanValue(now.subtract(const Duration(hours: 24))) &      await into(messages).insert(MessagesCompanion.insert(

      m.status.equals('delivered')        messageId: messageId,

    )).go();        fromId: message['fromId'] as String,

  }        toId: message['toId'] as String,

}        type: message['type'] as String,

        body: message['body'] as String,

LazyDatabase _openConnection() {        filePath: Value(message['filePath'] as String?),

  return LazyDatabase(() async {        timestamp: DateTime.now(),

    final dbFolder = await getApplicationDocumentsDirectory();      ));

    final file = File(p.join(dbFolder.path, 'app.db'));

    return NativeDatabase(file);      // Create queue item

  });      await into(queueItems).insert(QueueItemsCompanion.insert(

}        messageId: messageId,
        targetId: targetId,
        nextAttempt: DateTime.now(),
      ));

      // Log sync attempt
      await into(syncLogs).insert(SyncLogsCompanion.insert(
        messageId: messageId,
        operation: 'QUEUED',
        timestamp: DateTime.now(),
        status: 'pending',
      ));
    });
  }
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
