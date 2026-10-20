import 'package:flutter/foundation.dart';

import '../data/event_database.dart';
import '../models/schedule_event.dart';

class EventController extends ChangeNotifier {
  final EventDatabase _database = EventDatabase.instance;

  List<ScheduleEvent> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<ScheduleEvent> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _database.getAllEvents();
      _events.sort((a, b) => a.startAt.compareTo(b.startAt));
    } catch (error) {
      _errorMessage = 'Could not load events. Please restart the app.';
      debugPrint('loadEvents error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ScheduleEvent> get upcomingEvents {
    final now = DateTime.now();
    final results = _events.where((event) => event.endAt.isAfter(now)).toList();
    results.sort((a, b) => a.startAt.compareTo(b.startAt));
    return results;
  }

  List<ScheduleEvent> eventsForDay(DateTime day) {
    final results = _events.where((event) {
      return event.startAt.year == day.year &&
          event.startAt.month == day.month &&
          event.startAt.day == day.day;
    }).toList();
    results.sort((a, b) => a.startAt.compareTo(b.startAt));
    return results;
  }

  Future<void> saveEvent(ScheduleEvent event) async {
    if (event.id == null) {
      await _database.insertEvent(event);
    } else {
      await _database.updateEvent(event);
    }
    await loadEvents();
  }

  Future<void> deleteEvent(int id) async {
    await _database.deleteEvent(id);
    await loadEvents();
  }
}
