import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? nim;
  final String? campusName;
  final String? activeOrganizationId;
  final String? passwordHash;
  final String? profileImagePath;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.campusName,
    this.activeOrganizationId,
    this.passwordHash,
    this.profileImagePath,
  });

  bool get isAdmin {
    final lower = role.toLowerCase();
    return lower == 'admin' ||
        lower == 'super_admin' ||
        lower == 'organization_owner' ||
        lower == 'organization_manager' ||
        lower == 'org_manager';
  }

  bool get isSuperAdmin => role.toLowerCase() == 'admin' || role.toLowerCase() == 'super_admin';

  bool get isOrganizationOwner => role.toLowerCase() == 'organization_owner';

  bool get isOrganizationManager {
    final lower = role.toLowerCase();
    return lower == 'organization_manager' || lower == 'org_manager';
  }

  bool get isOrganizationMember =>
      role.toLowerCase() == 'organization_member' ||
      role.toLowerCase() == 'member' ||
      role.toLowerCase() == 'organization_manager' ||
      role.toLowerCase() == 'org_manager';

  bool verifyPassword(String password) {
    if (passwordHash == null || passwordHash!.isEmpty) {
      return false;
    }
    return passwordHash == hashPassword(password);
  }

  static String hashPassword(String password) {
    return base64Encode(utf8.encode(password));
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? nim,
    String? campusName,
    String? activeOrganizationId,
    String? passwordHash,
    String? profileImagePath,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      nim: nim ?? this.nim,
      campusName: campusName ?? this.campusName,
      activeOrganizationId: activeOrganizationId ?? this.activeOrganizationId,
      passwordHash: passwordHash ?? this.passwordHash,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      nim: json['nim'] as String?,
      campusName: json['campusName'] as String?,
      activeOrganizationId: json['activeOrganizationId'] as String?,
      passwordHash: json['passwordHash'] as String?,
      profileImagePath: json['profileImagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'nim': nim,
      'campusName': campusName,
      'activeOrganizationId': activeOrganizationId,
      'passwordHash': passwordHash,
      'profileImagePath': profileImagePath,
    };
  }
}
