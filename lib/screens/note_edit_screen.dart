import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/note_task.dart';
import '../providers/category_provider.dart';
import '../providers/note_task_provider.dart';
import '../providers/priority_tag_provider.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../widgets/color_swatch_picker.dart';

enum _ExitAction { save, discard }

class NoteEditScreen extends StatefulWidget {
  final NoteTask? existing;
  final String? defaultCategoryId;

  const NoteEditScreen({super.key, this.existing, this.defaultCategoryId});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _durationController;
  late final TextEditingController _tagController;
  late final TextEditingController _subtaskController;
  late final TextEditingController _locationNameController;
  late final TextEditingController _radiusController;

  late ItemType _type;
  late String _categoryId;
  String? _priorityTagId;
  Color? _urgencyColor;
  DateTime? _dueDate;
  TimeOfDay? _reminderTimeOfDay;
  bool _repeatDaily = false;
  String _durationUnit = 'min';
  bool _isUrgent = false;
  bool _isImportant = false;
  List<String> _tags = [];
  bool _voiceNotificationEnabled = true;
  bool _locationEnabled = false;
  double? _locationLat;
  double? _locationLng;
  bool _fetchingLocation = false;
  bool _saving = false;

  // Snapshot of every editable field, captured right after initState
  // finishes populating them from widget.existing - used to detect
  // unsaved changes when the user presses Back instead of Save.
  late final String _snapshotTitle;
  late final String _snapshotDesc;
  late final ItemType _snapshotType;
  late final String _snapshotCategoryId;
  late final String? _snapshotPriorityTagId;
  late final int? _snapshotUrgencyColor;
  late final DateTime? _snapshotDueDate;
  late final TimeOfDay? _snapshotReminderTimeOfDay;
  late final bool _snapshotRepeatDaily;
  late final String _snapshotDurationText;
  late final String _snapshotDurationUnit;
  late final bool _snapshotIsUrgent;
  late final bool _snapshotIsImportant;
  late final List<String> _snapshotTags;
  late final bool _snapshotVoiceNotificationEnabled;
  late final bool _snapshotLocationEnabled;
  late final String _snapshotLocationName;
  late final String _snapshotRadiusText;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _durationUnit = e?.durationUnit ?? 'min';
    final displayDuration =
        e?.durationMinutes != null ? minutesToDisplay(e!.durationMinutes!, _durationUnit) : null;
    _durationController = TextEditingController(
      text: displayDuration == null
          ? ''
          : (displayDuration == displayDuration.roundToDouble()
              ? displayDuration.toInt().toString()
              : displayDuration.toString()),
    );
    _tagController = TextEditingController();
    _subtaskController = TextEditingController();
    _locationNameController = TextEditingController(text: e?.locationName ?? '');
    _radiusController = TextEditingController(text: (e?.locationRadius ?? 200).toInt().toString());
    _type = e?.type ?? ItemType.todo;
    _categoryId = e?.categoryId ?? widget.defaultCategoryId ?? 'personal';
    _priorityTagId = e?.priorityTagId;
    _urgencyColor = e?.urgencyColor != null ? Color(e!.urgencyColor!) : null;
    _dueDate = e?.dueDate;
    _reminderTimeOfDay = e?.reminderTime != null ? TimeOfDay.fromDateTime(e!.reminderTime!) : null;
    _repeatDaily = e?.recurrenceRule == 'DAILY';
    _isUrgent = e?.isUrgent ?? false;
    _isImportant = e?.isImportant ?? false;
    _tags = List.of(e?.tags ?? const []);
    _voiceNotificationEnabled = e?.voiceNotificationEnabled ?? true;
    _locationEnabled = e?.hasLocation ?? false;
    _locationLat = e?.locationLat;
    _locationLng = e?.locationLng;

