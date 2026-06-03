import 'dart:convert';

class OrganizationModel {
  final String id;
  final String name;
  final String campusName;
  final String code;
  final String description;
  final String ownerId;
  final DateTime createdAt;
  final Map<String, List<String>> featurePermissions;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.campusName,
    required this.code,
    required this.description,
    required this.ownerId,
    required this.createdAt,
    this.featurePermissions = const {},
  });

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? campusName,
    String? code,
    String? description,
    String? ownerId,
    DateTime? createdAt,
    Map<String, List<String>>? featurePermissions,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      campusName: campusName ?? this.campusName,
      code: code ?? this.code,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      featurePermissions: featurePermissions ?? this.featurePermissions,
    );
  }

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      campusName: json['campusName'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      featurePermissions: json['featurePermissions'] != null
          ? Map<String, List<String>>.from(
              (json['featurePermissions'] as Map).map(
                (key, value) => MapEntry(key as String, List<String>.from(value)),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'campusName': campusName,
      'code': code,
      'description': description,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'featurePermissions': featurePermissions,
    };
  }

  @override
  String toString() => json.encode(toJson());
}
