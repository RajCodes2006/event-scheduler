import 'package:flutter/foundation.dart';

import '../data/event_database.dart';
import '../models/schedule_event.dart';
import '../services/notification_service.dart';

class EventController extends ChangeNotifier {
  final EventDatabase _database = EventDatabase.instance;

  List<ScheduleEvent> _events = const [];
  Map<DateTime, List<ScheduleEvent>> _eventsByDay = const {};
  bool _isLoading = true;
  bool _isDarkMode = false;
  String? _errorMessage;

  List<ScheduleEvent> get events => _events;
  Map<DateTime, List<ScheduleEvent>> get eventsByDay => _eventsByDay;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String? get errorMessage => _errorMessage;

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    var loadedSuccessfully = false;
    notifyListeners();

    try {
      final darkMode = await _database.getDarkModeEnabled();
      _replaceEvents(await _database.getAllEvents());
      _isDarkMode = darkMode;
      loadedSuccessfully = true;
    } catch (error) {
      _errorMessage = 'Could not load events. Please restart the app.';
      debugPrint('loadEvents error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (loadedSuccessfully) {
      await NotificationService.instance.syncReminders(_events);
    }
  }

  Future<void> toggleDarkMode() async {
    final previous = _isDarkMode;
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      await _database.setDarkModeEnabled(_isDarkMode);
    } catch (error) {
      _isDarkMode = previous;
      notifyListeners();
      debugPrint('Could not save Daymark appearance setting: $error');
    }
  }

  void _replaceEvents(Iterable<ScheduleEvent> events) {
    final sorted = List<ScheduleEvent>.of(events)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    _events = List<ScheduleEvent>.unmodifiable(sorted);

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
    return _events
        .where((event) => event.endAt.isAfter(now))
        .toList(growable: false);
  }

  List<ScheduleEvent> eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventsByDay[key] ?? const <ScheduleEvent>[];
  }

  Future<void> saveEvent(ScheduleEvent event) async {
    if (event.id == null && event.recurrenceFrequency != 'none') {
      final until = event.recurrenceUntil;
      final startDay = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
      if (until == null) {
        throw ArgumentError('Choose a repeat-until date on or after the event date.');
      }
      final untilDay = DateTime(until.year, until.month, until.day);
      if (untilDay.isBefore(startDay)) {
        throw ArgumentError('Choose a repeat-until date on or after the event date.');
      }
      final seriesId = DateTime.now().microsecondsSinceEpoch.toString();
      final occurrences = event.generateOccurrences(
        seriesId: seriesId,
        until: until,
      );
      final inserted = await _database.insertEvents(occurrences);
      _replaceEvents([..._events, ...inserted]);
      _errorMessage = null;
      notifyListeners();
      for (final occurrence in inserted) {
        await NotificationService.instance.scheduleReminder(occurrence);
      }
      return;
    }

    final ScheduleEvent savedEvent;
    if (event.id == null) {
      final id = await _database.insertEvent(event);
      savedEvent = event.copyWith(id: id);
      _replaceEvents([..._events, savedEvent]);
    } else {
      await _database.updateEvent(event);
      savedEvent = event;
      _replaceEvents(_events.where((existing) => existing.id != event.id).followedBy([savedEvent]));
    }

    _errorMessage = null;
    notifyListeners();
    await NotificationService.instance.scheduleReminder(savedEvent);
  }

  Future<void> deleteEvent(int id, {bool entireSeries = false}) async {
    ScheduleEvent? selected;
    for (final event in _events) {
      if (event.id == id) {
        selected = event;
        break;
      }
    }
    if (selected == null) return;
    final selectedEvent = selected;

    if (entireSeries && selectedEvent.recurrenceSeriesId != null) {
      final series = _events
          .where((event) => event.recurrenceSeriesId == selectedEvent.recurrenceSeriesId)
          .toList(growable: false);
      await _database.deleteSeries(selectedEvent.recurrenceSeriesId!);
      final ids = series.map((event) => event.id).whereType<int>().toSet();
      _replaceEvents(_events.where((event) => !ids.contains(event.id)));
      _errorMessage = null;
      notifyListeners();
      for (final eventId in ids) {
        await NotificationService.instance.cancelReminder(eventId);
      }
      return;
    }

    await _database.deleteEvent(id);
    _replaceEvents(_events.where((event) => event.id != id));
    _errorMessage = null;
    notifyListeners();
    await NotificationService.instance.cancelReminder(id);
  }
}
