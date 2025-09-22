import 'package:flutter_test/flutter_test.dart';
import '../lib/src/services/nearby_service.dart';
import '../lib/src/services/ble_service.dart';

void main() {
  group('NearbyService Tests', () {
    late NearbyService nearbyService;

    setUp(() {
      nearbyService = NearbyService.instance;
    });

    test('initialize should complete', () async {
      expect(await nearbyService.initialize(), isTrue);
    });

    test('start/stop advertising', () async {
      await nearbyService.startAdvertising('TestDevice');
      await Future.delayed(const Duration(seconds: 1));
      await nearbyService.stopAdvertising();
      expect(true, isTrue); // Just checking if no exceptions are thrown
    });

    test('start/stop discovery', () async {
      await nearbyService.startDiscovery();
      await Future.delayed(const Duration(seconds: 1));
      await nearbyService.stopDiscovery();
      expect(true, isTrue);
    });
  });

  group('BLEService Tests', () {
    late BLEService bleService;

    setUp(() {
      bleService = BLEService.instance;
    });

    test('initialize should complete', () async {
      expect(await bleService.initialize(), isTrue);
    });

    test('start/stop scanning', () async {
      await bleService.startScan();
      await Future.delayed(const Duration(seconds: 1));
      await bleService.stopScan();
      expect(true, isTrue);
    });
  });
}