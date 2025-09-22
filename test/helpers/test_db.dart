import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'test_db.g.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderId => text()();
  TextColumn get receiverId => text()();
  TextColumn get encryptedContent => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  static AppDatabase createInMemory() {
    return AppDatabase.forTesting(NativeDatabase.memory());
  }

  Future<int> insertMessage(MessagesCompanion message) {
    return into(messages).insert(message);
  }

  Future<List<Message>> getAllMessages() {
    return select(messages).get();
  }

  Future<List<Message>> getUnreadMessages() {
    return (select(messages)..where((m) => m.isRead.equals(false))).get();
  }

  Future<List<Message>> getMessagesBetween(String user1, String user2) {
    return (select(messages)
      ..where((m) => 
        (m.senderId.equals(user1) & m.receiverId.equals(user2)) |
        (m.senderId.equals(user2) & m.receiverId.equals(user1)))
      ..orderBy([(m) => OrderingTerm(expression: m.timestamp)]))
    .get();
  }

  Future<void> markMessageAsRead(int id) {
    return (update(messages)..where((m) => m.id.equals(id)))
      .write(const MessagesCompanion(isRead: Value(true)));
  }

  Future<void> deleteExpiredMessages(DateTime cutoff) {
    return (delete(messages)..where((m) => m.timestamp.isSmallerThanValue(cutoff)))
      .go();
  }
}