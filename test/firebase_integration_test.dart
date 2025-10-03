import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../lib/src/utils/logger.dart';
import 'dart:typed_data';
import 'dart:convert';

/// Firebase Integration Test Suite
/// Tests end-to-end Firebase connectivity and functionality
void main() {
  group('Firebase Integration Tests', () {
    setUpAll(() async {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      // Initialize Firebase for testing
      await Firebase.initializeApp();
    });

    group('1. Authentication Tests', () {
      test('Firebase Auth initialization', () async {
        expect(FirebaseAuth.instance, isNotNull);
        expect(Firebase.apps.isNotEmpty, true);
      });

      test('Anonymous authentication', () async {
        try {
          final userCredential = await FirebaseAuth.instance.signInAnonymously();
          expect(userCredential.user, isNotNull);
          expect(userCredential.user!.isAnonymous, true);
          
          // Sign out
          await FirebaseAuth.instance.signOut();
          expect(FirebaseAuth.instance.currentUser, isNull);
        } catch (e) {
          fail('Anonymous auth failed: $e');
        }
      });
    });

    group('2. Firestore Database Tests', () {
      late String testUserId;

      setUp(() async {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        testUserId = userCredential.user!.uid;
      });

      tearDown(() async {
        await FirebaseAuth.instance.signOut();
      });

      test('Firestore connection', () async {
        expect(FirebaseFirestore.instance, isNotNull);
      });

      test('Create user document', () async {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(testUserId);
        
        await userDoc.set({
          'name': 'Test User',
          'email': 'test@example.com',
          'createdAt': FieldValue.serverTimestamp(),
          'isOnline': true,
        });

        final snapshot = await userDoc.get();
        expect(snapshot.exists, true);
        expect(snapshot.data()!['name'], 'Test User');
      });

      test('SOS alert creation', () async {
        final sosCollection = FirebaseFirestore.instance.collection('sos_alerts');
        
        final sosDoc = await sosCollection.add({
          'userId': testUserId,
          'userName': 'Test User',
          'message': 'Test emergency message',
          'latitude': 13.7563,
          'longitude': 100.5018,
          'timestamp': FieldValue.serverTimestamp(),
          'isActive': true,
          'emergencyType': 'medical',
        });

        expect(sosDoc.id, isNotEmpty);
        
        final snapshot = await sosDoc.get();
        expect(snapshot.exists, true);
        expect(snapshot.data()!['message'], 'Test emergency message');
      });
    });

    group('3. Cloud Storage Tests', () {
      late String testUserId;

      setUp(() async {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        testUserId = userCredential.user!.uid;
      });

      tearDown(() async {
        await FirebaseAuth.instance.signOut();
      });

      test('Storage connection', () async {
        expect(FirebaseStorage.instance, isNotNull);
      });

      test('File upload and download', () async {
        final storage = FirebaseStorage.instance;
        final ref = storage.ref().child('test/$testUserId/test_file.txt');
        
        final testData = Uint8List.fromList(utf8.encode('Test file content'));
        
        await ref.putData(testData);
        
        final downloadedData = await ref.getData();
        expect(downloadedData, isNotNull);
        expect(utf8.decode(downloadedData!), 'Test file content');
        
        await ref.delete();
      });
    });
  });
}

/// Helper function to run Firebase integration tests
Future<void> runFirebaseTests() async {
  Logger.info('🔥 Starting Firebase Integration Tests...');
  
  try {
    await Firebase.initializeApp();
    Logger.success('✅ Firebase initialized successfully');
    
    // Test Authentication
    Logger.info('🔐 Testing Authentication...');
    final auth = FirebaseAuth.instance;
    final userCredential = await auth.signInAnonymously();
    Logger.success('✅ Anonymous authentication successful: ${userCredential.user?.uid}');
    
    // Test Firestore
    Logger.info('📁 Testing Firestore...');
    final firestore = FirebaseFirestore.instance;
    final testDoc = await firestore.collection('test').add({
      'message': 'Firebase integration test',
      'timestamp': FieldValue.serverTimestamp(),
    });
    Logger.success('✅ Firestore write successful: ${testDoc.id}');
    
    // Test Storage
    Logger.info('💾 Testing Storage...');
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('test/integration_test.txt');
    await ref.putString('Firebase integration test content');
    final downloadURL = await ref.getDownloadURL();
    Logger.success('✅ Storage upload successful: $downloadURL');
    
    // Clean up
    await userCredential.user?.delete();
    await testDoc.delete();
    await ref.delete();
    
    Logger.success('🎉 All Firebase integration tests passed!');
    
  } catch (e) {
    Logger.error('❌ Firebase integration test failed', 'FirebaseTest', e);
    rethrow;
  }
}