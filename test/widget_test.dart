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
      );

      final restored = ScheduleEvent.fromMap(event.toMap());

      expect(restored.id, event.id);
      expect(restored.title, event.title);
      expect(restored.description, event.description);
      expect(restored.location, event.location);
      expect(restored.category, event.category);
      expect(restored.startAt, event.startAt);
      expect(restored.endAt, event.endAt);
    });

    test('uses sensible defaults for optional stored text fields', () {
      final event = ScheduleEvent.fromMap({
        'id': 1,
        'title': 'Quick task',
        'start_at': DateTime(2026, 10, 21, 9).toIso8601String(),
        'end_at': DateTime(2026, 10, 21, 10).toIso8601String(),
      });

      expect(event.description, '');
      expect(event.location, '');
      expect(event.category, 'Personal');
    });
  });
}
