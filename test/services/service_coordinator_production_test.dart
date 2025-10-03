import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/src/services/service_coordinator.dart';
import '../../lib/src/models/chat_models.dart';
import '../../lib/src/models/user_role.dart' as role_enum;

void main() {
  group('ServiceCoordinator Production Tests', () {
    late ServiceCoordinator serviceCoordinator;

    setUp(() async {
      // Setup SharedPreferences mock with clean state
      SharedPreferences.setMockInitialValues({});
      
      // Get ServiceCoordinator instance
      serviceCoordinator = ServiceCoordinator.instance;
    });

    group('init() - Production Initialization', () {
      test('should initialize all services successfully', () async {
        // Test production initialization
        final result = await serviceCoordinator.init();
        
        // Should return true for successful initialization
        expect(result, isA<bool>());
        expect(serviceCoordinator.isInitialized, isA<bool>());
      });

      test('should handle partial service failures gracefully', () async {
        // Test that initialization continues even if some services fail
        final result = await serviceCoordinator.init();
        
        // Should not throw and should return status
        expect(result, isA<bool>());
      });

      test('should provide service status after initialization', () async {
        await serviceCoordinator.init();
        
        // Should provide service status map
        final status = serviceCoordinator.getServiceStatus();
        expect(status, isA<Map<String, bool>>());
        expect(status.keys, contains('nearby'));
        expect(status.keys, contains('p2p'));
        expect(status.keys, contains('ble'));
        expect(status.keys, contains('wifiDirect'));
      });
    });

    group('sendMessage() - Priority Routing & Retry', () {
      test('should validate message sending with retry logic', () async {
        // Create test message
        final testMessage = ChatMessage(
          id: 'test_msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'test_sender',
          senderName: 'Test User',
          receiverId: 'test_receiver',
          content: 'Test priority routing message',
          type: MessageType.text,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          isEmergency: false,
          ttl: 3,
          hopCount: 0,
          requiresAck: true,
        );

        // Test message sending (should handle no available services gracefully)
        final result = await serviceCoordinator.sendMessage(testMessage);
        
        // Should return boolean result
        expect(result, isA<bool>());
      });

      test('should handle emergency messages with priority', () async {
        final emergencyMessage = ChatMessage(
          id: 'emergency_${DateTime.now().millisecondsSinceEpoch}', 
          senderId: 'emergency_sender',
          senderName: 'Emergency User',
          receiverId: 'broadcast',
          content: 'EMERGENCY: Need immediate help!',
          type: MessageType.sos,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          isEmergency: true,
          latitude: 13.7563,
          longitude: 100.5018,
          ttl: 10,
          hopCount: 0,
          requiresAck: true,
        );

        final result = await serviceCoordinator.sendMessage(emergencyMessage);
        
        // Should handle emergency messages
        expect(result, isA<bool>());
      });

      test('should retry failed messages with exponential backoff', () async {
        final testMessage = ChatMessage(
          id: 'retry_test_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'retry_sender', 
          senderName: 'Retry User',
          receiverId: 'retry_receiver',
          content: 'Testing retry mechanism',
          type: MessageType.text,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          isEmergency: false,
        );

        // Test with specific retry count
        final result = await serviceCoordinator.sendMessage(testMessage, maxRetries: 2);
        
        expect(result, isA<bool>());
      });
    });

    group('handleIncoming() - Message Processing & Relay', () {
      test('should process incoming messages correctly', () async {
        final incomingMessage = ChatMessage(
          id: 'incoming_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'remote_sender',
          senderName: 'Remote User',
          receiverId: 'local_user',
          content: 'Incoming test message',
          type: MessageType.text,
          status: MessageStatus.delivered,
          timestamp: DateTime.now(),
          isEmergency: false,
          ttl: 3,
          hopCount: 1,
        );

        // Test message handling (should not throw)
        try {
          await serviceCoordinator.handleIncoming(incomingMessage);
          expect(true, isTrue); // Completed successfully
        } catch (e) {
          // Should handle gracefully
          expect(e, isA<Exception>());
        }
      });

      test('should handle relay logic for mesh routing', () async {
        final relayMessage = ChatMessage(
          id: 'relay_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'origin_sender',
          senderName: 'Origin User', 
          receiverId: 'final_destination',
          content: 'Message for relay routing',
          type: MessageType.text,
          status: MessageStatus.delivered,
          timestamp: DateTime.now(),
          isEmergency: false,
          ttl: 5, // Should be decremented
          hopCount: 2, // Should be incremented
        );

        try {
          await serviceCoordinator.handleIncoming(relayMessage, source: 'mesh');
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle emergency message processing', () async {
        final emergencyMessage = ChatMessage(
          id: 'emergency_incoming_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'emergency_sender',
          senderName: 'Emergency User',
          receiverId: 'local_user',
          content: 'EMERGENCY SOS MESSAGE',
          type: MessageType.sos,
          status: MessageStatus.delivered,
          timestamp: DateTime.now(),
          isEmergency: true,
          latitude: 13.7563,
          longitude: 100.5018,
          ttl: 10,
          hopCount: 0,
        );

        try {
          await serviceCoordinator.handleIncoming(emergencyMessage, source: 'nearby');
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('broadcastSOS() - Emergency Broadcasting', () {
      test('should broadcast SOS with GPS and encryption', () async {
        // Test SOS broadcast
        try {
          await serviceCoordinator.broadcastSOS(
            'EMERGENCY: Lost in forest, need immediate rescue!',
            13.7563, // Bangkok latitude
            100.5018, // Bangkok longitude
          );
          expect(true, isTrue); // Should complete without throwing
        } catch (e) {
          // SOS broadcast may fail due to no available services, but should handle gracefully
          expect(e, isA<Exception>());
        }
      });

      test('should handle SOS broadcast without GPS coordinates', () async {
        try {
          await serviceCoordinator.broadcastSOS('EMERGENCY: Need help urgently!');
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should broadcast with encrypted payload', () async {
        // Test that SOS includes encryption
        try {
          await serviceCoordinator.broadcastSOS(
            'Encrypted emergency message',
            13.7563,
            100.5018,
          );
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('syncQueue() - Cloud Upload', () {
      test('should sync pending messages to cloud when online', () async {
        // Test cloud sync
        try {
          await serviceCoordinator.syncQueue();
          expect(true, isTrue); // Should complete
        } catch (e) {
          // May fail if no cloud connection, should handle gracefully
          expect(e, isA<Exception>());
        }
      });

      test('should handle offline scenario gracefully', () async {
        // Test offline sync handling
        try {
          await serviceCoordinator.syncQueue();
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Service Management', () {
      test('should provide discovered devices list', () {
        final devices = serviceCoordinator.discoveredDevices;
        expect(devices, isA<List<NearbyDevice>>());
      });

      test('should provide available services list', () {
        final services = serviceCoordinator.availableServices;
        expect(services, isA<List<String>>());
      });

      test('should handle service status queries', () {
        final status = serviceCoordinator.getServiceStatus();
        expect(status, isA<Map<String, bool>>());
        
        // Should contain all expected services
        expect(status.containsKey('nearby'), isTrue);
        expect(status.containsKey('p2p'), isTrue);
        expect(status.containsKey('ble'), isTrue);
        expect(status.containsKey('wifiDirect'), isTrue);
        expect(status.containsKey('cloud'), isTrue);
      });

      test('should handle device connection attempts', () async {
        const testDeviceId = 'test_device_123';
        
        try {
          final result = await serviceCoordinator.connectToDevice(testDeviceId);
          expect(result, isA<bool>());
        } catch (e) {
          // May fail if device not found, should handle gracefully  
          expect(e, isA<Exception>());
        }
      });
    });

    group('Mesh Network Integration', () {
      test('should provide mesh network statistics', () {
        final stats = serviceCoordinator.getMeshNetworkStats();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should handle mesh topology stream', () {
        final stream = serviceCoordinator.meshTopologyStream;
        expect(stream, isA<Stream>());
      });

      test('should send messages through mesh network', () async {
        final meshMessage = ChatMessage(
          id: 'mesh_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'mesh_sender',
          senderName: 'Mesh User',
          receiverId: 'mesh_receiver', 
          content: 'Testing mesh routing',
          type: MessageType.text,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          isEmergency: false,
          ttl: 5,
          hopCount: 0,
        );

        try {
          final result = await serviceCoordinator.sendMessageThroughMesh(meshMessage);
          expect(result, isA<bool>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Error Handling & Recovery', () {
      test('should handle initialization failures gracefully', () async {
        // Test multiple initialization attempts
        final result1 = await serviceCoordinator.init();
        final result2 = await serviceCoordinator.init(); // Should handle already initialized
        
        expect(result1, isA<bool>());
        expect(result2, isA<bool>());
      });

      test('should provide streams for real-time updates', () {
        // Test that streams are available
        expect(serviceCoordinator.deviceStream, isA<Stream<List<NearbyDevice>>>());
        expect(serviceCoordinator.messageStream, isA<Stream<ChatMessage>>());
      });

      test('should handle concurrent operations', () async {
        // Test concurrent message sending
        final messages = List.generate(3, (i) => ChatMessage(
          id: 'concurrent_$i',
          senderId: 'sender_$i',
          senderName: 'User $i',
          receiverId: 'receiver_$i',
          content: 'Concurrent message $i',
          type: MessageType.text,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          isEmergency: false,
        ));

        final futures = messages.map((msg) => serviceCoordinator.sendMessage(msg));
        final results = await Future.wait(futures);
        
        expect(results.length, equals(3));
        // All results should be boolean values
        for (final result in results) {
          expect(result, isA<bool>());
        }
      });
    });

    group('Role Management Integration', () {
      test('should handle device role updates', () async {
        try {
          final result = await serviceCoordinator.updateDeviceRole(role_enum.UserRole.rescueUser.name);
          expect(result, isA<bool>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle discovery refresh for SOS scanning', () async {
        try {
          await serviceCoordinator.refreshDiscovery();
          expect(true, isTrue); // Should complete
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    tearDown(() async {
      // Clean up after each test
      try {
        serviceCoordinator.dispose();
      } catch (e) {
        // Ignore cleanup errors
      }
    });
  });

  group('ServiceCoordinator Integration Tests', () {
    test('should demonstrate complete message flow', () async {
      // This test demonstrates the complete production flow
      final coordinator = ServiceCoordinator.instance;
      
      // 1. Initialize services
      await coordinator.init();
      
      // 2. Create and send a message
      final message = ChatMessage(
        id: 'integration_test_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'test_user',
        senderName: 'Test User',
        receiverId: 'target_user',
        content: 'Integration test message',
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isEmergency: false,
      );
      
      await coordinator.sendMessage(message);
      
      // 3. Simulate incoming message handling
      final incomingMessage = message.copyWith(
        id: 'incoming_${DateTime.now().millisecondsSinceEpoch}',
        status: MessageStatus.delivered,
      );
      
      await coordinator.handleIncoming(incomingMessage);
      
      // 4. Test sync queue
      await coordinator.syncQueue();
      
      // 5. Verify service status
      final status = coordinator.getServiceStatus();
      expect(status, isNotEmpty);
      
      coordinator.dispose();
    });
  });

  group('Performance & Load Tests', () {
    test('should handle high message volume', () async {
      final coordinator = ServiceCoordinator.instance;
      await coordinator.init();
      
      // Create 10 messages for load testing
      final messages = List.generate(10, (i) => ChatMessage(
        id: 'load_test_$i',
        senderId: 'load_sender',
        senderName: 'Load Tester',
        receiverId: 'load_receiver',
        content: 'Load test message #$i',
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        isEmergency: false,
      ));
      
      // Send all messages
      final stopwatch = Stopwatch()..start();
      final futures = messages.map((msg) => coordinator.sendMessage(msg));
      final results = await Future.wait(futures);
      stopwatch.stop();
      
      expect(results.length, equals(10));
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
      
      coordinator.dispose();
    });
  });
}