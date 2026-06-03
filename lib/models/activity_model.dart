class ActivityModel {
  final String id;
  final String? organizationId;
  final String title;
  final String date;
  final String description;
  final int participants;
  final String emoji;
  final String? imagePath;

  ActivityModel({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.date,
    required this.description,
    required this.participants,
    required this.emoji,
    this.imagePath,
  });

  ActivityModel copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? date,
    String? description,
    int? participants,
    String? emoji,
    String? imagePath,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      emoji: emoji ?? this.emoji,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String?,
      title: json['title'] as String,
      date: json['date'] as String,
      description: json['description'] as String,
      participants: json['participants'] as int,
      emoji: json['emoji'] as String,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'title': title,
      'date': date,
      'description': description,
      'participants': participants,
      'emoji': emoji,
      'imagePath': imagePath,
    };
  }
}
