class ScheduleEvent {
  const ScheduleEvent({
    this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.startAt,
    required this.endAt,
    this.reminderMinutesBefore = 15,
    this.recurrenceSeriesId,
    this.recurrenceFrequency = 'none',
    this.recurrenceUntil,
  });

  final int? id;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime startAt;
  final DateTime endAt;
  final int reminderMinutesBefore;

  /// Shared identifier for materialized occurrences in a repeating series.
  final String? recurrenceSeriesId;

  /// One of none, daily, weekly, monthly. Instances are stored as ordinary rows
  /// so calendar views, edits, and local reminders use their own stable IDs.
  final String recurrenceFrequency;

  /// Last day on which an occurrence may start.
  final DateTime? recurrenceUntil;

  bool get isRecurring =>
      recurrenceSeriesId != null && recurrenceFrequency != 'none';

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'reminder_minutes_before': reminderMinutesBefore,
      'recurrence_series_id': recurrenceSeriesId,
      'recurrence_frequency': recurrenceFrequency,
      'recurrence_until': recurrenceUntil?.toIso8601String(),
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
      reminderMinutesBefore: (map['reminder_minutes_before'] as int?) ?? 15,
      recurrenceSeriesId: map['recurrence_series_id'] as String?,
      recurrenceFrequency: (map['recurrence_frequency'] as String?) ?? 'none',
      recurrenceUntil: map['recurrence_until'] == null
          ? null
          : DateTime.tryParse(map['recurrence_until'] as String),
    );
  }

  ScheduleEvent copyWith({
    int? id,
    String? title,
    String? description,
    String? location,
    String? category,
    DateTime? startAt,
    DateTime? endAt,
    int? reminderMinutesBefore,
    String? recurrenceSeriesId,
    String? recurrenceFrequency,
    DateTime? recurrenceUntil,
  }) {
    return ScheduleEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      recurrenceSeriesId: recurrenceSeriesId ?? this.recurrenceSeriesId,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceUntil: recurrenceUntil ?? this.recurrenceUntil,
    );
  }

  /// Builds concrete occurrences through [until], inclusive. Materializing the
  /// rows means every recurrence can keep its own SQLite ID and notification.
  List<ScheduleEvent> generateOccurrences({
    required String seriesId,
    required DateTime until,
    int maxOccurrences = 366,
  }) {
    if (recurrenceFrequency == 'none') return [this];

    final duration = endAt.difference(startAt);
    final limit = DateTime(until.year, until.month, until.day, 23, 59, 59);
    final occurrences = <ScheduleEvent>[];
    var occurrenceStart = startAt;

    while (!occurrenceStart.isAfter(limit) &&
        occurrences.length < maxOccurrences) {
      occurrences.add(copyWith(
        id: null,
        startAt: occurrenceStart,
        endAt: occurrenceStart.add(duration),
        recurrenceSeriesId: seriesId,
        recurrenceFrequency: recurrenceFrequency,
        recurrenceUntil: until,
      ));

      switch (recurrenceFrequency) {
        case 'daily':
          occurrenceStart = occurrenceStart.add(const Duration(days: 1));
          break;
        case 'weekly':
          occurrenceStart = occurrenceStart.add(const Duration(days: 7));
          break;
        case 'monthly':
          occurrenceStart = _sameDayNextMonth(occurrenceStart, startAt.day);
          break;
        default:
          return [this];
      }
    }
    return occurrences;
  }

  static DateTime _sameDayNextMonth(DateTime value, int targetDay) {
    final first = DateTime(
      value.year,
      value.month + 1,
      1,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    final day = targetDay < lastDay ? targetDay : lastDay;
    return DateTime(
      first.year,
      first.month,
      day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }
}
