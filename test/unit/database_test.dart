import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_sos/src/db/database.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    // Create in-memory database for testing
    db = AppDatabase.createInMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Message Database Tests', () {
    test('insert and retrieve message', () async {
      // Arrange
      final now = DateTime.now();
      final message = MessagesCompanion.insert(
        senderId: 'sender123',
        receiverId: 'receiver456',
        encryptedContent: 'encrypted_test_content',
        timestamp: now,
        isRead: false,
      );

      // Act
      final id = await db.insertMessage(message);
      final messages = await db.getAllMessages().get();

      // Assert
      expect(messages.length, equals(1));
      final retrievedMessage = messages.first;
      expect(retrievedMessage.id, equals(id));
      expect(retrievedMessage.senderId, equals('sender123'));
      expect(retrievedMessage.receiverId, equals('receiver456'));
      expect(retrievedMessage.encryptedContent, equals('encrypted_test_content'));
      expect(retrievedMessage.timestamp, equals(now));
      expect(retrievedMessage.isRead, isFalse);
    });

    test('mark message as read', () async {
      // Arrange
      final message = MessagesCompanion.insert(
        senderId: 'sender123',
        receiverId: 'receiver456',
        encryptedContent: 'test_content',
        timestamp: DateTime.now(),
        isRead: false,
      );
      final id = await db.insertMessage(message);

      // Act
      await db.markMessageAsRead(id);
      final messages = await db.getAllMessages().get();

      // Assert
      expect(messages.first.isRead, isTrue);
    });

    test('get unread messages', () async {
      // Arrange
      final now = DateTime.now();
      await db.insertMessage(MessagesCompanion.insert(
        senderId: 'sender1',
        receiverId: 'receiver1',
        encryptedContent: 'content1',
        timestamp: now,
        isRead: true,
      ));
      await db.insertMessage(MessagesCompanion.insert(
        senderId: 'sender2',
        receiverId: 'receiver2',
        encryptedContent: 'content2',
        timestamp: now,
        isRead: false,
      ));

      // Act
      final unreadMessages = await db.getUnreadMessages();

      // Assert
      expect(unreadMessages.length, equals(1));
      expect(unreadMessages.first.encryptedContent, equals('content2'));
    });

    test('get messages between users', () async {
      // Arrange
      final now = DateTime.now();
      await db.insertMessage(MessagesCompanion.insert(
        senderId: 'alice',
        receiverId: 'bob',
        encryptedContent: 'message1',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ));
      await db.insertMessage(MessagesCompanion.insert(
        senderId: 'bob',
        receiverId: 'alice',
        encryptedContent: 'message2',
        timestamp: now,
        isRead: false,
      ));
      await db.insertMessage(MessagesCompanion.insert(
        senderId: 'charlie',
        receiverId: 'alice',
        encryptedContent: 'message3',
        timestamp: now,
        isRead: false,
      ));

      // Act
      final messages = await db.getMessagesBetween('alice', 'bob');

      // Assert
      expect(messages.length, equals(2));
      expect(messages.every((m) => 
        (m.senderId == 'alice' && m.receiverId == 'bob') ||
        (m.senderId == 'bob' && m.receiverId == 'alice')
      ), isTrue);
    });

    test('delete expired messages', () async {
      // Arrange
      final now = DateTime.now();
      final oldMessage = MessagesCompanion.insert(
        senderId: 'sender1',
        receiverId: 'receiver1',
        encryptedContent: 'old_content',
        timestamp: now.subtract(const Duration(days: 30)),
        isRead: true,
      );
      final newMessage = MessagesCompanion.insert(
        senderId: 'sender2',
        receiverId: 'receiver2',
        encryptedContent: 'new_content',
        timestamp: now,
        isRead: false,
      );

      await db.insertMessage(oldMessage);
      await db.insertMessage(newMessage);

      // Act
      await db.deleteExpiredMessages(now.subtract(const Duration(days: 7)));
      final remainingMessages = await db.getAllMessages().get();

      // Assert
      expect(remainingMessages.length, equals(1));
      expect(remainingMessages.first.encryptedContent, equals('new_content'));
    });
  });
}