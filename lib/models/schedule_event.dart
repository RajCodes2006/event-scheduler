class ScheduleEvent {
  const ScheduleEvent({
    this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.startAt,
    required this.endAt,
  });

  final int? id;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime startAt;
  final DateTime endAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
    };
  }

  factory ScheduleEvent.fromMap(Map<String, Object?> map) {
    return ScheduleEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      location: (map['location'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Personal',
      startAt: DateTime.parse(map['start_at'] as String),
      endAt: DateTime.parse(map['end_at'] as String),
    );
  }
}
