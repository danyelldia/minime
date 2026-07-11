import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/note_task.dart';
import '../providers/bill_provider.dart';
import '../providers/note_task_provider.dart';
import '../providers/priority_tag_provider.dart';
import '../widgets/note_card.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _quickAddNote(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notita rapida'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Scrie ceva...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuleaza')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final task = NoteTask(
                id: const Uuid().v4(),
                title: text,
                type: ItemType.note,
                categoryId: 'personal',
                createdAt: DateTime.now(),
              );
              context.read<NoteTaskProvider>().addTask(task);
              Navigator.pop(ctx);
            },
            child: const Text('Salveaza'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<NoteTaskProvider>();
    final tagProvider = context.watch<PriorityTagProvider>();
    final billProvider = context.watch<BillProvider>();
    final notes = taskProvider.recentNotes.take(5).toList();
    final todos = taskProvider.pendingTodos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniMe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Istoric',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _quickAddNote(context),
        child: const Icon(Icons.edit_note_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'Quick Notes', icon: Icons.sticky_note_2_rounded),
          if (notes.isEmpty)
            const _EmptyHint(text: 'Nicio notita inca. Apasa + ca sa adaugi una.')
          else
            ...notes.map((n) => NoteTaskCard(
                  task: n,
                  priorityTag: tagProvider.byId(n.priorityTagId),
                  onTap: () {},
                )),
          const SizedBox(height: 24),
          _SectionHeader(title: 'To-Do (${todos.length} active)', icon: Icons.checklist_rounded),
          if (todos.isEmpty)
            const _EmptyHint(text: 'Nimic de facut momentan.')
          else
            ...todos.take(5).map((t) => NoteTaskCard(
                  task: t,
                  priorityTag: tagProvider.byId(t.priorityTagId),
                  onTap: () {},
                  onToggleDone: () => taskProvider.toggleDone(t),
                )),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Bills / Income / Wanted', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _MoneyRow(
                    label: 'Facturi neplatite',
                    amount: billProvider.totalUnpaidBills,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _MoneyRow(
                    label: 'Venituri asteptate',
                    amount: billProvider.totalExpectedIncome,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _MoneyRow(
                    label: 'Cost lucruri dorite',
                    amount: billProvider.totalWantedCost,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _MoneyRow({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '${amount.toStringAsFixed(2)} lei',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
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
