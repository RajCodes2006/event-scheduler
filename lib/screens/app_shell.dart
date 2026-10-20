import 'package:flutter/material.dart';

import '../models/schedule_event.dart';
import 'calendar_screen.dart';
import 'event_form_screen.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  Future<void> _openEventForm([ScheduleEvent? event]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EventFormScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(onAddEvent: () => _openEventForm(), onEditEvent: _openEventForm),
          CalendarScreen(onAddEvent: () => _openEventForm(), onEditEvent: _openEventForm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEventForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add event'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
