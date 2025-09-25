class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final bool isOnline;
  final String role; // 'normal', 'rescuer', 'sos_user'
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSyncedToCloud;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    this.isOnline = false,
    this.role = 'normal',
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
    this.isSyncedToCloud = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    bool? isOnline,
    String? role,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSyncedToCloud,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnline: isOnline ?? this.isOnline,
      role: role ?? this.role,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSyncedToCloud: isSyncedToCloud ?? this.isSyncedToCloud,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'role': role,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isSyncedToCloud': isSyncedToCloud,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      isOnline: json['isOnline'] ?? false,
      role: json['role'] ?? 'normal',
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isSyncedToCloud: json['isSyncedToCloud'] ?? false,
    );
  }
}

enum UserRole {
  normal,
  rescuer,
  sosUser,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.normal:
        return 'ผู้ใช้ทั่วไป';
      case UserRole.rescuer:
        return 'หน่วยกู้ภัย';
      case UserRole.sosUser:
        return 'ผู้ขอความช่วยเหลือ';
    }
  }
  
  String get value {
    switch (this) {
      case UserRole.normal:
        return 'normal';
      case UserRole.rescuer:
        return 'rescuer';
      case UserRole.sosUser:
        return 'sos_user';
    }
  }
}