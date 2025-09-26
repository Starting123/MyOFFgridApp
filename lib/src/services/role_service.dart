import '../models/user_role.dart';

class RoleService {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  UserRole? _currentUserRole;
  String? _currentUserId;

  // Get current user role
  UserRole? get currentRole => _currentUserRole;
  String? get currentUserId => _currentUserId;

  // Set user role
  void setUserRole(UserRole role, String userId) {
    _currentUserRole = role;
    _currentUserId = userId;
  }

  // Check if user can perform SOS operations
  bool canPerformSOS() {
    return _currentUserRole == UserRole.sosUser;
  }

  // Check if user can perform rescue operations
  bool canPerformRescue() {
    return _currentUserRole == UserRole.rescueUser;
  }

  // Check if user can act as relay
  bool canActAsRelay() {
    return _currentUserRole == UserRole.relayUser;
  }

  // Get role-specific capabilities
  List<String> getRoleCapabilities() {
    switch (_currentUserRole) {
      case UserRole.sosUser:
        return ['Send SOS signals', 'Request help', 'Share location'];
      case UserRole.rescueUser:
        return ['Receive SOS signals', 'Provide assistance', 'Navigate to victims'];
      case UserRole.relayUser:
        return ['Forward messages', 'Extend network range', 'Bridge communications'];
      default:
        return [];
    }
  }

  // Clear current role (logout)
  void clearRole() {
    _currentUserRole = null;
    _currentUserId = null;
  }
}