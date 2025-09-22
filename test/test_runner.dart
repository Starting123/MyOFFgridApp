import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'unit/database_test.dart' as database_test;
import 'unit/encryption_service_test.dart' as encryption_test;
import 'integration/encrypted_storage_test.dart' as integration_test;

void main() {
  group('Unit Tests', () {
    database_test.main();
    encryption_test.main();
  });

  group('Integration Tests', () {
    integration_test.main();
  });
}