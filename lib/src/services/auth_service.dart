import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'service_coordinator.dart';
import 'firebase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  
  AuthService._internal();

  UserModel? _currentUser;
  
  final StreamController<UserModel?> _userStreamController = 
      StreamController<UserModel?>.broadcast();
  
  Stream<UserModel?> get userStream => _userStreamController.stream;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Initialize auth service and restore saved user
  Future<void> initialize() async {
    await _restoreUser();
  }

  /// Restore user from local storage
  Future<void> _restoreUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _currentUser = UserModel(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          phone: userData['phone'],
          profileImageUrl: userData['profileImageUrl'],
          role: userData['role'] ?? 'normal',
          lastSeen: userData['lastSeen'] != null 
              ? DateTime.parse(userData['lastSeen'])
              : null,
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : null,
          updatedAt: DateTime.now(),
          isSyncedToCloud: userData['isSyncedToCloud'] ?? false,
        );
      }
      
      // Always emit the current state (null if no user exists)
      _userStreamController.add(_currentUser);
    } catch (e) {
      Logger.error('Error restoring user: $e');
      // Emit null state even on error
      _userStreamController.add(null);
    }
  }

  /// Sign up new user (offline-first)
  Future<UserModel?> signUp({
    required String name,
    required String email,
    String? phone,
    String? role,
  }) async {
    try {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
        role: role ?? 'normal', // Store the role
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: true,
        isSyncedToCloud: false, // Will sync when internet available
      );

      // Save to local storage
      await _saveUserLocally(user);
      
      // Set as current user
      _currentUser = user;
      _userStreamController.add(_currentUser);

      return user;
    } catch (e) {
      Logger.error('Error during signup: $e');
      return null;
    }
  }

  /// Sign in user (offline-first, check local storage)
  Future<UserModel?> signIn({
    required String email,
  }) async {
    try {
      // For now, simple local auth
      // In production, you'd validate against local database
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_$email');
      
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        final user = UserModel(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          phone: userData['phone'],
          profileImageUrl: userData['profileImageUrl'],
          role: userData['role'] ?? 'normal',
          lastSeen: DateTime.now(),
          createdAt: userData['createdAt'] != null
              ? DateTime.parse(userData['createdAt'])
              : null,
          updatedAt: DateTime.now(),
          isOnline: true,
          isSyncedToCloud: userData['isSyncedToCloud'] ?? false,
        );

        _currentUser = user;
        await _saveUserLocally(user);
        _userStreamController.add(_currentUser);
        
        return user;
      }
      
      return null;
    } catch (e) {
      Logger.error('Error during signin: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? role,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = UserModel(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: _currentUser!.email,
        phone: phone ?? _currentUser!.phone,
        profileImageUrl: _currentUser!.profileImageUrl,
        role: role ?? _currentUser!.role,
        lastSeen: _currentUser!.lastSeen,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
        isOnline: _currentUser!.isOnline,
        isSyncedToCloud: false, // Mark for sync
      );

      await _saveUserLocally(updatedUser);
      _currentUser = updatedUser;
      _userStreamController.add(_currentUser);
      
      return true;
    } catch (e) {
      Logger.error('Error updating profile: $e');
      return false;
    }
  }

  /// Enhanced role change API with comprehensive updates
  Future<bool> changeRole(String newRole, {bool forceCloudSync = true}) async {
    if (_currentUser == null) {
      Logger.error('No current user to update role for', 'auth');
      return false;
    }

    final oldRole = _currentUser!.role;
    Logger.info('Starting role change from $oldRole to $newRole', 'auth');

    try {
      // Step 1: Update using existing updateProfile method
      final success = await updateProfile(role: newRole);
      if (!success) {
        throw Exception('Failed to update profile with new role');
      }
      
      Logger.info('✅ Local user profile updated with new role', 'auth');

      // Step 2: Update ServiceCoordinator and broadcast role change
      await ServiceCoordinator.instance.updateDeviceRole(newRole);
      Logger.info('✅ ServiceCoordinator updated with new role', 'auth');

      // Step 3: Update Firebase cloud document if online and requested
      if (forceCloudSync) {
        await _updateCloudUserDocument(_currentUser!, oldRole);
      }

      // Step 4: Update local database if available
      await _updateLocalDatabase(_currentUser!);

      Logger.success('🎉 Role changed successfully from $oldRole to $newRole', 'auth');
      return true;

    } catch (e) {
      Logger.error('❌ Error changing user role: $e', 'auth');
      
      // Rollback on failure
      await _rollbackRoleChange(oldRole);
      return false;
    }
  }

  /// Legacy method for backward compatibility
  Future<bool> updateRole(String newRole) async {
    return await changeRole(newRole, forceCloudSync: false);
  }

  /// Update Firebase cloud user document
  Future<void> _updateCloudUserDocument(UserModel user, String oldRole) async {
    try {
      // Check if Firebase is available
      if (!FirebaseService.instance.isInitialized) {
        Logger.warning('🔥 Firebase not initialized - skipping cloud update', 'auth');
        return;
      }

      // Check connectivity
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        Logger.warning('📡 Device offline - cloud update will sync later', 'auth');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final firebaseAuth = FirebaseAuth.instance;
      
      // Get or create Firebase user
      User? firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        Logger.info('Creating anonymous Firebase session for cloud sync', 'auth');
        final credential = await firebaseAuth.signInAnonymously();
        firebaseUser = credential.user;
      }

      if (firebaseUser != null) {
        final userDoc = firestore.collection('users').doc(firebaseUser.uid);
        
        // Update user document with role change history
        await userDoc.set({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'profileImageUrl': user.profileImageUrl,
          'role': user.role,
          'lastSeen': user.lastSeen?.toIso8601String(),
          'createdAt': user.createdAt?.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isOnline': true,
          'isSyncedToCloud': true,
          'roleChangeHistory': FieldValue.arrayUnion([{
            'oldRole': oldRole,
            'newRole': user.role,
            'changedAt': DateTime.now().toIso8601String(),
            'deviceInfo': {
              'platform': 'flutter',
              'changeReason': 'user_initiated',
            }
          }]),
          'deviceInfo': {
            'platform': 'flutter',
            'lastSyncTime': DateTime.now().toIso8601String(),
            'lastRoleChange': DateTime.now().toIso8601String(),
          }
        }, SetOptions(merge: true));

        // Mark local user as synced
        final syncedUser = UserModel(
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          profileImageUrl: user.profileImageUrl,
          role: user.role,
          lastSeen: user.lastSeen,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          isOnline: user.isOnline,
          isSyncedToCloud: true,
        );
        
        await _saveUserLocally(syncedUser);
        _currentUser = syncedUser;
        _userStreamController.add(_currentUser);

        Logger.success('📤 Cloud user document updated successfully!', 'auth');
      }
    } catch (e) {
      Logger.error('❌ Failed to update cloud user document: $e (continuing anyway)', 'auth');
      // Don't throw - cloud sync failure shouldn't block role change
    }
  }

  /// Update local SQLite database
  Future<void> _updateLocalDatabase(UserModel user) async {
    try {
      // This would integrate with your local database service
      // For now, we log the intent
      Logger.info('📊 Local database would be updated with new role: ${user.role}', 'auth');
      
      // TODO: Integrate with DatabaseService when available
      // await DatabaseService.instance.updateUserRole(user.id, user.role);
      
    } catch (e) {
      Logger.warning('⚠️ Failed to update local database: $e (continuing anyway)', 'auth');
      // Don't throw - database update failure shouldn't block role change
    }
  }

  /// Rollback role change on failure
  Future<void> _rollbackRoleChange(String originalRole) async {
    try {
      Logger.warning('🔄 Rolling back role change to: $originalRole', 'auth');
      
      if (_currentUser != null) {
        // Use updateProfile to rollback
        await updateProfile(role: originalRole);
        
        // Rollback ServiceCoordinator
        await ServiceCoordinator.instance.updateDeviceRole(originalRole);
        
        Logger.info('✅ Role change rolled back successfully', 'auth');
      }
    } catch (e) {
      Logger.error('❌ Failed to rollback role change: $e', 'auth');
    }
  }

  /// Save user to local storage
  Future<void> _saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userMap = {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'profileImageUrl': user.profileImageUrl,
      'role': user.role,
      'lastSeen': user.lastSeen?.toIso8601String(),
      'createdAt': user.createdAt?.toIso8601String(),
      'updatedAt': user.updatedAt?.toIso8601String(),
      'isOnline': user.isOnline,
      'isSyncedToCloud': user.isSyncedToCloud,
    };
    
    // Save as current user
    await prefs.setString('current_user', jsonEncode(userMap));
    
    // Save with email key for signin
    await prefs.setString('user_${user.email}', jsonEncode(userMap));
  }

  /// Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    
    _currentUser = null;
    _userStreamController.add(null);
  }

  /// Sync user to Firebase cloud when internet available
  Future<void> syncToCloud() async {
    if (_currentUser == null || _currentUser!.isSyncedToCloud) return;

    try {
      // Check if Firebase is initialized
      if (!FirebaseService.instance.isInitialized) {
        Logger.warning('🔥 Firebase not initialized - cannot sync to cloud');
        return;
      }

      // Check internet connectivity
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        Logger.warning('📡 Device offline - cannot sync to cloud');
        return;
      }

      Logger.info('🚀 Starting Firebase cloud sync for user: ${_currentUser!.email}');

      final firebaseAuth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      
      User? firebaseUser = firebaseAuth.currentUser;

      // For now, we'll just sync to Firestore without authentication
      // In a real app, you'd handle Firebase Auth properly
      if (firebaseUser == null) {
        Logger.info('⚠️ No Firebase user authenticated, creating anonymous session');
        // Create anonymous user for demo purposes
        final credential = await firebaseAuth.signInAnonymously();
        firebaseUser = credential.user;
      }

      if (firebaseUser != null) {
        // Sync user data to Firestore
        final userDoc = firestore.collection('users').doc(firebaseUser.uid);
        
        await userDoc.set({
          'id': _currentUser!.id,
          'name': _currentUser!.name,
          'email': _currentUser!.email,
          'phone': _currentUser!.phone,
          'profileImageUrl': _currentUser!.profileImageUrl,
          'role': _currentUser!.role,
          'lastSeen': _currentUser!.lastSeen?.toIso8601String(),
          'createdAt': _currentUser!.createdAt?.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isOnline': true,
          'isSyncedToCloud': true,
          'deviceInfo': {
            'platform': 'flutter',
            'lastSyncTime': DateTime.now().toIso8601String(),
          }
        }, SetOptions(merge: true));

        Logger.success('📤 User data uploaded to Firestore successfully!');
        Logger.info('🆔 Firebase UID: ${firebaseUser.uid}');
      }

      // Update local user as synced
      final updatedUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        profileImageUrl: _currentUser!.profileImageUrl,
        role: _currentUser!.role,
        lastSeen: _currentUser!.lastSeen,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
        isOnline: _currentUser!.isOnline,
        isSyncedToCloud: true,
      );

      await _saveUserLocally(updatedUser);
      _currentUser = updatedUser;
      _userStreamController.add(_currentUser);
      
      Logger.success('✅ User successfully synced to Firebase Cloud!');
      
    } catch (e) {
      Logger.error('❌ Error syncing user to Firebase cloud: $e');
    }
  }

  /// Logout user and clear all data
  Future<void> logout() async {
    try {
      Logger.info('Logging out user: ${_currentUser?.name}', 'auth');
      
      // Clear current user
      _currentUser = null;
      _userStreamController.add(null);
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      
      // Sign out from Firebase if available
      if (await FirebaseService.instance.isAvailable()) {
        try {
          await FirebaseAuth.instance.signOut();
          Logger.info('Signed out from Firebase', 'auth');
        } catch (e) {
          Logger.warning('Firebase signout failed (offline?): $e', 'auth');
        }
      }
      
      Logger.success('User logged out successfully', 'auth');
    } catch (e) {
      Logger.error('Error during logout: $e', 'auth');
      // Still clear local state even if cleanup fails
      _currentUser = null;
      _userStreamController.add(null);
    }
  }

  void dispose() {
    _userStreamController.close();
  }
}