import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:offgrid_sos/src/services/encryption_service.dart';
import 'package:offgrid_sos/src/data/db.dart';
import 'package:matcher/matcher.dart' as matcher;

void main() {
  late AppDatabase db;
  late EncryptionService alice;
  late EncryptionService bob;
  late MessageDao messageDao;
  const alicePeerId = 'alice123';
  const bobPeerId = 'bob456';

  setUp(() async {
    // Initialize services
    db = AppDatabase();
    messageDao = db.messageDao;
    alice = EncryptionService.instance;
    bob = EncryptionService.instance;

    // Set up encryption between Alice and Bob
    final alicePublicKey = alice.getPublicKey();
    final bobPublicKey = bob.getPublicKey();
    alice.computeSharedSecret(bobPeerId, bobPublicKey);
    bob.computeSharedSecret(alicePeerId, alicePublicKey);
  });

  tearDown(() async {
    await db.close();
  });

  group('End-to-End Message Flow Tests', () {
    test('send encrypted message from Alice to Bob through database', () async {
      // Arrange
      const originalMessage = 'Hello Bob, this is a secret message!';
      final now = DateTime.now();
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

      // Act - Alice encrypts and stores message
      final encryptedContent = alice.encryptString(bobPeerId, originalMessage);
      await messageDao.insertMessage(MessagesCompanion(
        messageId: Value(messageId),
        fromId: Value(alicePeerId),
        toId: Value(bobPeerId),
        type: const Value('text'),
        body: Value(encryptedContent),
        filePath: const Value(null),
        timestamp: Value(now),
        status: const Value(MessageStatus.sent),
        ttl: const Value(24),
        hopCount: const Value(0),
      ));

      // Bob retrieves and decrypts message
      final message = await messageDao.getMessage(messageId);
      expect(message, matcher.isNotNull);

      final decryptedContent = bob.decryptString(alicePeerId, message!.body);

      // Assert
      expect(decryptedContent, equals(originalMessage));
      expect(message.fromId, equals(alicePeerId));
      expect(message.toId, equals(bobPeerId));
      expect(message.timestamp, equals(now));
      expect(message.status, equals(MessageStatus.sent));
    });

    test('handle multiple messages between users', () async {
      // Arrange
      final messages = [
        'Message 1 from Alice',
        'Message 2 from Bob',
        'Message 3 from Alice',
      ];
      final now = DateTime.now();

      // Act - Store multiple messages
      for (var i = 0; i < messages.length; i++) {
        final isFromAlice = i % 2 == 0;
        final sender = isFromAlice ? alice : bob;
        final receiver = isFromAlice ? bobPeerId : alicePeerId;
        final senderId = isFromAlice ? alicePeerId : bobPeerId;

        final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_$i';
        final encrypted = sender.encryptString(receiver, messages[i]);
        
        await messageDao.insertMessage(MessagesCompanion(
          messageId: Value(messageId),
          fromId: Value(senderId),
          toId: Value(receiver),
          type: const Value('text'),
          body: Value(encrypted),
          filePath: const Value(null),
          timestamp: Value(now.add(Duration(minutes: i))),
          status: const Value(MessageStatus.sent),
          ttl: const Value(24),
          hopCount: const Value(0),
        ));
      }

      // Retrieve messages using watchChatMessages stream
      final aliceBobChat = await messageDao.watchChatMessages(bobPeerId).first;

      final decryptedMessages = aliceBobChat.map((msg) {
        final isToAlice = msg.toId == alicePeerId;
        final receiverService = isToAlice ? alice : bob;
        final senderId = isToAlice ? bobPeerId : alicePeerId;
        return receiverService.decryptString(senderId, msg.body);
      }).toList();

      // Assert
      expect(aliceBobChat.length, equals(3));
      for (var i = 0; i < messages.length; i++) {
        expect(decryptedMessages[i], equals(messages[i]));
      }
    });

    test('message cleanup based on TTL', () async {
      // Arrange
      const message = 'This message should be deleted';
      final oldTimestamp = DateTime.now().subtract(const Duration(days: 2));
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
      final encryptedContent = alice.encryptString(bobPeerId, message);
      
      await messageDao.insertMessage(MessagesCompanion(
        messageId: Value(messageId),
        fromId: Value(alicePeerId),
        toId: Value(bobPeerId),
        type: const Value('text'),
        body: Value(encryptedContent),
        filePath: const Value(null),
        timestamp: Value(oldTimestamp),
        status: const Value(MessageStatus.sent),
        ttl: const Value(1), // 1 hour TTL
        hopCount: const Value(0),
      ));

      // Verify message exists
      final messageExists = await messageDao.messageExists(messageId);
      expect(messageExists, isTrue);

      // Act - Get pending messages
      final pendingMessages = await messageDao.getPendingMessages();

      // Assert
      expect(pendingMessages.isEmpty, isTrue);
    });

    test('message ordering in chat view', () async {
      // Arrange
      final messages = List.generate(5, (i) => 'Message ${i + 1}');
      final now = DateTime.now();

      // Act - Store messages with timestamps
      for (var i = 0; i < messages.length; i++) {
        final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_$i';
        final encrypted = alice.encryptString(bobPeerId, messages[i]);
        
        await messageDao.insertMessage(MessagesCompanion(
          messageId: Value(messageId),
          fromId: Value(alicePeerId),
          toId: Value(bobPeerId),
          type: const Value('text'),
          body: Value(encrypted),
          filePath: const Value(null),
          timestamp: Value(now.add(Duration(minutes: i))),
          status: const Value(MessageStatus.sent),
          ttl: const Value(24),
          hopCount: const Value(0),
        ));
      }

      // Retrieve messages using chat view
      final chatMessages = await messageDao.watchChatMessages(bobPeerId).first;
      final decryptedMessages = chatMessages.map((msg) =>
        bob.decryptString(alicePeerId, msg.body)
      ).toList();

      // Assert
      expect(chatMessages.length, equals(5));
      for (var i = 0; i < messages.length; i++) {
        expect(decryptedMessages[i], equals(messages[i]));
      }

      // Verify timestamps are in order
      for (var i = 1; i < chatMessages.length; i++) {
        expect(
          chatMessages[i].timestamp.isAfter(chatMessages[i - 1].timestamp),
          isTrue,
        );
      }
    });
  });
}