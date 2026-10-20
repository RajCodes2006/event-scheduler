import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/schedule_event.dart';
import '../services/notification_service.dart';
import '../state/event_controller.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.event});

  final ScheduleEvent? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late DateTime _startAt;
  late DateTime _endAt;
  late String _category;
  late int _reminderMinutesBefore;
  bool _saving = false;

  static const List<String> _categories = ['Personal', 'Work', 'Study', 'Health', 'Social', 'Other'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _startAt = widget.event?.startAt ?? nextHour;
    _endAt = widget.event?.endAt ?? _startAt.add(const Duration(hours: 1));
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _category = widget.event?.category ?? 'Personal';
    _reminderMinutesBefore = widget.event?.reminderMinutesBefore ?? 15;
    if (!_categories.contains(_category)) _category = 'Other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2050, 12, 31),
    );
    if (picked == null) return;

    setState(() {
      _startAt = DateTime(picked.year, picked.month, picked.day, _startAt.hour, _startAt.minute);
      _endAt = DateTime(picked.year, picked.month, picked.day, _endAt.hour, _endAt.minute);
      if (!_endAt.isAfter(_startAt)) _endAt = _startAt.add(const Duration(hours: 1));
    });
  }

  Future<void> _chooseStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startAt));
    if (picked == null) return;

    setState(() {
      _startAt = DateTime(_startAt.year, _startAt.month, _startAt.day, picked.hour, picked.minute);
      if (!_endAt.isAfter(_startAt)) _endAt = _startAt.add(const Duration(hours: 1));
    });
  }

  Future<void> _chooseEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_endAt));
    if (picked == null) return;

    setState(() {
      var candidate = DateTime(_startAt.year, _startAt.month, _startAt.day, picked.hour, picked.minute);
      if (!candidate.isAfter(_startAt)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      _endAt = candidate;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endAt.isAfter(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after the start time.')),
      );
      return;
    }

    setState(() => _saving = true);

    var notificationPermissionGranted = true;
    if (NotificationService.supportsEventReminders &&
        _reminderMinutesBefore > 0) {
      notificationPermissionGranted =
          await NotificationService.instance.requestPermission();
    }
    if (!mounted) return;

    final event = ScheduleEvent(
      id: widget.event?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      category: _category,
      startAt: _startAt,
      endAt: _endAt,
      reminderMinutesBefore: _reminderMinutesBefore,
    );

    try {
      final messenger = ScaffoldMessenger.of(context);
      await context.read<EventController>().saveEvent(event);
      if (mounted) {
        Navigator.of(context).pop();
        if (NotificationService.supportsEventReminders &&
            _reminderMinutesBefore > 0 &&
            !notificationPermissionGranted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Event saved. Allow notifications in Android Settings to receive reminders.',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this event. Please try again.')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit event' : 'New event', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const Text('EVENT DETAILS', style: TextStyle(fontSize: 11, letterSpacing: 1.7, fontWeight: FontWeight.w800, color: Color(0xFF5B5CE2))),
              const SizedBox(height: 13),
              TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Event title', hintText: 'e.g. Project meeting'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Add a title for your event.' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                onChanged: (value) => setState(() => _category = value ?? 'Personal'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Location (optional)', prefixIcon: Icon(Icons.place_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Notes (optional)', alignLabelWithHint: true, hintText: 'Anything you need to remember…'),
              ),
              const SizedBox(height: 28),
              const Text('DATE & TIME', style: TextStyle(fontSize: 11, letterSpacing: 1.7, fontWeight: FontWeight.w800, color: Color(0xFF5B5CE2))),
              const SizedBox(height: 13),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(DateFormat('EEEE, d MMMM yyyy').format(_startAt)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17), alignment: Alignment.centerLeft),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _TimeSelector(label: 'Starts', time: _startAt, onPressed: _chooseStartTime)),
                  const SizedBox(width: 12),
                  Expanded(child: _TimeSelector(label: 'Ends', time: _endAt, onPressed: _chooseEndTime)),
                ],
              ),
              const SizedBox(height: 12),
              if (NotificationService.supportsEventReminders) ...[
                DropdownButtonFormField<int>(
                  value: _reminderMinutesBefore,
                  decoration: const InputDecoration(
                    labelText: 'Reminder',
                    prefixIcon: Icon(Icons.notifications_active_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('No reminder')),
                    DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                    DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                    DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                    DropdownMenuItem(value: 60, child: Text('1 hour before')),
                  ],
                  onChanged: (value) {
                    setState(() => _reminderMinutesBefore = value ?? 15);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Daymark will remind you even when the app is closed, if notifications are allowed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777B8F),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Events that end after midnight are supported. The selected date is the start date.',
                style: TextStyle(fontSize: 12, color: Color(0xFF777B8F), height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : isEditing ? 'Save changes' : 'Create event'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({required this.label, required this.time, required this.onPressed});

  final String label;
  final DateTime time;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF777B8F))),
          const SizedBox(height: 5),
          Text(DateFormat('h:mm a').format(time), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
