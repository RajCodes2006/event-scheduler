import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/schedule_event.dart';
import '../state/event_controller.dart';
import '../widgets/event_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.onAddEvent,
    required this.onEditEvent,
  });

  final VoidCallback onAddEvent;
  final ValueChanged<ScheduleEvent> onEditEvent;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final events = context.select<EventController, List<ScheduleEvent>>(
      (controller) => controller.events,
    );
    final isLoading = context.select<EventController, bool>(
      (controller) => controller.isLoading,
    );
    final errorMessage = context.select<EventController, String?>(
      (controller) => controller.errorMessage,
    );
    final controller = context.read<EventController>();
    final scheme = Theme.of(context).colorScheme;
    final selectedEvents = controller.eventsForDay(_selectedDay);

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey<String>('daymark-calendar-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Your calendar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'See what is planned and what is free.',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: TableCalendar<ScheduleEvent>(
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime(2050, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: controller.eventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarFormat: CalendarFormat.month,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      leftChevronIcon: Icon(Icons.chevron_left_rounded),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded),
                      titleTextStyle: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      markersMaxCount: 3,
                      markerDecoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                      weekendTextStyle: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  DateFormat('EEEE, d MMMM').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedEvents.isEmpty
                      ? 'No events on this day.'
                      : '${selectedEvents.length} event${selectedEvents.length == 1 ? '' : 's'} planned',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 14),
              ]),
            ),
          ),
          if (controller.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (controller.errorMessage != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _EmptyDayPanel(
                  message: controller.errorMessage!,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            )
          else if (selectedEvents.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _EmptyDayPanel(
                  message: 'Nothing booked here yet.',
                  icon: Icons.event_busy_rounded,
                  onAddEvent: widget.onAddEvent,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = selectedEvents[index];
                    return EventCard(
                      key: ValueKey('calendar-${event.id ?? event.title}'),
                      event: event,
                      onEdit: widget.onEditEvent,
                      onDelete: (item, {bool? entireSeries}) async {
                        if (item.id != null) {
                          await context.read<EventController>().deleteEvent(item.id!, entireSeries: entireSeries ?? false);
                        }
                      },
                    );
                  },
                  childCount: selectedEvents.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

class _EmptyDayPanel extends StatelessWidget {
  const _EmptyDayPanel({
    required this.message,
    required this.icon,
    this.onAddEvent,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onAddEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (onAddEvent != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onAddEvent,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add an event'),
            ),
          ],
        ],
      ),
    );
  }
}
