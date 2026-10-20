import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_event.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleEvent event;
  final ValueChanged<ScheduleEvent> onEdit;
  final Future<void> Function(ScheduleEvent event) onDelete;

  Color get _categoryColor {
    switch (event.category) {
      case 'Work':
        return const Color(0xFF4175D5);
      case 'Health':
        return const Color(0xFF269A77);
      case 'Social':
        return const Color(0xFFB765C6);
      case 'Study':
        return const Color(0xFFE39A31);
      default:
        return const Color(0xFF5B5CE2);
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this event?'),
        content: Text('“${event.title}” will be removed from your schedule.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) await onDelete(event);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, d MMM').format(event.startAt);
    final timeLabel = '${DateFormat('h:mm a').format(event.startAt)} – '
        '${DateFormat('h:mm a').format(event.endAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEBF2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onEdit(event),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 54,
                decoration: BoxDecoration(
                  color: _categoryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_categoryIcon, color: _categoryColor, size: 21),
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$dateLabel  •  $timeLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF73768A)),
                    ),
                    if (event.location.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF73768A)),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Event options',
                onSelected: (value) => _showActions(context, value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
