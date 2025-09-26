import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

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
  }) async {
    try {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
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

  /// Sync user to cloud when internet available
  Future<void> syncToCloud() async {
    if (_currentUser == null || _currentUser!.isSyncedToCloud) return;

    try {
      // TODO: Implement actual cloud sync
      // For now, just mark as synced
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
      
      Logger.success('User synced to cloud');
    } catch (e) {
      Logger.error('Error syncing user to cloud: $e');
    }
  }

  void dispose() {
    _userStreamController.close();
  }
}