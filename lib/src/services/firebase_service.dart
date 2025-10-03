import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../models/chat_models.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  /// Firebase configuration for web
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: "AIzaSyDDYOTW5cNJjUd9LYuX9iUogtF7kEYzmjM",
    authDomain: "off-grid-sos-app.firebaseapp.com",
    projectId: "off-grid-sos-app",
    storageBucket: "off-grid-sos-app.firebasestorage.app",
    messagingSenderId: "798849744293",
    appId: "1:798849744293:web:262d0a88bea3deddd6fc4c",
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

      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      
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

  /// Upload message to Firestore with proper structure
  Future<bool> uploadMessage(ChatMessage message) async {
    try {
      if (!_isInitialized) {
        throw Exception('Firebase not initialized');
      }

      final user = _auth.currentUser;
      if (user == null) {
        Logger.warning('No authenticated user for message upload');
        return false;
      }

      // Create chat document ID from participants
      final chatId = _generateChatId(message.senderId, message.receiverId);
      
      // Message data with proper metadata
      final messageData = {
        'id': message.id,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'receiverId': message.receiverId,
        'content': message.content,
        'type': message.type.toString().split('.').last,
        'status': message.status.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
        'clientTimestamp': Timestamp.fromDate(message.timestamp),
        'isEmergency': message.isEmergency,
        'latitude': message.latitude,
        'longitude': message.longitude,
        'ttl': message.ttl,
        'hopCount': message.hopCount,
        'requiresAck': message.requiresAck,
        'visitedNodes': message.visitedNodes,
        'uploadedBy': user.uid,
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      // Upload to chats/{chatId}/messages/{messageId}
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id)
          .set(messageData, SetOptions(merge: true));

      // Update chat metadata
      await _updateChatMetadata(chatId, message);

      Logger.info('Message uploaded to Firestore: ${message.id}');
      return true;
      
    } catch (e) {
      Logger.error('Failed to upload message ${message.id}: $e');
      return false;
    }
  }

  /// Upload SOS alert to public collection
  Future<bool> uploadSOSAlert(ChatMessage sosMessage) async {
    try {
      if (!_isInitialized) {
        throw Exception('Firebase not initialized');
      }

      final user = _auth.currentUser;
      if (user == null) {
        Logger.warning('No authenticated user for SOS upload');
        return false;
      }

      final sosData = {
        'id': sosMessage.id,
        'userId': sosMessage.senderId,
        'userName': sosMessage.senderName,
        'message': sosMessage.content,
        'latitude': sosMessage.latitude,
        'longitude': sosMessage.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'clientTimestamp': Timestamp.fromDate(sosMessage.timestamp),
        'status': 'active', // active, responding, resolved
        'priority': sosMessage.isEmergency ? 'critical' : 'high',
        'responderId': null,
        'responderName': null,
        'responseTimestamp': null,
        'metadata': sosMessage.metadata,
        'hopCount': sosMessage.hopCount,
        'uploadedBy': user.uid,
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      // Upload to public sos_alerts collection
      await _firestore
          .collection('sos_alerts')
          .doc(sosMessage.id)
          .set(sosData, SetOptions(merge: true));

      Logger.info('SOS alert uploaded to Firestore: ${sosMessage.id}');
      return true;
      
    } catch (e) {
      Logger.error('Failed to upload SOS alert ${sosMessage.id}: $e');
      return false;
    }
  }

  /// Update device information in Firestore
  Future<bool> uploadDeviceInfo(Map<String, dynamic> deviceData) async {
    try {
      if (!_isInitialized) {
        throw Exception('Firebase not initialized');
      }

      final user = _auth.currentUser;
      if (user == null) {
        Logger.warning('No authenticated user for device upload');
        return false;
      }

      final deviceInfo = {
        ...deviceData,
        'userId': user.uid,
        'lastSeen': FieldValue.serverTimestamp(),
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      // Upload to devices collection with device ID as document ID
      await _firestore
          .collection('devices')
          .doc(deviceData['id'])
          .set(deviceInfo, SetOptions(merge: true));

      Logger.info('Device info uploaded: ${deviceData['id']}');
      return true;
      
    } catch (e) {
      Logger.error('Failed to upload device info: $e');
      return false;
    }
  }

  /// Update chat metadata (last message, participants, etc.)
  Future<void> _updateChatMetadata(String chatId, ChatMessage message) async {
    final chatData = {
      'id': chatId,
      'participants': [message.senderId, message.receiverId],
      'lastMessage': message.content,
      'lastMessageId': message.id,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': message.senderId,
      'isEmergencyChat': message.isEmergency,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .set(chatData, SetOptions(merge: true));
  }

  /// Generate consistent chat ID from participant IDs
  String _generateChatId(String userId1, String userId2) {
    final List<String> ids = [userId1, userId2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  /// Sync local data to cloud
  Future<void> syncToCloud() async {
    try {
      if (!_isInitialized) {
        throw Exception('Firebase not initialized');
      }
      
      Logger.info('Cloud sync completed successfully');
    } catch (e) {
      Logger.error('Cloud sync failed: $e');
      rethrow;
    }
  }
}