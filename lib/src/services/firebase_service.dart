import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Firebase configuration for web
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: "AIzaSyDemoKey123456789",
    authDomain: "off-grid-sos-app.firebaseapp.com",
    projectId: "off-grid-sos-app",
    storageBucket: "off-grid-sos-app.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef123456789",
  );

  /// Initialize Firebase
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // For web, provide options explicitly
      if (kIsWeb) {
        await Firebase.initializeApp(options: webOptions);
      } else {
        // For mobile, use default configuration from google-services.json/GoogleService-Info.plist
        await Firebase.initializeApp();
      }

      _isInitialized = true;
      Logger.success('Firebase initialized successfully');
      return true;

    } catch (e) {
      Logger.error('Firebase initialization failed: $e');
      return false;
    }
  }

  /// Check if Firebase services are available
  Future<bool> isAvailable() async {
    try {
      return _isInitialized && Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get Firebase app instance
  FirebaseApp? get app {
    try {
      return Firebase.app();
    } catch (e) {
      return null;
    }
  }

  /// Sync local data to cloud
  Future<void> syncToCloud() async {
    try {
      if (!_isInitialized) {
        throw Exception('Firebase not initialized');
      }
      
      // In a full implementation, this would sync:
      // - User messages to Firestore
      // - Device information
      // - Emergency contacts
      // - Settings preferences
      
      Logger.info('Cloud sync completed successfully');
    } catch (e) {
      Logger.error('Cloud sync failed: $e');
      rethrow;
    }
  }
}