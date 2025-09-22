import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_sos/src/services/encryption_service.dart';

void main() {
  late EncryptionService aliceService;
  late EncryptionService bobService;
  const ALICE_ID = 'alice123';
  const BOB_ID = 'bob456';

  setUp(() {
    aliceService = EncryptionService.instance;
    bobService = EncryptionService.instance;
  });

  group('Encryption Service Tests', () {
    test('get public key returns base64 string', () {
      // Act
      final publicKey = aliceService.getPublicKey();

      // Assert
      expect(publicKey, isNotNull);
      expect(() => base64Decode(publicKey), returnsNormally);
      expect(base64Decode(publicKey).length, equals(64)); // 32 bytes x + 32 bytes y
    });

    test('encrypt and decrypt roundtrip', () {
      // Arrange
      final alicePubKey = aliceService.getPublicKey();
      final bobPubKey = bobService.getPublicKey();
      
      // Establish shared secrets
      aliceService.computeSharedSecret(BOB_ID, bobPubKey);
      bobService.computeSharedSecret(ALICE_ID, alicePubKey);
      
      final plaintext = Uint8List.fromList(utf8.encode('Hello, secret world!'));

      // Act
      // Alice encrypts message for Bob
      final encrypted = aliceService.encryptForPeer(BOB_ID, plaintext);

      // Bob decrypts message from Alice
      final decrypted = bobService.decryptFromPeer(ALICE_ID, encrypted);

      // Assert
      expect(utf8.decode(decrypted), equals('Hello, secret world!'));
    });

    test('different recipients get different ciphertexts', () {
      // Arrange
      final charlieService = EncryptionService.instance;
      final alicePubKey = aliceService.getPublicKey();
      final bobPubKey = bobService.getPublicKey();
      final charliePubKey = charlieService.getPublicKey();
      
      aliceService.computeSharedSecret(BOB_ID, bobPubKey);
      aliceService.computeSharedSecret('charlie789', charliePubKey);
      
      final plaintext = Uint8List.fromList(utf8.encode('Secret message'));

      // Act
      final encryptedForBob = aliceService.encryptForPeer(BOB_ID, plaintext);
      final encryptedForCharlie = aliceService.encryptForPeer('charlie789', plaintext);

      // Assert
      expect(encryptedForBob, isNot(equals(encryptedForCharlie)));
    });

    test('fails to decrypt without shared secret', () {
      // Arrange
      final eveService = EncryptionService.instance;
      final plaintext = Uint8List.fromList(utf8.encode('Top secret message'));
      final encrypted = aliceService.encryptForPeer(BOB_ID, plaintext);

      // Assert
      expect(
        () => eveService.decryptFromPeer(ALICE_ID, encrypted),
        throwsA(isA<Exception>()),
      );
    });
  });
}