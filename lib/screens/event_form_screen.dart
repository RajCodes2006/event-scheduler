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
  late String _recurrenceFrequency;
  DateTime? _recurrenceUntil;
  bool _repeatUntilCustom = false;
  bool _saving = false;

  static const List<String> _categories = [
    'Personal', 'Work', 'Study', 'Health', 'Social', 'Other',
  ];

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
    _recurrenceFrequency = widget.event?.recurrenceFrequency ?? 'none';
    _recurrenceUntil = widget.event?.recurrenceUntil;
    if (!_categories.contains(_category)) _category = 'Other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  int _wordCount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\\s+')).length;
  }

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Add a title for your event.';
    if (title.length < 8) return 'Title must be at least 8 characters.';
    return null;
  }

  String? _validateOptionalWords(String? value, String fieldName) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (_wordCount(text) < 8) {
      return '$fieldName must contain at least 8 words.';
    }
    return null;
  }

  DateTime _defaultRepeatUntil() {
    final spanDays = switch (_recurrenceFrequency) {
      'weekly' => 90,
      'monthly' => 365,
      _ => 30,
    };
    final candidate = DateTime(_startAt.year, _startAt.month, _startAt.day + spanDays);
    final appMax = DateTime(2050, 12, 31);
    return candidate.isAfter(appMax) ? appMax : candidate;
  }

  DateTime _lastAllowedRepeatDate() {
    final candidate = DateTime(_startAt.year, _startAt.month, _startAt.day + 365);
    final appMax = DateTime(2050, 12, 31);
    return candidate.isAfter(appMax) ? appMax : candidate;
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
      if (_recurrenceUntil != null && _recurrenceUntil!.isBefore(_startAt)) {
        _recurrenceUntil = _defaultRepeatUntil();
      }
      if (_recurrenceUntil != null && _recurrenceUntil!.isAfter(_lastAllowedRepeatDate())) {
        _recurrenceUntil = _lastAllowedRepeatDate();
      }
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
      if (!candidate.isAfter(_startAt)) candidate = candidate.add(const Duration(days: 1));
      _endAt = candidate;
    });
  }

  Future<void> _chooseRepeatUntil() async {
    final startDay = DateTime(_startAt.year, _startAt.month, _startAt.day);
    final initial = _recurrenceUntil ?? _defaultRepeatUntil();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(startDay) ? startDay : initial,
      firstDate: startDay,
      lastDate: _lastAllowedRepeatDate(),
      helpText: 'LAST REPEAT DATE',
    );
    if (picked != null) {
      setState(() {
        _recurrenceUntil = picked;
        _repeatUntilCustom = true;
      });
    }
  }

  void _setRepeatFrequency(String value) {
    setState(() {
      _recurrenceFrequency = value;
      if (value == 'none') {
        _recurrenceUntil = null;
        _repeatUntilCustom = false;
        return;
      }

      final startDay = DateTime(_startAt.year, _startAt.month, _startAt.day);
      if (!_repeatUntilCustom ||
          _recurrenceUntil == null ||
          _recurrenceUntil!.isBefore(startDay)) {
        _recurrenceUntil = _defaultRepeatUntil();
        _repeatUntilCustom = false;
      } else if (_recurrenceUntil!.isAfter(_lastAllowedRepeatDate())) {
        _recurrenceUntil = _lastAllowedRepeatDate();
      }
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
    if (!isValidRepeatSettings()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a repeat-until date on or after the event date.')),
      );
      return;
    }

    setState(() => _saving = true);
    var notificationPermissionGranted = true;
    if (NotificationService.supportsEventReminders && _reminderMinutesBefore > 0) {
      notificationPermissionGranted = await NotificationService.instance.requestPermission();
    }
    if (!mounted) return;

    final existing = widget.event;
    final event = ScheduleEvent(
      id: existing?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      category: _category,
      startAt: _startAt,
      endAt: _endAt,
      reminderMinutesBefore: _reminderMinutesBefore,
      recurrenceSeriesId: existing?.recurrenceSeriesId,
      recurrenceFrequency: existing?.recurrenceFrequency ?? _recurrenceFrequency,
      recurrenceUntil: existing?.recurrenceUntil ??
          (_recurrenceFrequency == 'none' ? null : _recurrenceUntil),
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
              content: Text('Event saved. Allow notifications in Android Settings to receive reminders.'),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save this event: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  bool isValidRepeatSettings() {
    if (widget.event != null || _recurrenceFrequency == 'none') return true;
    final until = _recurrenceUntil;
    if (until == null) return false;
    final startDay = DateTime(_startAt.year, _startAt.month, _startAt.day);
    return !until.isBefore(startDay);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEditing = widget.event != null;
    final isEditingSeriesOccurrence = widget.event?.isRecurring ?? false;
    final isRepeating = _recurrenceFrequency != 'none';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit event' : 'New event',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
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
              _FormSectionLabel(label: 'EVENT DETAILS'),
              const SizedBox(height: 13),
              TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Event title', hintText: 'e.g. Project meeting'),
                validator: _validateTitle,
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
                decoration: const InputDecoration(labelText: 'Location (optional)', prefixIcon: Icon(Icons.place_outlined), helperText: 'If provided, enter at least 8 words.'),
                validator: (value) => _validateOptionalWords(value, 'Location'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Notes (optional)', alignLabelWithHint: true, hintText: 'Anything you need to remember…', helperText: 'If provided, enter at least 8 words.'),
                validator: (value) => _validateOptionalWords(value, 'Notes'),
              ),
              const SizedBox(height: 28),
              _FormSectionLabel(label: 'DATE & TIME'),
              const SizedBox(height: 13),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(DateFormat('EEEE, d MMMM yyyy').format(_startAt)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _TimeSelector(label: 'Starts', time: _startAt, onPressed: _chooseStartTime)),
                  const SizedBox(width: 12),
                  Expanded(child: _TimeSelector(label: 'Ends', time: _endAt, onPressed: _chooseEndTime)),
                ],
              ),
              if (!isEditing) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _recurrenceFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Repeat',
                    prefixIcon: Icon(Icons.repeat_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                    DropdownMenuItem(value: 'daily', child: Text('Every day')),
                    DropdownMenuItem(value: 'weekly', child: Text('Every week')),
                    DropdownMenuItem(value: 'monthly', child: Text('Every month')),
                  ],
                  onChanged: (value) => _setRepeatFrequency(value ?? 'none'),
                ),
                if (isRepeating) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _chooseRepeatUntil,
                    icon: const Icon(Icons.event_repeat_rounded),
                    label: Text('Repeat until ${DateFormat('d MMM yyyy').format(_recurrenceUntil ?? _defaultRepeatUntil())}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Occurrences are saved individually through the selected end date. You can remove one occurrence or the whole series later.',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.4),
                  ),
                ],
              ] else if (isEditingSeriesOccurrence) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.repeat_rounded, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This is one occurrence in a ${widget.event!.recurrenceFrequency} series. Changes apply to this occurrence only.',
                          style: TextStyle(color: scheme.onSurface, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 26),
              if (NotificationService.supportsEventReminders) ...[
                _FormSectionLabel(label: 'REMINDER'),
                const SizedBox(height: 13),
                DropdownButtonFormField<int>(
                  value: _reminderMinutesBefore,
                  decoration: const InputDecoration(
                    labelText: 'Notify me',
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
                  onChanged: (value) => setState(() => _reminderMinutesBefore = value ?? 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reminders can arrive while Daymark is closed when notifications are allowed.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ],
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : isEditing ? 'Save changes' : isRepeating ? 'Create series' : 'Create event'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.7,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.primary,
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
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 5),
          Text(DateFormat('h:mm a').format(time),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
