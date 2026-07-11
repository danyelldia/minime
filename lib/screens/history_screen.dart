import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_entry.dart';
import '../providers/history_provider.dart';
import '../providers/note_task_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  String _actionLabel(HistoryAction a) {
    switch (a) {
      case HistoryAction.created:
        return 'Created';
      case HistoryAction.done:
        return 'Marked Done';
      case HistoryAction.snoozed:
        return 'Snoozed';
      case HistoryAction.notToday:
        return 'Not Today';
      case HistoryAction.movedTomorrow:
        return 'Moved to tomorrow';
    }
  }

  IconData _actionIcon(HistoryAction a) {
    switch (a) {
      case HistoryAction.created:
        return Icons.add_circle_outline_rounded;
      case HistoryAction.done:
        return Icons.check_circle_rounded;
      case HistoryAction.snoozed:
        return Icons.snooze_rounded;
      case HistoryAction.notToday:
        return Icons.block_rounded;
      case HistoryAction.movedTomorrow:
        return Icons.arrow_forward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final taskProvider = context.watch<NoteTaskProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: history.entries.isEmpty
          ? const Center(child: Text('No events yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.entries.length,
              itemBuilder: (context, index) {
                final entry = history.entries[index];
                var taskTitle = 'Deleted task';
                for (final t in taskProvider.tasks) {
                  if (t.id == entry.noteTaskId) {
                    taskTitle = t.title;
                    break;
                  }
                }
                final snoozeText = entry.snoozeMinutes != null ? ' (${entry.snoozeMinutes} min)' : '';
                final ts = entry.timestamp;
                final timeText = '${ts.day}/${ts.month} '
                    '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  leading: Icon(_actionIcon(entry.action)),
                  title: Text(taskTitle),
                  subtitle: Text('${_actionLabel(entry.action)}$snoozeText - $timeText'),
                );
              },
            ),
    );
  }
}
