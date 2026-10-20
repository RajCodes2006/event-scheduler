import 'package:flutter/material.dart';

import '../models/schedule_event.dart';
import 'calendar_screen.dart';
import 'event_form_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  Future<void> _openEventForm([ScheduleEvent? event]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => EventFormScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(onAddEvent: () => _openEventForm(), onEditEvent: _openEventForm),
        CalendarScreen(onAddEvent: () => _openEventForm(), onEditEvent: _openEventForm),
        SearchScreen(onEditEvent: _openEventForm),
      ],
    );

    const destinations = [
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
      NavigationDestination(
        icon: Icon(Icons.search_rounded),
        selectedIcon: Icon(Icons.search_rounded),
        label: 'Search',
      ),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 820) return pages;
          final extendedRail = constraints.maxWidth >= 1180;
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                extended: extendedRail,
                labelType: extendedRail ? null : NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 22),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 27,
                    ),
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
                  NavigationRailDestination(
                    icon: Icon(Icons.search_rounded),
                    selectedIcon: Icon(Icons.search_rounded),
                    label: Text('Search'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
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
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: destinations,
            )
          : null,
    );
  }
}
