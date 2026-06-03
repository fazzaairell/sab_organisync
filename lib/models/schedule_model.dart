class ScheduleModel {
  final String id;
  final String? organizationId;
  final String title;
  final String date;
  final String time;
  final String location;
  final String category;
  final int color;

  ScheduleModel({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    required this.color,
  });

  ScheduleModel copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? date,
    String? time,
    String? location,
    String? category,
    int? color,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      category: category ?? this.category,
      color: color ?? this.color,
    );
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String?,
      title: json['title'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      color: json['color'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'category': category,
      'color': color,
    };
  }
}
