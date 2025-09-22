// Database schema and operations for the offline-first SOS appimport 'dart:io';import 'dart:io';import 'dart:io';import 'dart:io';

import 'dart:io';

import 'package:drift/drift.dart';import 'package:drift/drift.dart';

import 'package:drift/native.dart';

import 'package:path_provider/path_provider.dart';import 'package:drift/native.dart';import 'package:drift/drift.dart';

import 'package:path/path.dart' as p;

import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

import 'package:path/path.dart' as p;import 'package:drift/native.dart';import 'package:drift/drift.dart';import 'package:drift/drift.dart';

@DataClassName('Message')

class Messages extends Table {

  IntColumn get id => integer().autoIncrement()();

  TextColumn get messageId => text().unique()();part 'db.g.dart';import 'package:path_provider/path_provider.dart';

  TextColumn get fromId => text()();

  TextColumn get toId => text()();

  TextColumn get type => text()();

  TextColumn get body => text()();@DataClassName('Message')import 'package:path/path.dart' as p;import 'package:drift/native.dart';import 'package:drift/native.dart';

  TextColumn get filePath => text().nullable()();

  DateTimeColumn get timestamp => dateTime()();class Messages extends Table {

  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get ttl => integer().withDefault(const Constant(24))();  IntColumn get id => integer().autoIncrement()();

  IntColumn get hopCount => integer().withDefault(const Constant(0))();

  BoolColumn get isEncrypted => boolean().withDefault(const Constant(true))();  TextColumn get messageId => text().unique()();



  @override  TextColumn get fromId => text()();part 'db.g.dart';import 'package:path_provider/path_provider.dart';import 'package:path_provider/path_provider.dart';

  List<String> get customConstraints => [

        'CONSTRAINT message_unique_id UNIQUE (messageId)',  TextColumn get toId => text()();

      ];

}  TextColumn get type => text()();



@DataClassName('QueueItem')  TextColumn get body => text()();

class MessageQueue extends Table {

  IntColumn get id => integer().autoIncrement()();  TextColumn get filePath => text().nullable()();@DataClassName('Message')import 'package:path/path.dart' as p;import 'package:path/path.dart' as p;

