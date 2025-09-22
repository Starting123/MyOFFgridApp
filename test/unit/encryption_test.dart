import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_sos/src/services/encryption_service.dart';

void main() {
  late EncryptionService aliceService;
  late EncryptionService bobService;
  const alicePeerId = 'alice123';
  const bobPeerId = 'bob456';

  setUp(() {
    aliceService = EncryptionService.instance;
    bobService = EncryptionService.instance;
  });

  group('ECDH Key Exchange', () {
    test('public keys should be different for different instances', () {
      // Act
      final alicePublicKey = aliceService.getPublicKey();
      final bobPublicKey = bobService.getPublicKey();

      // Assert
      expect(alicePublicKey, isNot(equals(bobPublicKey)));
    });

    test('shared secret establishment', () {
      // Act - Exchange public keys and compute shared secrets
      final alicePublicKey = aliceService.getPublicKey();
      final bobPublicKey = bobService.getPublicKey();

      aliceService.computeSharedSecret(bobPeerId, bobPublicKey);
      bobService.computeSharedSecret(alicePeerId, alicePublicKey);
    });
  });

  group('Secure Messaging', () {
    setUp(() {
      // Set up shared secrets before each test
      final alicePublicKey = aliceService.getPublicKey();
      final bobPublicKey = bobService.getPublicKey();

      aliceService.computeSharedSecret(bobPeerId, bobPublicKey);
      bobService.computeSharedSecret(alicePeerId, alicePublicKey);
    });

    test('encrypt and decrypt message between peers', () {
      // Arrange
      const message = 'Hello Bob, this is Alice!';

      // Act - Alice encrypts for Bob
      final encrypted = aliceService.encryptString(bobPeerId, message);
      // Bob decrypts from Alice
      final decrypted = bobService.decryptString(alicePeerId, encrypted);

      // Assert
      expect(encrypted, isNot(equals(message))); // Should be encrypted
      expect(decrypted, equals(message)); // Should decrypt back correctly
    });

    test('different messages produce different ciphertexts', () {
      // Arrange
      const message1 = 'Message 1';
      const message2 = 'Message 2';

      // Act
      final encrypted1 = aliceService.encryptString(bobPeerId, message1);
      final encrypted2 = aliceService.encryptString(bobPeerId, message2);

      // Assert
      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('same message encrypted twice produces different ciphertexts', () {
      // Arrange
      const message = 'Test message';

      // Act
      final encrypted1 = aliceService.encryptString(bobPeerId, message);
      final encrypted2 = aliceService.encryptString(bobPeerId, message);

      // Assert
      expect(encrypted1, isNot(equals(encrypted2))); // Due to random IV
    });
  });

  group('Error Cases', () {
    test('decrypt fails with unknown peer', () {
      // Arrange
      const unknownPeerId = 'unknown123';
      const message = 'Secret message';

      // Act & Assert
      expect(
        () => aliceService.encryptString(unknownPeerId, message),
        throwsA(isA<Exception>()),
      );
    });

    test('decrypt fails with invalid ciphertext', () {
      // Arrange
      aliceService.computeSharedSecret(bobPeerId, bobService.getPublicKey());

      // Act & Assert
      expect(
        () => aliceService.decryptString(bobPeerId, 'invalid-base64!'),
        throwsA(isA<Exception>()),
      );
    });

    test('peer removal', () {
      // Arrange
      const message = 'Secret message';
      aliceService.computeSharedSecret(bobPeerId, bobService.getPublicKey());
      final encrypted = aliceService.encryptString(bobPeerId, message);

      // Act
      aliceService.removePeer(bobPeerId);

      // Assert
      expect(
        () => aliceService.decryptString(bobPeerId, encrypted),
        throwsA(isA<Exception>()),
      );
    });
  });
}