class AspirationModel {
  final String id;
  final String? organizationId;
  final String name;
  final String message;
  final String date;
  final String status;
  final String reply;

  AspirationModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.message,
    required this.date,
    required this.status,
    required this.reply,
  });

  AspirationModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? message,
    String? date,
    String? status,
    String? reply,
  }) {
    return AspirationModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      message: message ?? this.message,
      date: date ?? this.date,
      status: status ?? this.status,
      reply: reply ?? this.reply,
    );
  }

  factory AspirationModel.fromJson(Map<String, dynamic> json) {
    return AspirationModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String?,
      name: json['name'] as String,
      message: json['message'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      reply: json['reply'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'message': message,
      'date': date,
      'status': status,
      'reply': reply,
    };
  }
}
