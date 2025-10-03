import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../utils/logger.dart';

/// Production-ready encryption service with ECDH key exchange and AES-GCM encryption
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  static EncryptionService get instance => _instance;

  late final SecureRandom _secureRandom;
  late final ECDomainParameters _domainParams;
  
  // Persistent key pairs for ECDH
  late AsymmetricKeyPair<ECPublicKey, ECPrivateKey> _keyPair;
  final Map<String, Uint8List> _sharedSecrets = {};

  // ECDH curve for key exchange (NIST P-256)
  static const String _curveName = 'secp256r1';
  static const int _keySize = 32; // 256 bits
  static const int _ivSize = 12;  // 96 bits for GCM
  static const int _tagSize = 16; // 128 bits for GCM

  EncryptionService._internal() {
    _initializeSecureRandom();
    _initializeCurve();
    _generateKeyPair();
  }

  /// Initialize secure random number generator
  void _initializeSecureRandom() {
    _secureRandom = SecureRandom('Fortuna');
    final seed = Uint8List.fromList(
      List.generate(32, (_) => Random.secure().nextInt(256))
    );
    _secureRandom.seed(KeyParameter(seed));
  }

  /// Initialize the elliptic curve domain parameters
  void _initializeCurve() {
    _domainParams = ECDomainParameters(_curveName);
  }

  /// Generate a new ECDH key pair
  void _generateKeyPair() {
    try {
      final keyGen = ECKeyGenerator();
      keyGen.init(ParametersWithRandom(
        ECKeyGeneratorParameters(_domainParams),
        _secureRandom,
      ));
      
      final keyPair = keyGen.generateKeyPair();
      _keyPair = AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
        keyPair.publicKey as ECPublicKey,
        keyPair.privateKey as ECPrivateKey,
      );
      
      Logger.info('ECDH key pair generated successfully', 'Encryption');
    } catch (e) {
      Logger.error('Error generating ECDH key pair', 'Encryption', e);
      rethrow;
    }
  }

  /// Generate ephemeral key pair for temporary key exchange
  AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateEphemeralKeypair() {
    try {
      final keyGen = ECKeyGenerator();
      keyGen.init(ParametersWithRandom(
        ECKeyGeneratorParameters(_domainParams),
        _secureRandom,
      ));
      
      final keyPair = keyGen.generateKeyPair();
      return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
        keyPair.publicKey as ECPublicKey,
        keyPair.privateKey as ECPrivateKey,
      );
    } catch (e) {
      Logger.error('Error generating ephemeral key pair', 'Encryption', e);
      rethrow;
    }
  }

  /// Get the public key as base64 encoded string
  String getPublicKey() {
    return _encodePublicKey(_keyPair.publicKey);
  }

  /// Encode public key to base64 string
  String _encodePublicKey(ECPublicKey publicKey) {
    final q = publicKey.Q!;
    final xBytes = _bigIntToBytes(q.x!.toBigInteger()!, _keySize);
    final yBytes = _bigIntToBytes(q.y!.toBigInteger()!, _keySize);
    return base64Encode(Uint8List.fromList([...xBytes, ...yBytes]));
  }

  /// Decode public key from base64 string
  ECPublicKey _decodePublicKey(String publicKeyBase64) {
    try {
      final publicKeyBytes = base64Decode(publicKeyBase64);
      if (publicKeyBytes.length != _keySize * 2) {
        throw ArgumentError('Invalid public key length');
      }
      
      final xBytes = publicKeyBytes.sublist(0, _keySize);
      final yBytes = publicKeyBytes.sublist(_keySize);
      final x = _bytesToBigInt(xBytes);
      final y = _bytesToBigInt(yBytes);
      
      final point = _domainParams.curve.createPoint(x, y);
      return ECPublicKey(point, _domainParams);
    } catch (e) {
      Logger.error('Error decoding public key', 'Encryption', e);
      rethrow;
    }
  }

  /// Compute shared secret with another device's public key
  Uint8List computeSharedSecret(String peerPublicKeyBase64, {ECPrivateKey? ephemeralPrivateKey}) {
    try {
      final peerPublicKey = _decodePublicKey(peerPublicKeyBase64);
      final privateKey = ephemeralPrivateKey ?? _keyPair.privateKey;
      
      // Compute ECDH shared secret
      final agreement = ECDHBasicAgreement();
      agreement.init(privateKey);
      final sharedSecret = agreement.calculateAgreement(peerPublicKey);
      
      // Derive encryption key using HKDF
      final hkdf = HKDFKeyDerivator(SHA256Digest());
      hkdf.init(HkdfParameters(
        _bigIntToBytes(sharedSecret, _keySize),
        _keySize,
        Uint8List.fromList('OffGridSOS'.codeUnits), // Salt
        Uint8List.fromList('ECDH-AES-GCM'.codeUnits), // Info
      ));
      
      return hkdf.process(Uint8List(_keySize));
    } catch (e) {
      Logger.error('Error computing shared secret', 'Encryption', e);
      rethrow;
    }
  }

  /// Store shared secret for a peer
  void storeSharedSecret(String peerId, String peerPublicKeyBase64) {
    try {
      final sharedSecret = computeSharedSecret(peerPublicKeyBase64);
      _sharedSecrets[peerId] = sharedSecret;
      Logger.info('Shared secret established with peer: $peerId', 'Encryption');
    } catch (e) {
      Logger.error('Error storing shared secret for peer: $peerId', 'Encryption', e);
      rethrow;
    }
  }

  /// Encrypt bytes using AES-GCM with shared secret
  Uint8List encryptBytes(Uint8List plaintext, {String? peerId, Uint8List? key}) {
    try {
      final encryptionKey = key ?? (peerId != null ? _sharedSecrets[peerId] : null);
      if (encryptionKey == null) {
        throw ArgumentError('No encryption key or peer ID provided');
      }

      // Generate random IV (nonce) for GCM
      final iv = _generateRandomBytes(_ivSize);
      
      // Initialize AES-GCM cipher
      final cipher = GCMBlockCipher(AESEngine());
      cipher.init(true, AEADParameters(
        KeyParameter(encryptionKey),
        _tagSize * 8, // Tag size in bits
        iv,
        Uint8List(0), // No additional authenticated data
      ));

      // Encrypt the plaintext
      final ciphertext = cipher.process(plaintext);
      
      // Return IV + ciphertext (includes authentication tag)
      return Uint8List.fromList([...iv, ...ciphertext]);
    } catch (e) {
      Logger.error('Error encrypting bytes', 'Encryption', e);
      rethrow;
    }
  }

  /// Decrypt bytes using AES-GCM with shared secret
  Uint8List decryptBytes(Uint8List ciphertext, {String? peerId, Uint8List? key}) {
    try {
      final decryptionKey = key ?? (peerId != null ? _sharedSecrets[peerId] : null);
      if (decryptionKey == null) {
        throw ArgumentError('No decryption key or peer ID provided');
      }

      if (ciphertext.length < _ivSize) {
        throw ArgumentError('Ciphertext too short');
      }

      // Extract IV and encrypted data
      final iv = ciphertext.sublist(0, _ivSize);
      final encrypted = ciphertext.sublist(_ivSize);
      
      // Initialize AES-GCM cipher for decryption
      final cipher = GCMBlockCipher(AESEngine());
      cipher.init(false, AEADParameters(
        KeyParameter(decryptionKey),
        _tagSize * 8, // Tag size in bits
        iv,
        Uint8List(0), // No additional authenticated data
      ));

      // Decrypt the ciphertext
      return cipher.process(encrypted);
    } catch (e) {
      Logger.error('Error decrypting bytes', 'Encryption', e);
      rethrow;
    }
  }

  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextUint8();
    }
    return bytes;
  }

  /// Convert BigInt to bytes with specified length
  Uint8List _bigIntToBytes(BigInt number, int length) {
    final bytes = Uint8List(length);
    var temp = number;
    
    for (int i = length - 1; i >= 0; i--) {
      bytes[i] = temp.toUnsigned(8).toInt();
      temp = temp >> 8;
    }
    
    return bytes;
  }

  /// Convert bytes to BigInt
  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) + BigInt.from(bytes[i]);
    }
    return result;
  }

  // ========== HIGH-LEVEL CONVENIENCE METHODS ==========

  /// Encrypt data for a specific peer (legacy method - uses encryptBytes)
  Uint8List encryptForPeer(String peerId, Uint8List plaintext) {
    return encryptBytes(plaintext, peerId: peerId);
  }

  /// Decrypt data from a specific peer (legacy method - uses decryptBytes)
  Uint8List decryptFromPeer(String peerId, Uint8List ciphertext) {
    return decryptBytes(ciphertext, peerId: peerId);
  }

  /// Encrypt string using peer's shared secret
  String encryptString(String peerId, String plaintext) {
    try {
      final plaintextBytes = utf8.encode(plaintext);
      final ciphertext = encryptBytes(Uint8List.fromList(plaintextBytes), peerId: peerId);
      return base64Encode(ciphertext);
    } catch (e) {
      Logger.error('Error encrypting string for peer: $peerId', 'Encryption', e);
      rethrow;
    }
  }

  /// Decrypt string using peer's shared secret
  String decryptString(String peerId, String ciphertext) {
    try {
      final ciphertextBytes = base64Decode(ciphertext);
      final plaintext = decryptBytes(ciphertextBytes, peerId: peerId);
      return utf8.decode(plaintext);
    } catch (e) {
      Logger.error('Error decrypting string from peer: $peerId', 'Encryption', e);
      rethrow;
    }
  }

  /// High-level message encryption with fallback
  String encryptMessage(String content, String recipientId) {
    try {
      if (!_sharedSecrets.containsKey(recipientId)) {
        Logger.warning('No shared secret for recipient: $recipientId, message sent unencrypted', 'Encryption');
        return content; // Emergency messages or no key established
      }
      return encryptString(recipientId, content);
    } catch (e) {
      Logger.error('Error encrypting message for recipient: $recipientId', 'Encryption', e);
      return content; // Fallback to unencrypted
    }
  }

  /// High-level message decryption with fallback
  String decryptMessage(String encryptedContent, String senderId) {
    try {
      if (!_sharedSecrets.containsKey(senderId)) {
        Logger.info('No shared secret for sender: $senderId, assuming unencrypted', 'Encryption');
        return encryptedContent; // Assume unencrypted
      }
      return decryptString(senderId, encryptedContent);
    } catch (e) {
      Logger.error('Error decrypting message from sender: $senderId', 'Encryption', e);
      return encryptedContent; // Fallback to original
    }
  }

  // ========== PEER MANAGEMENT METHODS ==========

  /// Check if we can encrypt for a peer
  bool canEncryptForPeer(String peerId) {
    return _sharedSecrets.containsKey(peerId);
  }

  /// Get all peers we have shared secrets with
  List<String> getEncryptionPeers() {
    return _sharedSecrets.keys.toList();
  }

  /// Clean up shared secrets for a peer
  void removePeer(String peerId) {
    _sharedSecrets.remove(peerId);
    Logger.info('Removed shared secret for peer: $peerId', 'Encryption');
  }

  /// Get number of established shared secrets
  int get sharedSecretCount => _sharedSecrets.length;

  /// Clear all shared secrets (use with caution)
  void clearAllSharedSecrets() {
    _sharedSecrets.clear();
    Logger.warning('All shared secrets cleared', 'Encryption');
  }

  // ========== UTILITY METHODS ==========

  /// Generate random key for symmetric encryption
  Uint8List generateRandomKey() {
    return _generateRandomBytes(_keySize);
  }

  /// Validate that encryption service is properly initialized
  bool get isInitialized {
    try {
      return _keyPair.publicKey.Q != null && _keyPair.privateKey.d != null;
    } catch (e) {
      return false;
    }
  }

  /// Get encryption service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': isInitialized,
      'publicKey': isInitialized ? getPublicKey() : null,
      'sharedSecrets': _sharedSecrets.length,
      'peers': _sharedSecrets.keys.toList(),
      'curveName': _curveName,
      'keySize': _keySize,
    };
  }
}
