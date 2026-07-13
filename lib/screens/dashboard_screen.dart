import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/bill_item.dart';
import '../models/category.dart';
import '../models/note_task.dart';
import '../providers/bill_provider.dart';
import '../providers/history_provider.dart';
import '../providers/note_task_provider.dart';
import '../widgets/quick_add_sheet.dart';
import 'bill_edit_screen.dart';
import 'category_detail_screen.dart';
import 'eisenhower_screen.dart';
import 'history_screen.dart';
import 'note_edit_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _quickNoteController = TextEditingController();
  final _quickNoteFocus = FocusNode();
  bool _savingQuickNote = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  @override
  void dispose() {
    _quickNoteController.dispose();
    _quickNoteFocus.dispose();
    super.dispose();
  }

  Future<void> _saveQuickNote() async {
    // Pazeste impotriva dublu-tap / dublu-submit (Enter apasat de 2 ori).
    if (_savingQuickNote) return;
    final text = _quickNoteController.text.trim();
    if (text.isEmpty) return;

    setState(() => _savingQuickNote = true);
    try {
      await context.read<NoteTaskProvider>().addTask(NoteTask(
            id: const Uuid().v4(),
            title: text,
            type: ItemType.note,
            categoryId: quickNotesCategoryId,
            createdAt: DateTime.now(),
          ));
      _quickNoteController.clear();
    } catch (e) {
      // best-effort - lasam textul acolo ca userul sa nu piarda ce a scris.
    } finally {
      if (mounted) setState(() => _savingQuickNote = false);
    }
    // Pastreaza focusul ca userul sa poata scrie imediat urmatoarea notita,
    // fara sa mai atinga ecranul.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _quickNoteFocus.requestFocus();
    });
  }

  List<NoteTask> _urgentTasks(NoteTaskProvider provider) {
    final todos = provider.pendingTodos.toList();
    todos.sort((a, b) {
      if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
      if (a.isImportant != b.isImportant) return a.isImportant ? -1 : 1;
      final aDate = a.reminderTime ?? a.dueDate;
      final bDate = b.reminderTime ?? b.dueDate;
      if (aDate != null && bDate != null) return aDate.compareTo(bDate);
      if (aDate != null) return -1;
      if (bDate != null) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return todos.take(5).toList();
  }

  List<BillItem> _urgentBills(BillProvider provider) {
    final bills = provider.byCategory(BillCategory.bill).where((b) => !b.isSettled).toList();
    bills.sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return 0;
    });
    return bills.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<NoteTaskProvider>();
    final billProvider = context.watch<BillProvider>();
    final history = context.watch<HistoryProvider>();
    final streak = history.currentStreak;

    final quickNotesCount = taskProvider.byCategory(quickNotesCategoryId).length;
    final urgentTasks = _urgentTasks(taskProvider);
    final urgentBills = _urgentBills(billProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniMe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Eisenhower Matrix',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EisenhowerScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickAddSheet(context, initialKind: QuickAddKind.note),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (streak > 0)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Text(
                      '$streak day${streak == 1 ? '' : 's'} streak - keep it going!',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          if (streak > 0) const SizedBox(height: 16),

          // Quick Note - scrie si apasa Enter (sau butonul), se salveaza
          // instant in categoria "Quick Notes", fara pasi suplimentari.
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Quick Note', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _quickNoteController,
                          focusNode: _quickNoteFocus,
                          autofocus: true,
                          maxLines: null,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Type here...',
                          ),
                          onSubmitted: (_) => _saveQuickNote(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: _savingQuickNote
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    onPressed: _savingQuickNote ? null : _saveQuickNote,
                  ),
                ],
              ),
            ),
          ),
          if (quickNotesCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryDetailScreen(categoryId: quickNotesCategoryId),
                  ),
                ),
                child: Text('View $quickNotesCount quick note${quickNotesCount == 1 ? '' : 's'}'),
              ),
            ),
          const SizedBox(height: 24),

          const _SectionHeader(title: 'Tasks', icon: Icons.checklist_rounded),
          const SizedBox(height: 8),
          if (urgentTasks.isEmpty)
            const _EmptyHint(text: 'Nothing urgent right now.')
          else
            ...urgentTasks.map((t) => _SimpleRow(
                  leading: Icon(
                    t.isUrgent ? Icons.bolt_rounded : Icons.circle_outlined,
                    size: 18,
                    color: t.isUrgent ? Colors.orange : Theme.of(context).colorScheme.outline,
                  ),
                  title: t.title,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NoteEditScreen(existing: t)),
                  ),
                )),
          const SizedBox(height: 24),

          const _SectionHeader(title: 'Bills', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 8),
          if (urgentBills.isEmpty)
            const _EmptyHint(text: 'No unpaid bills due soon.')
          else
            ...urgentBills.map((b) => _SimpleRow(
                  leading: const Icon(Icons.receipt_rounded, size: 18, color: Colors.redAccent),
                  title: b.name,
                  trailing: '${b.amount.toStringAsFixed(2)} RON',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BillEditScreen(existing: b)),
                  ),
                )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// O linie minimala - o iconita, titlul, si optional ceva la final (ex. o
/// suma) - folosita pentru listele Tasks si Bills de pe Dashboard. Click
/// pe ea deschide item-ul in ecranul lui complet de editare.
class _SimpleRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _SimpleRow({
    required this.leading,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
