import 'dart:convert';

class MembershipModel {
  final String id;
  final String userId;
  final String organizationId;
  final String role;
  final DateTime joinedAt;

  MembershipModel({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.role,
    required this.joinedAt,
  });

  MembershipModel copyWith({
    String? id,
    String? userId,
    String? organizationId,
    String? role,
    DateTime? joinedAt,
  }) {
    return MembershipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      organizationId: json['organizationId'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'organizationId': organizationId,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  @override
  String toString() => json.encode(toJson());
}