  TextColumn get messageId => text().references(Messages, #messageId, onDelete: KeyAction.cascade)();

  TextColumn get targetId => text()();  DateTimeColumn get timestamp => dateTime()();

  DateTimeColumn get nextAttempt => dateTime()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();  TextColumn get status => text().withDefault(const Constant('pending'))();class Messages extends Table {

  TextColumn get status => text().withDefault(const Constant('pending'))();

  TextColumn get transportType => text()(); // 'ble', 'p2p', or 'cloud'  IntColumn get ttl => integer().withDefault(const Constant(24))();



  @override  IntColumn get hopCount => integer().withDefault(const Constant(0))();  IntColumn get id => integer().autoIncrement()();

  List<String> get customConstraints => [

        'CREATE INDEX idx_message_queue_status ON message_queue(status)',  BoolColumn get isEncrypted => boolean().withDefault(const Constant(true))();

        'CREATE INDEX idx_message_queue_next_attempt ON message_queue(next_attempt)',

      ];  TextColumn get messageId => text().unique()();

}

  @override

@DataClassName('SyncLog')

class SyncLogs extends Table {  List<String> get customConstraints => [  TextColumn get fromId => text()();part 'db.g.dart';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get messageId => text().references(Messages, #messageId, onDelete: KeyAction.cascade)();        'CONSTRAINT message_unique_id UNIQUE (messageId)',

  TextColumn get operation => text()();

  DateTimeColumn get timestamp => dateTime()();      ];  TextColumn get toId => text()();

  TextColumn get status => text()();

  TextColumn get error => text().nullable()();}

  

  @override  TextColumn get type => text()();part 'db.g.dart';

  List<String> get customConstraints => [

        'CREATE INDEX idx_sync_logs_message ON sync_logs(message_id)',@DataClassName('QueueItem')

        'CREATE INDEX idx_sync_logs_timestamp ON sync_logs(timestamp)',

      ];class MessageQueue extends Table {  TextColumn get body => text()();

}

  IntColumn get id => integer().autoIncrement()();

@DriftDatabase(tables: [Messages, MessageQueue, SyncLogs])

class AppDatabase extends _$AppDatabase {  TextColumn get messageId => text().references(Messages, #messageId, onDelete: KeyAction.cascade)();  TextColumn get filePath => text().nullable()();class Messages extends Table {

  AppDatabase() : super(_openConnection());

  TextColumn get targetId => text()();

  @override

  int get schemaVersion => 1;  DateTimeColumn get nextAttempt => dateTime()();  DateTimeColumn get timestamp => dateTime()();



  @override  IntColumn get attempts => integer().withDefault(const Constant(0))();

  MigrationStrategy get migration {

    return MigrationStrategy(  TextColumn get status => text().withDefault(const Constant('pending'))();  TextColumn get status => text().withDefault(const Constant('pending'))();  IntColumn get id => integer().autoIncrement()();part 'db.g.dart';

      onCreate: (m) async {

        await m.createAll();  TextColumn get transportType => text()(); // 'ble', 'p2p', or 'cloud'

      },

      onUpgrade: (m, from, to) async {  IntColumn get ttl => integer().withDefault(const Constant(24))();

        if (from < 1) {

          // Add future migrations here  @override

        }

      },  List<String> get customConstraints => [  IntColumn get hopCount => integer().withDefault(const Constant(0))();  TextColumn get messageId => text().unique()();

      beforeOpen: (details) async {

        await customStatement('PRAGMA foreign_keys = ON');        'CREATE INDEX idx_message_queue_status ON message_queue(status)',

      },

    );        'CREATE INDEX idx_message_queue_next_attempt ON message_queue(next_attempt)',  BoolColumn get isEncrypted => boolean().withDefault(const Constant(true))();

  }

      ];

  // Message Operations

  Future<int> createMessage(MessagesCompanion message) =>}  TextColumn get fromId => text()();class Messages extends Table {

      into(messages).insert(message);



  Future<Message?> getMessage(String messageId) =>

      (select(messages)..where((m) => m.messageId.equals(messageId)))@DataClassName('SyncLog')  @override

          .getSingleOrNull();

class SyncLogs extends Table {

  Future<List<Message>> getPendingMessages() =>

      (select(messages)..where((m) => m.status.equals('pending'))).get();  IntColumn get id => integer().autoIncrement()();  List<String> get customConstraints => [  TextColumn get toId => text()();  IntColumn get id => integer().autoIncrement()();



  Future<bool> updateMessageStatus(String messageId, String status) async {  TextColumn get messageId => text().references(Messages, #messageId, onDelete: KeyAction.cascade)();

    return transaction(() async {

      final count = await (update(messages)  TextColumn get operation => text()();        'CONSTRAINT message_unique_id UNIQUE (messageId)',

            ..where((m) => m.messageId.equals(messageId)))

          .write(MessagesCompanion(status: Value(status)));  DateTimeColumn get timestamp => dateTime()();

      return count > 0;

    });  TextColumn get status => text()();      ];  TextColumn get type => text()();  TextColumn get messageId => text().unique()();

  }

  TextColumn get error => text().nullable()();

  // Queue Operations

  Future<int> queueMessage(MessageQueueCompanion item) =>  }

      into(messageQueue).insert(item);

  @override

  Future<List<QueueItem>> getPendingQueueItems() =>

      (select(messageQueue)  List<String> get customConstraints => [  TextColumn get body => text()();  TextColumn get fromId => text()();

        ..where((q) => q.status.equals('pending'))

        ..orderBy([(q) => OrderingTerm(expression: q.nextAttempt)]))        'CREATE INDEX idx_sync_logs_message ON sync_logs(message_id)',

          .get();

        'CREATE INDEX idx_sync_logs_timestamp ON sync_logs(timestamp)',@DataClassName('QueueItem')

  Future<void> updateQueueItemStatus(int id, String status, {DateTime? nextAttempt}) =>

      (update(messageQueue)..where((q) => q.id.equals(id)))      ];

          .write(MessageQueueCompanion(

            status: Value(status),}class MessageQueue extends Table {  TextColumn get filePath => text().nullable()();  TextColumn get toId => text()();

            nextAttempt: nextAttempt == null ? const Value.absent() : Value(nextAttempt),

            attempts: Value(messageQueue.attempts + 1),

          ));

@DriftDatabase(tables: [Messages, MessageQueue, SyncLogs])  IntColumn get id => integer().autoIncrement()();

  // Sync Operations

  Future<void> logSync(class AppDatabase extends _$AppDatabase {

      String messageId, String operation, String status, {String? error}) =>

      into(syncLogs).insert(SyncLogsCompanion.insert(  AppDatabase() : super(_openConnection());  TextColumn get messageId => text().references(Messages, #messageId, onDelete: KeyAction.cascade)();  DateTimeColumn get timestamp => dateTime()();  TextColumn get type => text()();

        messageId: messageId,

        operation: operation,

        timestamp: DateTime.now(),

        status: status,  @override  TextColumn get targetId => text()();

        error: Value(error),

      ));  int get schemaVersion => 1;



  // Cleanup Operations  DateTimeColumn get nextAttempt => dateTime()();  TextColumn get status => text().withDefault(const Constant('pending'))();  TextColumn get body => text()();

  Future<void> cleanup() async {

    final now = DateTime.now();  @override

    await transaction(() async {

      // Delete old delivered messages  MigrationStrategy get migration {  IntColumn get attempts => integer().withDefault(const Constant(0))();

      await (delete(messages)

        ..where((m) =>    return MigrationStrategy(

            m.status.equals('delivered') &

            m.timestamp.isSmallerThanValue(now.subtract(const Duration(days: 7)))))      onCreate: (m) async {  TextColumn get status => text().withDefault(const Constant('pending'))();  IntColumn get ttl => integer().withDefault(const Constant(24))();  TextColumn get filePath => text().nullable()();

          .go();

        await m.createAll();

      // Delete failed queue items after 24 hours

      await (delete(messageQueue)      },  TextColumn get transportType => text()(); // 'ble', 'p2p', or 'cloud'

        ..where((q) =>

            q.status.equals('failed') &      onUpgrade: (m, from, to) async {

            q.nextAttempt.isSmallerThanValue(now.subtract(const Duration(hours: 24)))))

          .go();        if (from < 1) {  IntColumn get hopCount => integer().withDefault(const Constant(0))();  DateTimeColumn get timestamp => dateTime()();



      // Delete old sync logs          // Add future migrations here

      await (delete(syncLogs)

        ..where((s) =>        }  @override

            s.timestamp.isSmallerThanValue(now.subtract(const Duration(days: 30)))))

          .go();      },

    });

  }      beforeOpen: (details) async {  List<String> get customConstraints => [  TextColumn get status => text().withDefault(const Constant('pending'))();

}

        await customStatement('PRAGMA foreign_keys = ON');

LazyDatabase _openConnection() {

  return LazyDatabase(() async {      },        'CREATE INDEX idx_message_queue_status ON message_queue(status)',

    final dbFolder = await getApplicationDocumentsDirectory();

    final file = File(p.join(dbFolder.path, 'app.db'));    );

    return NativeDatabase(file);

  });  }        'CREATE INDEX idx_message_queue_next_attempt ON message_queue(next_attempt)',  @override  IntColumn get ttl => integer().withDefault(const Constant(24))();

}


  // Message Operations      ];

  Future<int> createMessage(MessagesCompanion message) =>

      into(messages).insert(message);}  List<String> get customConstraints => [  IntColumn get hopCount => integer().withDefault(const Constant(0))();



  Future<Message?> getMessage(String messageId) =>

      (select(messages)..where((m) => m.messageId.equals(messageId)))

          .getSingleOrNull();@DataClassName('SyncLog')    'CONSTRAINT message_unique_id UNIQUE (messageId)',



  Future<List<Message>> getPendingMessages() =>class SyncLogs extends Table {

      (select(messages)..where((m) => m.status.equals('pending'))).get();

  IntColumn get id => integer().autoIncrement()();  ];  @override

  Future<bool> updateMessageStatus(String messageId, String status) async {

    return transaction(() async {  TextColumn get messageId => text().references(Messages, #messageId, onDelete: KeyAction.cascade)();

      final count = await (update(messages)

            ..where((m) => m.messageId.equals(messageId)))  TextColumn get operation => text()();}  List<String> get customConstraints => [

          .write(MessagesCompanion(status: Value(status)));

      return count > 0;  DateTimeColumn get timestamp => dateTime()();

    });

  }  TextColumn get status => text()();    'CONSTRAINT message_idx UNIQUE (messageId)',



  // Queue Operations  TextColumn get error => text().nullable()();

  Future<int> queueMessage(MessageQueueCompanion item) =>

      into(messageQueue).insert(item);  class QueueItems extends Table {    'CREATE INDEX message_status_idx ON messages(status)',



  Future<List<QueueItem>> getPendingQueueItems() =>  @override

      (select(messageQueue)

        ..where((q) => q.status.equals('pending'))  List<String> get customConstraints => [  IntColumn get id => integer().autoIncrement()();    'CREATE INDEX message_timestamp_idx ON messages(timestamp)',

        ..orderBy([(q) => OrderingTerm(expression: q.nextAttempt)]))

          .get();        'CREATE INDEX idx_sync_logs_message ON sync_logs(message_id)',



  Future<void> updateQueueItemStatus(int id, String status, {DateTime? nextAttempt}) =>        'CREATE INDEX idx_sync_logs_timestamp ON sync_logs(timestamp)',  TextColumn get messageId => text().references(Messages, #messageId)();  ];

      (update(messageQueue)..where((q) => q.id.equals(id)))

          .write(MessageQueueCompanion(      ];

            status: Value(status),

            nextAttempt: nextAttempt == null ? const Value.absent() : Value(nextAttempt),}  TextColumn get targetId => text()();}

            attempts: Value(messageQueue.attempts + 1),

          ));



  // Sync Operations@DriftDatabase(tables: [Messages, MessageQueue, SyncLogs])  DateTimeColumn get nextAttempt => dateTime()();

  Future<void> logSync(

      String messageId, String operation, String status, {String? error}) =>class AppDatabase extends _$AppDatabase {

      into(syncLogs).insert(SyncLogsCompanion.insert(

        messageId: messageId,  AppDatabase() : super(_openConnection());  IntColumn get attempts => integer().withDefault(const Constant(0))();class QueueItems extends Table {

        operation: operation,

        timestamp: DateTime.now(),

        status: status,

        error: Value(error),  @override  TextColumn get status => text().withDefault(const Constant('pending'))();  IntColumn get id => integer().autoIncrement()();

      ));

  int get schemaVersion => 1;

  // Cleanup Operations

  Future<void> cleanup() async {}  TextColumn get messageId => text()();

    final now = DateTime.now();

    await transaction(() async {  @override

      // Delete old delivered messages

      await (delete(messages)  MigrationStrategy get migration {  TextColumn get targetId => text()();

        ..where((m) =>

            m.status.equals('delivered') &    return MigrationStrategy(

            m.timestamp.isSmallerThanValue(now.subtract(const Duration(days: 7)))))

          .go();      onCreate: (m) async {class SyncLogs extends Table {  DateTimeColumn get nextAttempt => dateTime()();



      // Delete failed queue items after 24 hours        await m.createAll();

      await (delete(messageQueue)

        ..where((q) =>      },  IntColumn get id => integer().autoIncrement()();  IntColumn get attempts => integer().withDefault(const Constant(0))();

            q.status.equals('failed') &

            q.nextAttempt.isSmallerThanValue(now.subtract(const Duration(hours: 24)))))      onUpgrade: (m, from, to) async {

          .go();

        if (from < 1) {  TextColumn get messageId => text().references(Messages, #messageId)();  TextColumn get status => text().withDefault(const Constant('pending'))();

      // Delete old sync logs

      await (delete(syncLogs)          // Add future migrations here

        ..where((s) =>

            s.timestamp.isSmallerThanValue(now.subtract(const Duration(days: 30)))))        }  TextColumn get operation => text()();

          .go();

    });      },

  }

}      beforeOpen: (details) async {  DateTimeColumn get timestamp => dateTime()();  @override



LazyDatabase _openConnection() {        await customStatement('PRAGMA foreign_keys = ON');

  return LazyDatabase(() async {

    final dbFolder = await getApplicationDocumentsDirectory();      },  TextColumn get status => text()();  List<String> get customConstraints => [

    final file = File(p.join(dbFolder.path, 'app.db'));

    return NativeDatabase(file);    );

  });

}  }  TextColumn get error => text().nullable()();    'FOREIGN KEY (messageId) REFERENCES messages(messageId) ON DELETE CASCADE',



  // Message Operations}    'CREATE INDEX queue_message_idx ON queue_items(messageId)',

  Future<int> createMessage(MessagesCompanion message) =>

      into(messages).insert(message);    'CREATE INDEX queue_status_idx ON queue_items(status)',



  Future<Message?> getMessage(String messageId) =>@DriftDatabase(tables: [Messages, QueueItems, SyncLogs])    'CREATE INDEX queue_next_attempt_idx ON queue_items(nextAttempt)',

      (select(messages)..where((m) => m.messageId.equals(messageId)))

          .getSingleOrNull();class AppDatabase extends _$AppDatabase {  ];



  Future<List<Message>> getPendingMessages() =>  AppDatabase() : super(_openConnection());}

      (select(messages)..where((m) => m.status.equals('pending'))).get();



  Future<bool> updateMessageStatus(String messageId, String status) async {

    return transaction(() async {  @overrideclass SyncLogs extends Table {

      final count = await (update(messages)

            ..where((m) => m.messageId.equals(messageId)))  int get schemaVersion => 1;  IntColumn get id => integer().autoIncrement()();

          .write(MessagesCompanion(status: Value(status)));

      return count > 0;  TextColumn get messageId => text()();

    });

  }  @override  TextColumn get operation => text()();



  // Queue Operations  MigrationStrategy get migration {  DateTimeColumn get timestamp => dateTime()();

  Future<int> queueMessage(MessageQueueCompanion item) =>

      into(messageQueue).insert(item);    return MigrationStrategy(  TextColumn get status => text()();



  Future<List<QueueItem>> getPendingQueueItems() =>      onCreate: (m) async {  TextColumn get error => text().nullable()();

      (select(messageQueue)

        ..where((q) => q.status.equals('pending'))        await m.createAll();

        ..orderBy([(q) => OrderingTerm(expression: q.nextAttempt)]))

          .get();        await customStatement('PRAGMA foreign_keys = ON');  @override



  Future<void> updateQueueItemStatus(int id, String status, {DateTime? nextAttempt}) =>      },  List<String> get customConstraints => [

      (update(messageQueue)..where((q) => q.id.equals(id)))

          .write(MessageQueueCompanion(      beforeOpen: (details) async {    'FOREIGN KEY (messageId) REFERENCES messages(messageId) ON DELETE CASCADE',

            status: Value(status),

            nextAttempt: nextAttempt == null ? const Value.absent() : Value(nextAttempt),        await customStatement('PRAGMA foreign_keys = ON');    'CREATE INDEX sync_message_idx ON sync_logs(messageId)',

            attempts: Value(messageQueue.attempts + 1),

          ));      },    'CREATE INDEX sync_timestamp_idx ON sync_logs(timestamp)',



  // Sync Operations    );  ];

  Future<void> logSync(

      String messageId, String operation, String status, {String? error}) =>  }}

      into(syncLogs).insert(SyncLogsCompanion.insert(

        messageId: messageId,

        operation: operation,

        timestamp: DateTime.now(),  Future<int> createMessage(MessagesCompanion message) => @DriftDatabase(tables: [Messages, QueueItems, SyncLogs])

        status: status,

        error: Value(error),    into(messages).insert(message);class AppDatabase extends _$AppDatabase {

      ));

  AppDatabase() : super(_openConnection());

  // Cleanup Operations

  Future<void> cleanup() async {  Future<Message?> getMessage(String messageId) =>

    final now = DateTime.now();

    await transaction(() async {    (select(messages)..where((m) => m.messageId.equals(messageId)))  @override

      // Delete old delivered messages

      await (delete(messages)        .getSingleOrNull();  int get schemaVersion => 1;

        ..where((m) =>

            m.status.equals('delivered') &

            m.timestamp.isSmallerThanValue(now.subtract(const Duration(days: 7)))))

          .go();  Future<List<Message>> getUnsentMessages() =>  @override



      // Delete failed queue items after 24 hours    (select(messages)..where((m) => m.status.equals('pending')))  MigrationStrategy get migration {

      await (delete(messageQueue)

        ..where((q) =>        .get();    return MigrationStrategy(

            q.status.equals('failed') &

            q.nextAttempt.isSmallerThanValue(now.subtract(const Duration(hours: 24)))))      onCreate: (m) async {

          .go();

  Future<bool> updateMessageStatus(String messageId, String status) async {        await m.createAll();

      // Delete old sync logs

      await (delete(syncLogs)    final count = await (update(messages)..where((m) => m.messageId.equals(messageId)))        await customStatement('PRAGMA foreign_keys = ON');

        ..where((s) =>

            s.timestamp.isSmallerThanValue(now.subtract(const Duration(days: 30)))))        .write(MessagesCompanion(status: Value(status)));      },

          .go();

    });    return count > 0;      onUpgrade: (m, from, to) async {

  }

}  }        if (from < 1) {



LazyDatabase _openConnection() {          // Add future migrations here

  return LazyDatabase(() async {

    final dbFolder = await getApplicationDocumentsDirectory();  Future<void> deleteMessage(String messageId) async {        }

    final file = File(p.join(dbFolder.path, 'app.db'));

    return NativeDatabase(file);    await (delete(messages)..where((m) => m.messageId.equals(messageId))).go();      },

  });

}  }      beforeOpen: (details) async {

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
