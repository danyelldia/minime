import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/bill_item.dart';
import '../models/note_task.dart';
import '../providers/bill_provider.dart';
import '../providers/note_task_provider.dart';
import '../services/notification_service.dart';
import '../utils/natural_language_parser.dart';

enum QuickAddKind { note, task, bill, shopping }

/// Universal quick-add bottom sheet. Reachable from a "+" button on every
/// screen; defaults to whichever kind makes sense for the screen it was
/// opened from, but lets the user switch. For tasks, the text is run
/// through a tiny natural-language parser so things like "tomorrow at
/// 6pm water the plants" fill in the date/time automatically.
Future<void> showQuickAddSheet(
  BuildContext context, {
  QuickAddKind initialKind = QuickAddKind.task,
  String defaultCategoryId = 'personal',
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _QuickAddSheet(
      initialKind: initialKind,
      defaultCategoryId: defaultCategoryId,
    ),
  );
}

class _QuickAddSheet extends StatefulWidget {
  final QuickAddKind initialKind;
  final String defaultCategoryId;
  const _QuickAddSheet({required this.initialKind, required this.defaultCategoryId});

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  late QuickAddKind _kind;
  final _textController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _textController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _hint {
    switch (_kind) {
      case QuickAddKind.note:
        return 'Write something...';
      case QuickAddKind.task:
        return 'e.g. tomorrow at 6pm water the plants';
      case QuickAddKind.bill:
        return 'Bill name';
      case QuickAddKind.shopping:
        return 'Item to buy';
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    switch (_kind) {
      case QuickAddKind.note:
        await context.read<NoteTaskProvider>().addTask(NoteTask(
              id: const Uuid().v4(),
              title: text,
              type: ItemType.note,
              categoryId: widget.defaultCategoryId,
              createdAt: DateTime.now(),
            ));
        break;
      case QuickAddKind.task:
        final parsed = parseQuickAdd(text);
        final task = NoteTask(
          id: const Uuid().v4(),
          title: parsed.title,
          type: ItemType.todo,
          categoryId: widget.defaultCategoryId,
          dueDate: parsed.dateTime,
          reminderTime: parsed.dateTime,
          createdAt: DateTime.now(),
        );
        await context.read<NoteTaskProvider>().addTask(task);
        if (task.reminderTime != null) {
          await NotificationService.instance.scheduleReminder(task);
        }
        break;
      case QuickAddKind.bill:
      case QuickAddKind.shopping:
        final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
        await context.read<BillProvider>().addItem(BillItem(
              id: const Uuid().v4(),
              name: text,
              amount: amount,
              category: _kind == QuickAddKind.bill ? BillCategory.bill : BillCategory.shopping,
            ));
        break;
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Note'),
                selected: _kind == QuickAddKind.note,
                onSelected: (_) => setState(() => _kind = QuickAddKind.note),
              ),
              ChoiceChip(
                label: const Text('Task'),
                selected: _kind == QuickAddKind.task,
                onSelected: (_) => setState(() => _kind = QuickAddKind.task),
              ),
              ChoiceChip(
                label: const Text('Bill'),
                selected: _kind == QuickAddKind.bill,
                onSelected: (_) => setState(() => _kind = QuickAddKind.bill),
              ),
              ChoiceChip(
                label: const Text('Shopping item'),
                selected: _kind == QuickAddKind.shopping,
                onSelected: (_) => setState(() => _kind = QuickAddKind.shopping),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            autofocus: true,
            decoration: InputDecoration(hintText: _hint, border: const OutlineInputBorder()),
            onSubmitted: (_) => _submit(),
          ),
          if (_kind == QuickAddKind.bill || _kind == QuickAddKind.shopping) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
            ),
          ],
          if (_kind == QuickAddKind.task) ...[
            const SizedBox(height: 8),
            Text(
              'Tip: try "tomorrow at 8", "in 30 minutes", or "next friday".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: const Text('Add')),
        ],
      ),
    );
  }
}
