import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// User Provider
final userProvider = StreamProvider<UserModel?>((ref) {
  return AuthService.instance.userStream;
});

// Current User Provider (sync)
final currentUserProvider = Provider<UserModel?>((ref) {
  return AuthService.instance.currentUser;
});

// Is Logged In Provider
final isLoggedInProvider = Provider<bool>((ref) {
  return AuthService.instance.isLoggedIn;
});

// User Role Provider  
final userRoleProvider = Provider<String>((ref) {
  final user = AuthService.instance.currentUser;
  return user?.role ?? 'normal';
});

// Auth Actions Provider
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions();
});

class AuthActions {
  Future<UserModel?> signUp({
    required String name,
    required String email,
    String? phone,
    String? role,
  }) async {
    return await AuthService.instance.signUp(
      name: name,
      email: email,
      phone: phone,
      role: role,
    );
  }

  Future<UserModel?> signIn({
    required String email,
  }) async {
    return await AuthService.instance.signIn(email: email);
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? role,
  }) async {
    return await AuthService.instance.updateProfile(
      name: name,
      phone: phone,
      role: role,
    );
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
  }

  Future<void> syncToCloud() async {
    await AuthService.instance.syncToCloud();
  }
}