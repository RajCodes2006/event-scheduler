import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/schedule_event.dart';
import '../state/event_controller.dart';
import '../widgets/event_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onAddEvent,
    required this.onEditEvent,
  });

  final VoidCallback onAddEvent;
  final ValueChanged<ScheduleEvent> onEditEvent;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EventController>();
    final todayEvents = controller.eventsForDay(DateTime.now());
    final upcomingEvents = controller.upcomingEvents;
    final visibleUpcomingEvents = upcomingEvents.take(5).toList(growable: false);
    final dateLabel = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey<String>('daymark-home-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAYMARK',
                            style: TextStyle(
                              color: Color(0xFF5B5CE2),
                              fontSize: 11,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Plan your day.',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              color: Color(0xFF777B8F),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E9FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF5B5CE2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    color: const Color(0xFF292A59),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MAKE ROOM FOR\nWHAT MATTERS.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                height: 1.25,
                                letterSpacing: -0.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              controller.events.isEmpty
                                  ? 'Start with one event. Keep the rest of your day clear.'
                                  : '${upcomingEvents.length} upcoming event${upcomingEvents.length == 1 ? '' : 's'} on your schedule.',
                              style: const TextStyle(
                                color: Color(0xFFD1D2F0),
                                height: 1.4,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: onAddEvent,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF292A59),
                              ),
                              child: const Text('Create event'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.event_available_rounded,
                        size: 62,
                        color: Color(0xFFB9BAFF),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Today',
                        value: '${todayEvents.length}',
                        icon: Icons.today_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Upcoming',
                        value: '${upcomingEvents.length}',
                        icon: Icons.upcoming_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Today',
                  subtitle: todayEvents.isEmpty
                      ? 'A little breathing room.'
                      : '${todayEvents.length} scheduled',
                ),
                const SizedBox(height: 13),
              ]),
            ),
          ),
          if (controller.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (controller.errorMessage != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _MessagePanel(
                  message: controller.errorMessage!,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            )
          else if (todayEvents.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _MessagePanel(
                  message: 'Nothing scheduled today. Enjoy the space or add an event.',
                  icon: Icons.coffee_rounded,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = todayEvents[index];
                    return EventCard(
                      key: ValueKey('today-${event.id ?? event.title}'),
                      event: event,
                      onEdit: onEditEvent,
                      onDelete: (item) async {
                        if (item.id != null) {
                          await context.read<EventController>().deleteEvent(item.id!);
                        }
                      },
                    );
                  },
                  childCount: todayEvents.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(
                  title: 'Coming up',
                  subtitle: 'Your next few plans',
                ),
                const SizedBox(height: 13),
              ]),
            ),
          ),
          if (!controller.isLoading && visibleUpcomingEvents.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _MessagePanel(
                  message: 'Your next events will show up here.',
                  icon: Icons.event_note_rounded,
                ),
              ),
            )
          else if (visibleUpcomingEvents.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = visibleUpcomingEvents[index];
                    return EventCard(
                      key: ValueKey('upcoming-${event.id ?? event.title}'),
                      event: event,
                      onEdit: onEditEvent,
                      onDelete: (item) async {
                        if (item.id != null) {
                          await context.read<EventController>().deleteEvent(item.id!);
                        }
                      },
                    );
                  },
                  childCount: visibleUpcomingEvents.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEBF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF5B5CE2), size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF777B8F)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF777B8F)),
        ),
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9A9DB0), size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777B8F), height: 1.4),
          ),
        ],
      ),
    );
  }
}
