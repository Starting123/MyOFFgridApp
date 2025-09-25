import 'lib/src/services/encryption_service.dart';

void main() {
  print('Testing EncryptionService...');
  
  try {
    final encryption = EncryptionService.instance;
    final publicKey = encryption.getPublicKey();
    print('✅ EncryptionService working! Public key generated: ${publicKey.substring(0, 20)}...');
  } catch (e) {
    print('❌ EncryptionService error: $e');
  }
}