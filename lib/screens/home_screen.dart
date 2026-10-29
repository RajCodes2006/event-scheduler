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
    final events = context.select<EventController, List<ScheduleEvent>>(
      (controller) => controller.events,
    );
    final isLoading = context.select<EventController, bool>(
      (controller) => controller.isLoading,
    );
    final errorMessage = context.select<EventController, String?>(
      (controller) => controller.errorMessage,
    );
    final isDarkMode = context.select<EventController, bool>(
      (controller) => controller.isDarkMode,
    );
    final controller = context.read<EventController>();
    final scheme = Theme.of(context).colorScheme;
    final todayEvents = controller.eventsForDay(DateTime.now());
    final upcomingEvents = controller.upcomingEvents;
    final visibleUpcomingEvents = upcomingEvents.take(5).toList(growable: false);
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, d MMMM').format(now);

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey<String>('daymark-home-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.wb_twilight_rounded, size: 15, color: scheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'DAYMARK',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: 11,
                                  letterSpacing: 2.3,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _greeting(now.hour),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(dateLabel,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
                        ],
                      ),
                    ),
                    Material(
                      color: scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: IconButton(
                        tooltip: controller.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
                        onPressed: controller.toggleDarkMode,
                        icon: Icon(controller.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded),
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(23),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: controller.isDarkMode
                          ? const [Color(0xFF302C67), Color(0xFF1D2548)]
                          : const [Color(0xFF302D70), Color(0xFF5B54D9)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: controller.isDarkMode ? 0.10 : 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'YOUR DAY, IN FOCUS',
                                style: TextStyle(
                                  color: Color(0xFFE7E5FF),
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Make room for\nwhat matters.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                height: 1.08,
                                letterSpacing: -1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              events.isEmpty
                                  ? 'Start small. Add what matters to you.'
                                  : '${upcomingEvents.length} upcoming event${upcomingEvents.length == 1 ? '' : 's'} on your schedule.',
                              style: const TextStyle(
                                color: Color(0xFFD9D8FF),
                                height: 1.45,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 17),
                            FilledButton.icon(
                              onPressed: onAddEvent,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Create event'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF342F85),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month_rounded, size: 66, color: Color(0xFFBEBBFF)),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
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
                        label: 'Coming up',
                        value: '${upcomingEvents.length}',
                        icon: Icons.upcoming_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Today',
                  subtitle: todayEvents.isEmpty ? 'A little breathing room' : '${todayEvents.length} scheduled',
                ),
                const SizedBox(height: 13),
              ]),
            ),
          ),
          if (controller.isLoading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
            )
          else if (controller.errorMessage != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: _MessagePanel(
                  message: controller.errorMessage!,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            )
          else if (todayEvents.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: _MessagePanel(
                  message: 'Nothing scheduled today. Enjoy the space or add an event.',
                  icon: Icons.coffee_rounded,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = todayEvents[index];
                    return EventCard(
                      key: ValueKey('today-${event.id ?? event.title}'),
                      event: event,
                      onEdit: onEditEvent,
                      onDelete: (item, {bool? entireSeries}) async {
                        if (item.id != null) {
                          await context.read<EventController>().deleteEvent(
                                item.id!,
                                entireSeries: entireSeries ?? false,
                              );
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
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(title: 'Coming up', subtitle: 'Your next few plans'),
                const SizedBox(height: 13),
              ]),
            ),
          ),
          if (!controller.isLoading && visibleUpcomingEvents.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: _MessagePanel(
                  message: 'Your next events will show up here.',
                  icon: Icons.event_note_rounded,
                ),
              ),
            )
          else if (visibleUpcomingEvents.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = visibleUpcomingEvents[index];
                    return EventCard(
                      key: ValueKey('upcoming-${event.id ?? event.title}'),
                      event: event,
                      onEdit: onEditEvent,
                      onDelete: (item, {bool? entireSeries}) async {
                        if (item.id != null) {
                          await context.read<EventController>().deleteEvent(
                                item.id!,
                                entireSeries: entireSeries ?? false,
                              );
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

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
        ),
        Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant, size: 28),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45)),
        ],
      ),
    );
  }
}
