import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:offgrid_sos/src/data/db.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Message CRUD Tests', () {
    test('insert message', () async {
      // Arrange
      final message = MessagesCompanion.insert(
        messageId: 'test-msg-1',
        fromId: 'user1',
        toId: 'user2',
        type: 'text',
        body: 'Hello World',
        timestamp: DateTime.now(),
        status: MessageStatus.pending,
        ttl: const Value(24),
        hopCount: const Value(0),
      );

      // Act
      final id = await db.messageDao.insertMessage(message);

      // Assert
      expect(id, isNotNull);
      expect(id, greaterThan(0));

      final inserted = await db.messageDao.getMessage('test-msg-1');
      expect(inserted, isNotNull);
      expect(inserted!.messageId, equals('test-msg-1'));
      expect(inserted.fromId, equals('user1'));
      expect(inserted.type, equals('text'));
    });

    test('update message status', () async {
      // Arrange
      final message = MessagesCompanion.insert(
        messageId: 'test-msg-2',
        fromId: 'user1',
        toId: 'user2',
        type: 'text',
        body: 'Test Message',
        timestamp: DateTime.now(),
        status: MessageStatus.pending,
        ttl: const Value(24),
        hopCount: const Value(0),
      );
      await db.messageDao.insertMessage(message);

      // Act
      await db.messageDao.updateMessage(MessagesCompanion(
        messageId: const Value('test-msg-2'),
        status: const Value(MessageStatus.sent),
      ));

      // Assert
      final updated = await db.messageDao.getMessage('test-msg-2');
      expect(updated, isNotNull);
      expect(updated!.status, equals(MessageStatus.sent));
    });

    test('get pending messages', () async {
      // Arrange
      final now = DateTime.now();
      final messages = [
        MessagesCompanion.insert(
          messageId: 'pending-1',
          fromId: 'user1',
          toId: 'user2',
          type: 'text',
          body: 'Pending 1',
          timestamp: now,
          status: MessageStatus.pending,
          ttl: const Value(24),
          hopCount: const Value(0),
        ),
        MessagesCompanion.insert(
          messageId: 'sent-1',
          fromId: 'user1',
          toId: 'user2',
          type: 'text',
          body: 'Sent 1',
          timestamp: now,
          status: MessageStatus.sent,
          ttl: const Value(24),
          hopCount: const Value(0),
        ),
        MessagesCompanion.insert(
          messageId: 'pending-2',
          fromId: 'user1',
          toId: 'user2',
          type: 'text',
          body: 'Pending 2',
          timestamp: now,
          status: MessageStatus.pending,
          ttl: const Value(24),
          hopCount: const Value(0),
        ),
      ];

      for (final msg in messages) {
        await db.messageDao.insertMessage(msg);
      }

      // Act
      final pendingMessages = await db.messageDao.getPendingMessages();

      // Assert
      expect(pendingMessages, hasLength(2));
      expect(
        pendingMessages.map((m) => m.messageId).toList(),
        containsAll(['pending-1', 'pending-2']),
      );
    });

    test('delete expired messages', () async {
      // Arrange
      final now = DateTime.now();
      final expiredTime = now.subtract(const Duration(hours: 25));
      
      final messages = [
        MessagesCompanion.insert(
          messageId: 'fresh',
          fromId: 'user1',
          toId: 'user2',
          type: 'text',
          body: 'Fresh message',
          timestamp: now,
          status: MessageStatus.sent,
          ttl: const Value(24),
          hopCount: const Value(0),
        ),
        MessagesCompanion.insert(
          messageId: 'expired',
          fromId: 'user1',
          toId: 'user2',
          type: 'text',
          body: 'Expired message',
          timestamp: expiredTime,
          status: MessageStatus.sent,
          ttl: const Value(24),
          hopCount: const Value(0),
        ),
      ];

      for (final msg in messages) {
        await db.messageDao.insertMessage(msg);
      }

      // Act
      await db.messageDao.deleteExpiredMessages(now);

      // Assert
      final remaining = await db.messageDao.getAllMessages();
      expect(remaining, hasLength(1));
      expect(remaining.first.messageId, equals('fresh'));
    });
  });
}