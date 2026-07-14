import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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

  String _actionLabel(AppLocalizations l10n, HistoryAction a) {
    switch (a) {
      case HistoryAction.created:
        return l10n.historyActionCreated;
      case HistoryAction.done:
        return l10n.historyActionDone;
      case HistoryAction.snoozed:
        return l10n.historyActionSnoozed;
      case HistoryAction.notToday:
        return l10n.historyActionNotToday;
      case HistoryAction.movedTomorrow:
        return l10n.historyActionMovedTomorrow;
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
    final l10n = AppLocalizations.of(context)!;
    final history = context.watch<HistoryProvider>();
    final taskProvider = context.watch<NoteTaskProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: history.entries.isEmpty
          ? Center(child: Text(l10n.historyNoEvents))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.entries.length,
              itemBuilder: (context, index) {
                final entry = history.entries[index];
                var taskTitle = l10n.historyDeletedTask;
                for (final t in taskProvider.tasks) {
                  if (t.id == entry.noteTaskId) {
                    taskTitle = t.title;
                    break;
                  }
                }
                final snoozeText = entry.snoozeMinutes != null
                    ? l10n.historySnoozeMinutes(entry.snoozeMinutes!)
                    : '';
                final ts = entry.timestamp;
                final timeText = '${ts.day}/${ts.month} '
                    '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  leading: Icon(_actionIcon(entry.action)),
                  title: Text(taskTitle),
                  subtitle: Text(l10n.historyEntryLine(
                    _actionLabel(l10n, entry.action),
                    snoozeText,
                    timeText,
                  )),
                );
              },
            ),
    );
  }
}
