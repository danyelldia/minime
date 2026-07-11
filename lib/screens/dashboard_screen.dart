import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bill_provider.dart';
import '../providers/history_provider.dart';
import '../providers/note_task_provider.dart';
import '../providers/priority_tag_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/quick_add_sheet.dart';
import 'eisenhower_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<NoteTaskProvider>();
    final tagProvider = context.watch<PriorityTagProvider>();
    final billProvider = context.watch<BillProvider>();
    final history = context.watch<HistoryProvider>();
    final notes = taskProvider.recentNotes.take(5).toList();
    final todos = taskProvider.pendingTodos;
    final streak = history.currentStreak;

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
        child: const Icon(Icons.edit_note_rounded),
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
          const _SectionHeader(title: 'Quick Notes', icon: Icons.sticky_note_2_rounded),
          if (notes.isEmpty)
            const _EmptyHint(text: 'No notes yet. Tap + to add one.')
          else
            ...notes.map((n) => NoteTaskCard(
                  task: n,
                  priorityTag: tagProvider.byId(n.priorityTagId),
                  onTap: () {},
                )),
          const SizedBox(height: 24),
          _SectionHeader(title: 'To-Do (${todos.length} active)', icon: Icons.checklist_rounded),
          if (todos.isEmpty)
            const _EmptyHint(text: 'Nothing to do right now.')
          else
            ...todos.take(5).map((t) => NoteTaskCard(
                  task: t,
                  priorityTag: tagProvider.byId(t.priorityTagId),
                  onTap: () {},
                  onToggleDone: () => taskProvider.toggleDone(t),
                )),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Bills / Income / Shopping', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _MoneyRow(
                    label: 'Unpaid bills',
                    amount: billProvider.totalUnpaidBills,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _MoneyRow(
                    label: 'Expected income',
                    amount: billProvider.totalExpectedIncome,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _MoneyRow(
                    label: 'Shopping list cost',
                    amount: billProvider.totalShoppingCost,
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
          '${amount.toStringAsFixed(2)} RON',
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
