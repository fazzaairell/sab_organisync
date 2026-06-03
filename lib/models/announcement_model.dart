class AnnouncementModel {
  final String id;
  final String? organizationId;
  final String title;
  final String content;
  final String date;
  final String category;
  final String? createdBy;

  AnnouncementModel({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.content,
    required this.date,
    required this.category,
    this.createdBy,
  });

  AnnouncementModel copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? content,
    String? date,
    String? category,
    String? createdBy,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      date: json['date'] as String,
      category: json['category'] as String? ?? 'Umum',
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'title': title,
      'content': content,
      'date': date,
      'category': category,
      'createdBy': createdBy,
    };
  }
}
