// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

// Database tables
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderId => text()();
  TextColumn get receiverId => text()();
  TextColumn get encryptedContent => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isRead => boolean()();
}

// Database access
@DriftDatabase(tables: [Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  // Open database from file system
  static Future<AppDatabase> openConnection() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return AppDatabase(NativeDatabase(file));
  }

  // Create an in-memory database for testing
  static AppDatabase createInMemory() {
    return AppDatabase(NativeDatabase.memory());
  }

  // Messages CRUD operations
  Future<int> insertMessage(MessagesCompanion message) {
    return into(messages).insert(message);
  }

  Future<bool> updateMessage(MessagesCompanion message) {
    return update(messages).replace(message);
  }

  Future<int> deleteMessage(int id) {
    return (delete(messages)..where((t) => t.id.equals(id))).go();
  }

  // Query operations
  SimpleSelectStatement<Messages, Message> getAllMessages() {
    return select(messages);
  }

  Future<List<Message>> getUnreadMessages() {
    return (select(messages)..where((t) => t.isRead.equals(false))).get();
  }

  Future<List<Message>> getMessagesForUser(String userId) {
    return (select(messages)
      ..where((t) => t.receiverId.equals(userId))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp)])).get();
  }

  Future<List<Message>> getMessagesBetween(String user1, String user2) {
    return (select(messages)
      ..where((t) => 
          (t.senderId.equals(user1) & t.receiverId.equals(user2)) |
          (t.senderId.equals(user2) & t.receiverId.equals(user1)))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp)])).get();
  }

  // Mark message as read
  Future<int> markMessageAsRead(int messageId) {
    return (update(messages)..where((t) => t.id.equals(messageId)))
      .write(const MessagesCompanion(isRead: Value(true)));
  }

  // Delete old messages
  Future<int> deleteExpiredMessages(DateTime cutoff) {
    return (delete(messages)..where((t) => t.timestamp.isSmallerThanValue(cutoff)))
      .go();
  }
}