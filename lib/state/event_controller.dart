import 'package:flutter/foundation.dart';

import '../data/event_database.dart';
import '../models/schedule_event.dart';

class EventController extends ChangeNotifier {
  final EventDatabase _database = EventDatabase.instance;

  List<ScheduleEvent> _events = const [];
  Map<DateTime, List<ScheduleEvent>> _eventsByDay = const {};
  bool _isLoading = true;
  String? _errorMessage;

  // The list is replaced, never mutated, so callers can safely reuse it.
  List<ScheduleEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _replaceEvents(await _database.getAllEvents());
    } catch (error) {
      _errorMessage = 'Could not load events. Please restart the app.';
      debugPrint('loadEvents error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _replaceEvents(Iterable<ScheduleEvent> events) {
    final sorted = List<ScheduleEvent>.of(events)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    _events = List<ScheduleEvent>.unmodifiable(sorted);

    // TableCalendar asks for event data for each visible date. Index once
    // after data changes instead of filtering and sorting the entire list
    // for every calendar cell.
    final grouped = <DateTime, List<ScheduleEvent>>{};
    for (final event in sorted) {
      final day = DateTime(
        event.startAt.year,
        event.startAt.month,
        event.startAt.day,
      );
      (grouped[day] ??= <ScheduleEvent>[]).add(event);
    }

    _eventsByDay = Map<DateTime, List<ScheduleEvent>>.unmodifiable({
      for (final entry in grouped.entries)
        entry.key: List<ScheduleEvent>.unmodifiable(entry.value),
    });
  }

  List<ScheduleEvent> get upcomingEvents {
    final now = DateTime.now();
    // _events is already sorted by start time, so no second sort is needed.
    return _events
        .where((event) => event.endAt.isAfter(now))
        .toList(growable: false);
  }

  List<ScheduleEvent> eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventsByDay[key] ?? const <ScheduleEvent>[];
  }

  Future<void> saveEvent(ScheduleEvent event) async {
    if (event.id == null) {
      final id = await _database.insertEvent(event);
      _replaceEvents([
        ..._events,
        ScheduleEvent(
          id: id,
          title: event.title,
          description: event.description,
          location: event.location,
          category: event.category,
          startAt: event.startAt,
          endAt: event.endAt,
        ),
      ]);
    } else {
      await _database.updateEvent(event);
      final updated = _events
          .where((existing) => existing.id != event.id)
          .followedBy([event]);
      _replaceEvents(updated);
    }

    // Don't set isLoading during normal edits. Keeping the screen in place
    // avoids a spinner flash and a second whole-app rebuild after every save.
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteEvent(int id) async {
    await _database.deleteEvent(id);
    _replaceEvents(_events.where((event) => event.id != id));
    _errorMessage = null;
    notifyListeners();
  }
}
