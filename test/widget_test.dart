import 'package:flutter_test/flutter_test.dart';
import 'package:event_scheduler/models/schedule_event.dart';

void main() {
  group('ScheduleEvent', () {
    test('serializes and restores all event fields', () {
      final event = ScheduleEvent(
        id: 12,
        title: 'Project review',
        description: 'Bring the notes',
        location: 'Library',
        category: 'Study',
        startAt: DateTime(2026, 10, 21, 14, 30),
        endAt: DateTime(2026, 10, 21, 15, 30),
        reminderMinutesBefore: 30,
        recurrenceSeriesId: 'series-123',
        recurrenceFrequency: 'weekly',
        recurrenceUntil: DateTime(2026, 12, 1),
      );

      final restored = ScheduleEvent.fromMap(event.toMap());

      expect(restored.id, event.id);
      expect(restored.title, event.title);
      expect(restored.description, event.description);
      expect(restored.location, event.location);
      expect(restored.category, event.category);
      expect(restored.startAt, event.startAt);
      expect(restored.endAt, event.endAt);
      expect(restored.reminderMinutesBefore, 30);
      expect(restored.recurrenceSeriesId, 'series-123');
      expect(restored.recurrenceFrequency, 'weekly');
      expect(restored.recurrenceUntil, DateTime(2026, 12, 1));
      expect(restored.isRecurring, isTrue);
    });

    test('uses sensible defaults for legacy event rows', () {
      final event = ScheduleEvent.fromMap({
        'id': 1,
        'title': 'Quick task',
        'start_at': DateTime(2026, 10, 21, 9).toIso8601String(),
        'end_at': DateTime(2026, 10, 21, 10).toIso8601String(),
      });

      expect(event.description, '');
      expect(event.location, '');
      expect(event.category, 'Personal');
      expect(event.reminderMinutesBefore, 15);
      expect(event.recurrenceFrequency, 'none');
      expect(event.recurrenceSeriesId, isNull);
      expect(event.recurrenceUntil, isNull);
      expect(event.isRecurring, isFalse);
    });

    test('generates daily occurrences inclusively through repeat-until date', () {
      final event = ScheduleEvent(
        title: 'Morning run',
        description: '',
        location: 'Park',
        category: 'Health',
        startAt: DateTime(2026, 10, 21, 7),
        endAt: DateTime(2026, 10, 21, 8),
        reminderMinutesBefore: 15,
        recurrenceFrequency: 'daily',
        recurrenceUntil: DateTime(2026, 10, 23),
      );

      final occurrences = event.generateOccurrences(
        seriesId: 'daily-run',
        until: DateTime(2026, 10, 23),
      );

      expect(occurrences, hasLength(3));
      expect(occurrences.map((e) => e.startAt.day), [21, 22, 23]);
      expect(occurrences.every((e) => e.recurrenceSeriesId == 'daily-run'), isTrue);
      expect(occurrences.every((e) => e.endAt.difference(e.startAt) == const Duration(hours: 1)), isTrue);
    });

    test('monthly recurrence clamps to the last valid day of short months', () {
      final event = ScheduleEvent(
        title: 'Monthly review',
        description: '',
        location: '',
        category: 'Work',
        startAt: DateTime(2026, 1, 31, 9),
        endAt: DateTime(2026, 1, 31, 10),
        recurrenceFrequency: 'monthly',
      );

      final occurrences = event.generateOccurrences(
        seriesId: 'month-review',
        until: DateTime(2026, 3, 31),
      );

      expect(occurrences.map((e) => e.startAt.month), [1, 2, 3]);
      expect(occurrences.map((e) => e.startAt.day), [31, 28, 28]);
    });
  });
}
