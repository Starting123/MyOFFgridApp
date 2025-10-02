import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_sos/src/services/nearby_service.dart';
import 'package:offgrid_sos/src/utils/debug_helper.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Device Discovery Tests', () {
    late NearbyService nearbyService;

    setUp(() {
      nearbyService = NearbyService.instance;
    });

    test('should initialize nearby service', () async {
      final result = await nearbyService.initialize();
      expect(result, isTrue);
    });

    test('should start advertising', () async {
      await nearbyService.initialize();
      
      expect(() async {
        await nearbyService.startAdvertising('Test_SOS_Device');
      }, returnsNormally);
    });

    test('should start discovery', () async {
      await nearbyService.initialize();
      
      expect(() async {
        await nearbyService.startDiscovery();
      }, returnsNormally);
    });

    test('should broadcast SOS message', () async {
      await nearbyService.initialize();
      await nearbyService.startAdvertising('Test_Device');
      
      expect(() async {
        await nearbyService.broadcastSOS(
          deviceId: 'test_device_123',
          message: 'Test emergency message',
          additionalData: {
            'priority': 'high',
            'location': {'lat': 0.0, 'lon': 0.0},
          },
        );
      }, returnsNormally);
    });
  });

  group('Debug Helper Tests', () {
    test('should check permissions without errors', () async {
      expect(() async {
        await DeviceDiscoveryDebugger.checkAllPermissions();
      }, returnsNormally);
    });

    test('should check device capabilities', () {
      expect(() {
        DeviceDiscoveryDebugger.checkDeviceCapabilities();
      }, returnsNormally);
    });

    test('should log troubleshooting steps', () {
      expect(() {
        DeviceDiscoveryDebugger.logTroubleshootingSteps();
      }, returnsNormally);
    });

    test('should log expected behavior', () {
      expect(() {
        DeviceDiscoveryDebugger.logExpectedBehavior();
      }, returnsNormally);
    });
  });
}