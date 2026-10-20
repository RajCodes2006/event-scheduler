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
    final pages = IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(
          onAddEvent: () => _openEventForm(),
          onEditEvent: _openEventForm,
        ),
        CalendarScreen(
          onAddEvent: () => _openEventForm(),
          onEditEvent: _openEventForm,
        ),
      ],
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Keep bottom navigation on narrow/mobile layouts. Desktop gets a
          // navigation rail and a readable max-width content column.
          if (constraints.maxWidth < 820) return pages;

          final extendedRail = constraints.maxWidth >= 1180;
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                extended: extendedRail,
                labelType:
                    extendedRail ? null : NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.only(top: 18, bottom: 18),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF5B5CE2),
                    size: 28,
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.grid_view_rounded),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: Text('Today'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_rounded),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: Text('Calendar'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: pages,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEventForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add event'),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 820
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
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
            )
          : null,
    );
  }
}
