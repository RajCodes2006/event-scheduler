import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_event.dart';

typedef DeleteEventCallback = Future<void> Function(
  ScheduleEvent event, {
  bool entireSeries,
});

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleEvent event;
  final ValueChanged<ScheduleEvent> onEdit;
  final DeleteEventCallback onDelete;

  Color _categoryColor(BuildContext context) {
    switch (event.category) {
      case 'Work':
        return const Color(0xFF5286EC);
      case 'Health':
        return const Color(0xFF35B58C);
      case 'Social':
        return const Color(0xFFC27DDE);
      case 'Study':
        return const Color(0xFFE8AD4F);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData get _categoryIcon {
    switch (event.category) {
      case 'Work':
        return Icons.work_outline_rounded;
      case 'Health':
        return Icons.favorite_border_rounded;
      case 'Social':
        return Icons.groups_2_outlined;
      case 'Study':
        return Icons.menu_book_outlined;
      default:
        return Icons.event_note_rounded;
    }
  }

  Future<void> _showActions(BuildContext context, String value) async {
    if (value == 'edit') {
      onEdit(event);
      return;
    }

    final entireSeries = value == 'delete-series';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entireSeries ? 'Delete this series?' : 'Delete this event?'),
        content: Text(
          entireSeries
              ? 'Every occurrence of “${event.title}” will be removed from your schedule.'
              : '“${event.title}” will be removed from your schedule.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(entireSeries ? 'Delete series' : 'Delete event'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete(event, entireSeries: entireSeries);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEE, d MMM').format(event.startAt);
    final timeLabel = '${DateFormat('h:mm a').format(event.startAt)} – '
        '${DateFormat('h:mm a').format(event.endAt)}';
    final categoryColor = _categoryColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onEdit(event),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 5, 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 58,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_categoryIcon, color: categoryColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$dateLabel  •  $timeLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                          ),
                          if (event.isRecurring) ...[
                            const SizedBox(width: 5),
                            Tooltip(
                              message: 'Repeats ${event.recurrenceFrequency}',
                              child: Icon(Icons.repeat_rounded, size: 14, color: scheme.primary),
                            ),
                          ],
                        ],
                      ),
                      if (event.location.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Event options',
                  onSelected: (value) => _showActions(context, value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit occurrence')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(event.isRecurring ? 'Delete occurrence' : 'Delete event'),
                    ),
                    if (event.isRecurring)
                      const PopupMenuItem(
                        value: 'delete-series',
                        child: Text('Delete entire series'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
