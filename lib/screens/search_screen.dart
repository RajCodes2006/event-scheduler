import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_event.dart';
import '../state/event_controller.dart';
import '../widgets/event_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.onEditEvent});

  final ValueChanged<ScheduleEvent> onEditEvent;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _dateScope = 'Upcoming';

  static const categories = [
    'All', 'Personal', 'Work', 'Study', 'Health', 'Social', 'Other',
  ];
  static const dateScopes = ['All', 'Upcoming', 'Today', 'Past'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final query = _searchController.text.trim().toLowerCase();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = events.where((event) {
      final matchesQuery = query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.category.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'All' || event.category == _selectedCategory;
      final matchesDate = switch (_dateScope) {
        'Upcoming' => event.endAt.isAfter(now),
        'Today' => event.startAt.year == today.year &&
            event.startAt.month == today.month &&
            event.startAt.day == today.day,
        'Past' => event.endAt.isBefore(now),
        _ => true,
      };
      return matchesQuery && matchesCategory && matchesDate;
    }).toList(growable: false);

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey<String>('daymark-search-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find your next thing.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Search the details. Filter down to what matters.',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search title, notes, place…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  Text('CATEGORY',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      return ChoiceChip(
                        label: Text(category),
                        selected: category == _selectedCategory,
                        onSelected: (_) => setState(() => _selectedCategory = category),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 19),
                  Text('WHEN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    children: dateScopes.map((scope) {
                      return ChoiceChip(
                        label: Text(scope),
                        selected: scope == _dateScope,
                        onSelected: (_) => setState(() => _dateScope = scope),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your results',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text('${filtered.length} found',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 13),
                ],
              ),
            ),
          ),
          if (controller.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (filtered.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 32, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 10),
                      const Text('No events match those filters.',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text('Try another keyword or clear a filter.',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = filtered[index];
                    return EventCard(
                      key: ValueKey('search-${event.id ?? event.title}'),
                      event: event,
                      onEdit: widget.onEditEvent,
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
                  childCount: filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
