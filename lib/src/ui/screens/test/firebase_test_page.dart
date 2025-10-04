import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../services/firebase_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/logger.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({Key? key}) : super(key: key);

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  String _status = 'Ready to test Firebase';
  bool _isLoading = false;

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase connection...';
    });

    try {
      // 1. Test Firebase initialization
      await Firebase.initializeApp();
      setState(() {
        _status = '✅ Firebase initialized successfully';
      });
      await Future.delayed(const Duration(seconds: 1));

      // 2. Test FirebaseService
      await FirebaseService.instance.initialize();
      setState(() {
        _status = '✅ FirebaseService initialized';
      });
      await Future.delayed(const Duration(seconds: 1));

      // 3. Test Authentication
      setState(() {
        _status = 'Testing Authentication...';
      });
      
      // Try anonymous sign in
      final user = await FirebaseService.instance.auth.signInAnonymously();
      setState(() {
        _status = '✅ Anonymous authentication successful\nUID: ${user.user?.uid}';
      });
      await Future.delayed(const Duration(seconds: 2));

      // 4. Test Firestore
      setState(() {
        _status = 'Testing Firestore...';
      });
      
      await FirebaseService.instance.firestore
          .collection('test')
          .doc('test_doc')
          .set({
        'message': 'Hello Firebase!',
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'Flutter',
      });
      
      setState(() {
        _status = '✅ Firestore write successful';
      });
      await Future.delayed(const Duration(seconds: 1));

      // 5. Test Firestore read
      final doc = await FirebaseService.instance.firestore
          .collection('test')
          .doc('test_doc')
          .get();
      
      if (doc.exists) {
        setState(() {
          _status = '✅ Firestore read successful\nData: ${doc.data()}';
        });
      }

      Logger.success('🔥 All Firebase tests passed!');
      
    } catch (e) {
      Logger.error('❌ Firebase test failed: $e');
      setState(() {
        _status = '❌ Firebase test failed:\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthService() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing AuthService...';
    });

    try {
      // Test user registration
      await AuthService.instance.signUp(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        phone: '+66812345678',
      );
      
      setState(() {
        _status = '✅ User registration successful';
      });
      await Future.delayed(const Duration(seconds: 1));

      // Test cloud sync
      await AuthService.instance.syncToCloud();
      setState(() {
        _status = '✅ Cloud sync successful';
      });

      Logger.success('🚀 AuthService test passed!');
      
    } catch (e) {
      Logger.error('❌ AuthService test failed: $e');
      setState(() {
        _status = '❌ AuthService test failed:\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase Status:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFirebaseConnection,
              icon: const Icon(Icons.cloud),
              label: const Text('Test Firebase Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAuthService,
              icon: const Icon(Icons.person_add),
              label: const Text('Test Auth Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What should happen:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Firebase connection established'),
                    Text('2. Anonymous authentication successful'),
                    Text('3. Firestore write/read operations work'),
                    Text('4. User registration and cloud sync work'),
                    Text('5. Check Firebase Console for new data'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}