    _snapshotTitle = _titleController.text.trim();
    _snapshotDesc = _descController.text.trim();
    _snapshotType = _type;
    _snapshotCategoryId = _categoryId;
    _snapshotPriorityTagId = _priorityTagId;
    _snapshotUrgencyColor = _urgencyColor?.value;
    _snapshotDueDate = _dueDate;
    _snapshotReminderTimeOfDay = _reminderTimeOfDay;
    _snapshotRepeatDaily = _repeatDaily;
    _snapshotDurationText = _durationController.text.trim();
    _snapshotDurationUnit = _durationUnit;
    _snapshotIsUrgent = _isUrgent;
    _snapshotIsImportant = _isImportant;
    _snapshotTags = List.of(_tags);
    _snapshotVoiceNotificationEnabled = _voiceNotificationEnabled;
    _snapshotLocationEnabled = _locationEnabled;
    _snapshotLocationName = _locationNameController.text.trim();
    _snapshotRadiusText = _radiusController.text.trim();
  }

  bool get _hasUnsavedChanges {
    if (_titleController.text.trim() != _snapshotTitle) return true;
    if (_descController.text.trim() != _snapshotDesc) return true;
    if (_type != _snapshotType) return true;
    if (_categoryId != _snapshotCategoryId) return true;
    if (_priorityTagId != _snapshotPriorityTagId) return true;
    if (_urgencyColor?.value != _snapshotUrgencyColor) return true;
    if (_dueDate != _snapshotDueDate) return true;
    if (_reminderTimeOfDay != _snapshotReminderTimeOfDay) return true;
    if (_repeatDaily != _snapshotRepeatDaily) return true;
    if (_durationController.text.trim() != _snapshotDurationText) return true;
    if (_durationUnit != _snapshotDurationUnit) return true;
    if (_isUrgent != _snapshotIsUrgent) return true;
    if (_isImportant != _snapshotIsImportant) return true;
    if (_tags.length != _snapshotTags.length || !_tags.every(_snapshotTags.contains)) return true;
    if (_voiceNotificationEnabled != _snapshotVoiceNotificationEnabled) return true;
    if (_locationEnabled != _snapshotLocationEnabled) return true;
    if (_locationEnabled) {
      if (_locationNameController.text.trim() != _snapshotLocationName) return true;
      if (_radiusController.text.trim() != _snapshotRadiusText) return true;
    }
    return false;
  }

  Future<_ExitAction?> _confirmDiscardDialog() {
    return showDialog<_ExitAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _tagController.dispose();
    _subtaskController.dispose();
    _locationNameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimeOfDay ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _reminderTimeOfDay = picked);
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    final position = await LocationService.instance.currentPosition();
    setState(() => _fetchingLocation = false);
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't get your location. Check location permission.")),
        );
      }
      return;
    }
    setState(() {
      _locationLat = position.latitude;
      _locationLng = position.longitude;
    });
  }

  Future<void> _save() async {
    // Pazeste impotriva dublu-tap / dublu-submit: fara asta, daca
    // programarea notificarii dura putin (sau arunca o eroare), userul
    // apasa Save a doua oara si se creau 2 task-uri identice.
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _doSave(title);
    } catch (e, st) {
      debugPrint('NoteEditScreen._save error: $e\n$st');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save - please try again.')),
        );
      }
    }
  }

  Future<void> _doSave(String title) async {
    final rawDuration = num.tryParse(_durationController.text.trim());
    final duration = rawDuration != null ? durationToMinutes(rawDuration, _durationUnit) : null;
    final desc = _descController.text.trim();
    final provider = context.read<NoteTaskProvider>();

    DateTime? reminderDateTime;
    if (_reminderTimeOfDay != null) {
      final now = DateTime.now();
      reminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _reminderTimeOfDay!.hour,
        _reminderTimeOfDay!.minute,
      );
    }
    final recurrenceRule = _repeatDaily ? 'DAILY' : null;
    final radius = double.tryParse(_radiusController.text.trim()) ?? 200;

    late final NoteTask savedTask;

    if (widget.existing != null) {
      final e = widget.existing!;
      savedTask = NoteTask(
        id: e.id,
        title: title,
        description: desc.isEmpty ? null : desc,
        type: _type,
        categoryId: _categoryId,
        priorityTagId: _priorityTagId,
        urgencyColor: _urgencyColor?.value,
        durationMinutes: _type == ItemType.todo ? duration : null,
        durationUnit: _durationUnit,
        dueDate: _dueDate,
        reminderTime: reminderDateTime,
        recurrenceRule: recurrenceRule,
        isDone: e.isDone,
        createdAt: e.createdAt,
        completedAt: e.completedAt,
        googleCalendarEventId: e.googleCalendarEventId,
        parentTaskId: e.parentTaskId,
        tags: _tags,
        isUrgent: _isUrgent,
        isImportant: _isImportant,
        sortOrder: e.sortOrder,
        locationName: _locationEnabled ? _locationNameController.text.trim() : null,
        locationLat: _locationEnabled ? _locationLat : null,
        locationLng: _locationEnabled ? _locationLng : null,
        locationRadius: _locationEnabled ? radius : null,
        locationLastTriggeredDate: _locationEnabled ? e.locationLastTriggeredDate : null,
        voiceNotificationEnabled: _voiceNotificationEnabled,
      );
      await provider.updateTask(savedTask);
    } else {
      savedTask = NoteTask(
        id: const Uuid().v4(),
        title: title,
        description: desc.isEmpty ? null : desc,
        type: _type,
        categoryId: _categoryId,
        priorityTagId: _priorityTagId,
        urgencyColor: _urgencyColor?.value,
        durationMinutes: _type == ItemType.todo ? duration : null,
        durationUnit: _durationUnit,
        dueDate: _dueDate,
        reminderTime: reminderDateTime,
        recurrenceRule: recurrenceRule,
        createdAt: DateTime.now(),
        tags: _tags,
        isUrgent: _isUrgent,
        isImportant: _isImportant,
        locationName: _locationEnabled ? _locationNameController.text.trim() : null,
        locationLat: _locationEnabled ? _locationLat : null,
        locationLng: _locationEnabled ? _locationLng : null,
        locationRadius: _locationEnabled ? radius : null,
        voiceNotificationEnabled: _voiceNotificationEnabled,
      );
      await provider.addTask(savedTask);
    }

    if (savedTask.reminderTime != null) {
      await NotificationService.instance.scheduleReminder(savedTask);
    } else {
      await NotificationService.instance.cancelReminder(savedTask.id);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await context.read<NoteTaskProvider>().deleteTask(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addSubtask() async {
    final text = _subtaskController.text.trim();
    if (text.isEmpty || widget.existing == null) return;
    final subtask = NoteTask(
      id: const Uuid().v4(),
      title: text,
      type: ItemType.todo,
      categoryId: widget.existing!.categoryId,
      parentTaskId: widget.existing!.id,
      createdAt: DateTime.now(),
    );
    await context.read<NoteTaskProvider>().addTask(subtask);
    _subtaskController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final tagProvider = context.watch<PriorityTagProvider>();
    final taskProvider = context.watch<NoteTaskProvider>();
    final allCategories = categoryProvider.categories;
    final isSubtask = widget.existing?.isSubtask ?? false;
    final canHaveSubtasks = widget.existing != null && !isSubtask && _type == ItemType.todo;
    final subtasks = widget.existing != null ? taskProvider.subtasksOf(widget.existing!.id) : const [];

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final action = await _confirmDiscardDialog();
        if (!mounted) return;
        if (action == _ExitAction.save) {
          await _save();
        } else if (action == _ExitAction.discard) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing != null ? 'Edit' : 'Add'),
          actions: [
            if (widget.existing != null)
              IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<ItemType>(
              segments: const [
                ButtonSegment(
                  value: ItemType.note,
                  label: Text('Note'),
                  icon: Icon(Icons.sticky_note_2_rounded),
                ),
                ButtonSegment(
                  value: ItemType.todo,
                  label: Text('To-Do'),
                  icon: Icon(Icons.check_box_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: allCategories.any((c) => c.id == _categoryId) ? _categoryId : null,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: allCategories.map((c) {
                final prefix = c.isMainCategory ? '' : '  -- ';
                return DropdownMenuItem(value: c.id, child: Text('$prefix${c.name}'));
              }).toList(),
              onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _priorityTagId,
              decoration: const InputDecoration(
                labelText: 'Priority (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('None')),
                ...tagProvider.tags.map(
                  (t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.label)),
                ),
              ],
              onChanged: (v) => setState(() => _priorityTagId = v),
            ),
            const SizedBox(height: 16),
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._tags.map((t) => Chip(
                      label: Text(t),
                      onDeleted: () => setState(() => _tags.remove(t)),
                    )),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(hintText: 'Add tag', isDense: true),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Urgent'),
                    value: _isUrgent,
                    onChanged: (v) => setState(() => _isUrgent = v),
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Important'),
                    value: _isImportant,
                    onChanged: (v) => setState(() => _isImportant = v),
                  ),
                ),
              ],
            ),
            Text(
              'Used by the Eisenhower Matrix view on the Today screen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_type == ItemType.todo) ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _durationController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Estimated duration',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _durationUnit,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'min', child: Text('minutes')),
                        DropdownMenuItem(value: 'hour', child: Text('hours')),
                        DropdownMenuItem(value: 'day', child: Text('days')),
                      ],
                      onChanged: (v) => setState(() => _durationUnit = v ?? 'min'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_dueDate == null
                  ? 'No due date'
                  : 'Due date: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: _pickDueDate,
            ),
            const Divider(height: 32),
            Text('Reminder notification', style: Theme.of(context).textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable reminder'),
              value: _reminderTimeOfDay != null,
              onChanged: (v) => setState(() {
                _reminderTimeOfDay = v ? (_reminderTimeOfDay ?? TimeOfDay.now()) : null;
                if (!v) _repeatDaily = false;
              }),
            ),
            if (_reminderTimeOfDay != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Time: ${_reminderTimeOfDay!.format(context)}'),
                trailing: const Icon(Icons.access_time_rounded),
                onTap: _pickReminderTime,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat daily'),
                value: _repeatDaily,
                onChanged: (v) => setState(() => _repeatDaily = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow voice notification'),
                subtitle: const Text('Speaks the reminder aloud. Turn off for a silent banner only.'),
                value: _voiceNotificationEnabled,
                onChanged: (v) => setState(() => _voiceNotificationEnabled = v),
              ),
              Text(
                'The notification comes with sound and quick actions: Done, '
                'Snooze 15m, Not Today.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Divider(height: 32),
            Text('Location reminder', style: Theme.of(context).textTheme.titleSmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me when I\'m near a place'),
              value: _locationEnabled,
              onChanged: (v) => setState(() => _locationEnabled = v),
            ),
            if (_locationEnabled) ...[
              TextField(
                controller: _locationNameController,
                decoration: const InputDecoration(
                  labelText: 'Place name (e.g. Home, Office)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _fetchingLocation ? null : _useCurrentLocation,
                icon: const Icon(Icons.my_location_rounded),
                label: Text(_fetchingLocation
                    ? 'Getting location...'
                    : _locationLat != null
                        ? 'Location set (tap to update)'
                        : 'Use my current location'),
              ),
              Text(
                'Checked whenever you open or resume MiniMe while near this spot.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            Text('Urgency color (optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ColorSwatchPicker(
              selected: _urgencyColor,
              onChanged: (c) => setState(() => _urgencyColor = c),
            ),
            if (canHaveSubtasks) ...[
              const Divider(height: 32),
              Text('Subtasks', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...subtasks.map((sub) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: sub.isDone,
                    title: Text(
                      sub.title,
                      style: TextStyle(
                        decoration: sub.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    onChanged: (_) => context.read<NoteTaskProvider>().toggleDone(sub),
                  )),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: const InputDecoration(hintText: 'Add subtask'),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add_rounded), onPressed: _addSubtask),
                ],
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
