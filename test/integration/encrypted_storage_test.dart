import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_sos/src/db/database.dart';
import 'package:offgrid_sos/src/services/encryption_service.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late EncryptionService alice;
  late EncryptionService bob;
  const ALICE_ID = 'alice123';
  const BOB_ID = 'bob456';

  setUp(() async {
    // Create in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
    alice = EncryptionService.instance;
    bob = EncryptionService.instance;

    // Set up encryption keys
    final alicePubKey = alice.getPublicKey();
    final bobPubKey = bob.getPublicKey();
    alice.computeSharedSecret(BOB_ID, bobPubKey);
    bob.computeSharedSecret(ALICE_ID, alicePubKey);
  });

  tearDown(() async {
    await db.close();
  });

  group('Encrypted Message Storage and Retrieval', () {
    test('store and retrieve encrypted message', () async {
      // Arrange
      final plaintext = 'Help needed at coordinates 35.6895, 139.6917';
      final encryptedBytes = alice.encryptForPeer(
        BOB_ID, 
        Uint8List.fromList(utf8.encode(plaintext))
      );
      final encryptedBase64 = base64Encode(encryptedBytes);

      // Act - Store encrypted message
      final timestamp = DateTime.now();
      await db.insertMessage(MessagesCompanion.insert(
        senderId: ALICE_ID,
        receiverId: BOB_ID,
        encryptedContent: encryptedBase64,
        timestamp: timestamp,
        isRead: false,
      ));

      // Retrieve and decrypt message
      final messages = await db.getAllMessages().get();
      expect(messages.length, equals(1));
      
      final message = messages.first;
      expect(message.senderId, equals(ALICE_ID));
      expect(message.receiverId, equals(BOB_ID));
      
      final retrievedBytes = base64Decode(message.encryptedContent);
      final decryptedBytes = bob.decryptFromPeer(ALICE_ID, retrievedBytes);
      final decryptedText = utf8.decode(decryptedBytes);

      // Assert
      expect(decryptedText, equals(plaintext));
    });

    test('messages remain encrypted in database', () async {
      // Arrange
      final plaintext = 'Secret location: Building 7';
      final encryptedBytes = alice.encryptForPeer(
        BOB_ID,
        Uint8List.fromList(utf8.encode(plaintext))
      );
      final encryptedBase64 = base64Encode(encryptedBytes);

      // Act - Store message
      await db.insertMessage(MessagesCompanion.insert(
        senderId: ALICE_ID,
        receiverId: BOB_ID,
        encryptedContent: encryptedBase64,
        timestamp: DateTime.now(),
        isRead: false,
      ));

      // Get raw database content
      final messages = await db.getAllMessages().get();
      final storedContent = messages.first.encryptedContent;

      // Assert - Verify content is not stored as plaintext
      expect(storedContent, isNot(contains(plaintext)));
      expect(storedContent, isNot(equals(plaintext)));
      
      // Should be valid base64
      expect(() => base64Decode(storedContent), returnsNormally);
    });

    test('handles multiple messages with different recipients', () async {
      // Arrange
      final charlie = EncryptionService.instance;
      final charliePubKey = charlie.getPublicKey();
      alice.computeSharedSecret('charlie789', charliePubKey);

      final message1 = 'Message for Bob';
      final message2 = 'Message for Charlie';

      // Act - Store messages for different recipients
      await db.insertMessage(MessagesCompanion.insert(
        senderId: ALICE_ID,
        receiverId: BOB_ID,
        encryptedContent: base64Encode(
          alice.encryptForPeer(BOB_ID, Uint8List.fromList(utf8.encode(message1)))
        ),
        timestamp: DateTime.now(),
        isRead: false,
      ));

      await db.insertMessage(MessagesCompanion.insert(
        senderId: ALICE_ID,
        receiverId: 'charlie789',
        encryptedContent: base64Encode(
          alice.encryptForPeer('charlie789', Uint8List.fromList(utf8.encode(message2)))
        ),
        timestamp: DateTime.now(),
        isRead: false,
      ));

      // Assert
      final messages = await db.getAllMessages().get();
      expect(messages.length, equals(2));

      // Verify Bob's message
      final bobMessage = messages.firstWhere((m) => m.receiverId == BOB_ID);
      final bobDecrypted = utf8.decode(
        bob.decryptFromPeer(ALICE_ID, base64Decode(bobMessage.encryptedContent))
      );
      expect(bobDecrypted, equals(message1));

      // Verify messages are encrypted differently
      expect(messages[0].encryptedContent, isNot(equals(messages[1].encryptedContent)));
    });
  });
}