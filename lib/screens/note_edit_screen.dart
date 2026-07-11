import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/note_task.dart';
import '../providers/category_provider.dart';
import '../providers/note_task_provider.dart';
import '../providers/priority_tag_provider.dart';
import '../services/notification_service.dart';
import '../widgets/color_swatch_picker.dart';

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

  late ItemType _type;
  late String _categoryId;
  String? _priorityTagId;
  Color? _urgencyColor;
  DateTime? _dueDate;
  TimeOfDay? _reminderTimeOfDay;
  bool _repeatDaily = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _durationController = TextEditingController(text: e?.durationMinutes?.toString() ?? '');
    _type = e?.type ?? ItemType.todo;
    _categoryId = e?.categoryId ?? widget.defaultCategoryId ?? 'personal';
    _priorityTagId = e?.priorityTagId;
    _urgencyColor = e?.urgencyColor != null ? Color(e!.urgencyColor!) : null;
    _dueDate = e?.dueDate;
    _reminderTimeOfDay = e?.reminderTime != null ? TimeOfDay.fromDateTime(e!.reminderTime!) : null;
    _repeatDaily = e?.recurrenceRule == 'DAILY';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final duration = int.tryParse(_durationController.text.trim());
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
        dueDate: _dueDate,
        reminderTime: reminderDateTime,
        recurrenceRule: recurrenceRule,
        isDone: e.isDone,
        createdAt: e.createdAt,
        completedAt: e.completedAt,
        googleCalendarEventId: e.googleCalendarEventId,
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
        dueDate: _dueDate,
        reminderTime: reminderDateTime,
        recurrenceRule: recurrenceRule,
        createdAt: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final tagProvider = context.watch<PriorityTagProvider>();
    final allCategories = categoryProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Editeaza' : 'Adauga'),
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
                label: Text('Notita'),
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
            decoration: const InputDecoration(labelText: 'Titlu', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descriere (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: allCategories.any((c) => c.id == _categoryId) ? _categoryId : null,
            decoration: const InputDecoration(labelText: 'Categorie', border: OutlineInputBorder()),
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
              labelText: 'Prioritate (optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Fara')),
              ...tagProvider.tags.map(
                (t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.label)),
              ),
            ],
            onChanged: (v) => setState(() => _priorityTagId = v),
          ),
          const SizedBox(height: 16),
          if (_type == ItemType.todo) ...[
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durata estimata (minute)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_dueDate == null
                ? 'Fara data limita'
                : 'Data limita: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
            trailing: const Icon(Icons.calendar_month_rounded),
            onTap: _pickDueDate,
          ),
          const Divider(height: 32),
          Text('Reminder cu notificare', style: Theme.of(context).textTheme.titleSmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activeaza reminder'),
            value: _reminderTimeOfDay != null,
            onChanged: (v) => setState(() {
              _reminderTimeOfDay = v ? (_reminderTimeOfDay ?? TimeOfDay.now()) : null;
              if (!v) _repeatDaily = false;
            }),
          ),
          if (_reminderTimeOfDay != null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Ora: ${_reminderTimeOfDay!.format(context)}'),
              trailing: const Icon(Icons.access_time_rounded),
              onTap: _pickReminderTime,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repeta zilnic'),
              value: _repeatDaily,
              onChanged: (v) => setState(() => _repeatDaily = v),
            ),
            Text(
              'Notificarea vine cu sunet si actiuni rapide: Done, Snooze 15m, '
              'Not azi, Maine.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          Text('Culoare de urgenta (optional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ColorSwatchPicker(
            selected: _urgencyColor,
            onChanged: (c) => setState(() => _urgencyColor = c),
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: _save, child: const Text('Salveaza')),
        ],
      ),
    );
  }
}
