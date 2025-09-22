import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'test_db.g.dart';

// Tables
class TestMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderId => text()();
  TextColumn get receiverId => text()();
  TextColumn get encryptedContent => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [TestMessages])
class TestDatabase extends _$TestDatabase {
  TestDatabase() : super(_openConnection());

  static TestDatabase createInMemory() {
    return TestDatabase.withExecutor(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  Future<int> insertMessage(TestMessagesCompanion message) {
    return into(testMessages).insert(message);
  }

  Future<List<TestMessage>> getAllMessages() {
    return select(testMessages).get();
  }

  Future<List<TestMessage>> getUnreadMessages() {
    return (select(testMessages)..where((m) => m.isRead.equals(false))).get();
  }

  Future<List<TestMessage>> getMessagesBetween(String user1, String user2) {
    return (select(testMessages)
      ..where((m) => 
        (m.senderId.equals(user1) & m.receiverId.equals(user2)) |
        (m.senderId.equals(user2) & m.receiverId.equals(user1)))
      ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
    .get();
  }

  Future<void> markMessageAsRead(int id) {
    return (update(testMessages)..where((m) => m.id.equals(id)))
      .write(const TestMessagesCompanion(isRead: Value(true)));
  }

  Future<void> deleteExpiredMessages(DateTime cutoff) {
    return (delete(testMessages)..where((m) => m.timestamp.isSmallerThanValue(cutoff)))
      .go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'test_offgrid_sos.db'));
    return NativeDatabase(file);
  });
}