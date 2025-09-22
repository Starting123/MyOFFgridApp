import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/hkdf.dart';
import 'package:pointycastle/macs/hmac.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  static EncryptionService get instance => _instance;

  final _secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)))));

  // ECDH curve for key exchange
  static const CURVE = 'secp256r1';
  
  // Key pairs for ECDH
  late AsymmetricKeyPair<ECPublicKey, ECPrivateKey> _keyPair;
  final Map<String, Uint8List> _sharedSecrets = {};

  EncryptionService._internal() {
    _generateKeyPair();
  }

  void _generateKeyPair() {
    final domainParams = ECDomainParameters(CURVE);
    final keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(
        ECKeyGeneratorParameters(domainParams),
        _secureRandom,
      ));
    _keyPair = keyGen.generateKeyPair() as AsymmetricKeyPair<ECPublicKey, ECPrivateKey>;
  }

  // Get public key to share with other devices
  String getPublicKey() {
    final publicKey = _keyPair.publicKey.Q!;
    final xBigInt = publicKey.x!.toBigInteger()!;
    final yBigInt = publicKey.y!.toBigInteger()!;
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
    
    final domainParams = ECDomainParameters(CURVE);
    final peerPublicKey = ECPublicKey(
      domainParams.curve.createPoint(x, y),
      domainParams,
    );

    // Compute ECDH shared secret
    final agreement = ECDHBasicAgreement()
      ..init(_keyPair.privateKey);
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

  // Clean up shared secrets for a peer
  void removePeer(String peerId) {
    _sharedSecrets.remove(peerId);
  }
}
