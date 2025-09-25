import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../utils/logger.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  static EncryptionService get instance => _instance;

  final _secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)))));

  // ECDH curve for key exchange
  static const curve = 'secp256r1';
  
  // Key pairs for ECDH
  late AsymmetricKeyPair<PublicKey, PrivateKey> _keyPair;
  final Map<String, Uint8List> _sharedSecrets = {};

  EncryptionService._internal() {
    _generateKeyPair();
  }

  void _generateKeyPair() {
    try {
      final domainParams = ECDomainParameters(curve);
      final keyGen = ECKeyGenerator()
        ..init(ParametersWithRandom(
          ECKeyGeneratorParameters(domainParams),
          _secureRandom,
        ));
      final keyPair = keyGen.generateKeyPair();
      _keyPair = keyPair;
    } catch (e) {
      Logger.error('Error generating key pair', 'Encryption', e);
      // Fallback key generation
      _generateSimpleKeyPair();
    }
  }

  void _generateSimpleKeyPair() {
    try {
      final keyGen = ECKeyGenerator();
      final params = ECKeyGeneratorParameters(ECDomainParameters(curve));
      keyGen.init(ParametersWithRandom(params, _secureRandom));
      _keyPair = keyGen.generateKeyPair();
    } catch (e) {
      Logger.error('Error with simple key generation', 'Encryption', e);
      rethrow;
    }
  }

  // Get public key to share with other devices
  String getPublicKey() {
    final publicKey = _keyPair.publicKey as ECPublicKey;
    final q = publicKey.Q!;
    final xBigInt = q.x!.toBigInteger()!;
    final yBigInt = q.y!.toBigInteger()!;
    return base64Encode(
      Uint8List.fromList([
        ...bigIntToBytes(xBigInt),
        ...bigIntToBytes(yBigInt)
      ]),
    );
  }

  // Compute shared secret with another device's public key
  void computeSharedSecret(String peerId, String peerPublicKeyBase64) {
    final peerPublicKeyBytes = base64Decode(peerPublicKeyBase64);
    final x = BigInt.parse(
      base64Encode(peerPublicKeyBytes.sublist(0, 32)),
      radix: 16
    );
    final y = BigInt.parse(
      base64Encode(peerPublicKeyBytes.sublist(32)),
      radix: 16
    );
    
    final domainParams = ECDomainParameters(curve);
    final peerPublicKey = ECPublicKey(
      domainParams.curve.createPoint(x, y),
      domainParams,
    );

    // Compute ECDH shared secret
    final agreement = ECDHBasicAgreement()
      ..init(_keyPair.privateKey as ECPrivateKey);
    final sharedSecret = agreement.calculateAgreement(peerPublicKey);
    
    // Derive encryption key using HKDF
    final hkdf = HKDFKeyDerivator(SHA256Digest());
    hkdf.init(HkdfParameters(
      bigIntToBytes(sharedSecret),
      32,
      Uint8List(0),
    ));
    
    _sharedSecrets[peerId] = hkdf.process(Uint8List(32));
  }

  // Encrypt data for a specific peer
  Uint8List encryptForPeer(String peerId, Uint8List plaintext) {
    if (!_sharedSecrets.containsKey(peerId)) {
      throw Exception('No shared secret established with peer: $peerId');
    }

    final iv = _secureRandom.nextBytes(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(_sharedSecrets[peerId]!),
          128,
          iv,
          Uint8List(0),
        ),
      );

    final ciphertext = cipher.process(plaintext);
    return Uint8List.fromList([...iv, ...ciphertext]);
  }

  // Decrypt data from a specific peer
  // BigInt utility methods
  Uint8List bigIntToBytes(BigInt number) {
    final size = (number.bitLength + 7) >> 3;
    final result = Uint8List(size);
    var value = number;
    for (var i = size - 1; i >= 0; i--) {
      result[i] = value.toUnsigned(8).toInt();
      value = value >> 8;
    }
    return result;
  }

  Uint8List decryptFromPeer(String peerId, Uint8List ciphertext) {
    if (!_sharedSecrets.containsKey(peerId)) {
      throw Exception('No shared secret established with peer: $peerId');
    }

    final iv = ciphertext.sublist(0, 12);
    final encrypted = ciphertext.sublist(12);
    
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(_sharedSecrets[peerId]!),
          128,
          iv,
          Uint8List(0),
        ),
      );

    return cipher.process(encrypted);
  }

  // Convenience methods for string encryption
  String encryptString(String peerId, String plaintext) {
    final plaintextBytes = utf8.encode(plaintext);
    final ciphertext = encryptForPeer(peerId, Uint8List.fromList(plaintextBytes));
    return base64Encode(ciphertext);
  }

  String decryptString(String peerId, String ciphertext) {
    final ciphertextBytes = base64Decode(ciphertext);
    final plaintext = decryptFromPeer(peerId, ciphertextBytes);
    return utf8.decode(plaintext);
  }

  // High-level message encryption methods
  String encryptMessage(String content, String recipientId) {
    try {
      if (!_sharedSecrets.containsKey(recipientId)) {
        // For emergency messages, return unencrypted (they should be readable by all)
        return content;
      }
      return encryptString(recipientId, content);
    } catch (e) {
      Logger.error('Error encrypting message', 'Encryption', e);
      // Return original content if encryption fails
      return content;
    }
  }

  String decryptMessage(String encryptedContent, String senderId) {
    try {
      if (!_sharedSecrets.containsKey(senderId)) {
        // If no shared secret, assume it's unencrypted
        return encryptedContent;
      }
      return decryptString(senderId, encryptedContent);
    } catch (e) {
      Logger.error('Error decrypting message', 'Encryption', e);
      // Return original content if decryption fails
      return encryptedContent;
    }
  }

  // Check if we can encrypt for a peer
  bool canEncryptForPeer(String peerId) {
    return _sharedSecrets.containsKey(peerId);
  }

  // Get all peers we have shared secrets with
  List<String> getEncryptionPeers() {
    return _sharedSecrets.keys.toList();
  }

  // Clean up shared secrets for a peer
  void removePeer(String peerId) {
    _sharedSecrets.remove(peerId);
  }
}
