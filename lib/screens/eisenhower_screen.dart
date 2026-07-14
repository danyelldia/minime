import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/note_task.dart';
import '../providers/note_task_provider.dart';
import '../providers/priority_tag_provider.dart';
import '../widgets/note_card.dart';
import 'note_edit_screen.dart';

/// Eisenhower Matrix view: buckets pending to-dos into 4 quadrants based
/// on the isUrgent / isImportant flags set on each task (edit a task to
/// mark it). An alternative to the plain list view for people who think
/// in "urgent vs important" terms.
class EisenhowerScreen extends StatelessWidget {
  const EisenhowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final taskProvider = context.watch<NoteTaskProvider>();
    final tagProvider = context.watch<PriorityTagProvider>();
    final todos = taskProvider.pendingTodos;

    final doFirst = todos.where((t) => t.isUrgent && t.isImportant).toList();
    final schedule = todos.where((t) => !t.isUrgent && t.isImportant).toList();
    final delegate = todos.where((t) => t.isUrgent && !t.isImportant).toList();
    final eliminate = todos.where((t) => !t.isUrgent && !t.isImportant).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eisenhowerTitle)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
        children: [
          _Quadrant(
            title: l10n.eisenhowerDoFirst,
            subtitle: l10n.eisenhowerDoFirstSub,
            color: Colors.red,
            tasks: doFirst,
            tagProvider: tagProvider,
            taskProvider: taskProvider,
          ),
          _Quadrant(
            title: l10n.eisenhowerSchedule,
            subtitle: l10n.eisenhowerScheduleSub,
            color: Colors.blue,
            tasks: schedule,
            tagProvider: tagProvider,
            taskProvider: taskProvider,
          ),
          _Quadrant(
            title: l10n.eisenhowerDelegate,
            subtitle: l10n.eisenhowerDelegateSub,
            color: Colors.orange,
            tasks: delegate,
            tagProvider: tagProvider,
            taskProvider: taskProvider,
          ),
          _Quadrant(
            title: l10n.eisenhowerEliminate,
            subtitle: l10n.eisenhowerEliminateSub,
            color: Colors.grey,
            tasks: eliminate,
            tagProvider: tagProvider,
            taskProvider: taskProvider,
          ),
        ],
      ),
    );
  }
}

class _Quadrant extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<NoteTask> tasks;
  final PriorityTagProvider tagProvider;
  final NoteTaskProvider taskProvider;

  const _Quadrant({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tasks,
    required this.tagProvider,
    required this.taskProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('-', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return NoteTaskCard(
                        task: task,
                        priorityTag: tagProvider.byId(task.priorityTagId),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NoteEditScreen(existing: task)),
                        ),
                        onToggleDone: () => taskProvider.toggleDone(task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
