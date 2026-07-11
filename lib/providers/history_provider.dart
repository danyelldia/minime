import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/history_entry.dart';

/// History of reminder actions: created, Done, Snooze, Not Today,
/// Move Tomorrow - populated both from in-app actions and from actions
/// tapped directly on a notification. Also computes the current daily
/// streak (consecutive days with at least one completed task).
class HistoryProvider extends ChangeNotifier {
  List<HistoryEntry> _entries = [];

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('history_entries', orderBy: 'timestamp DESC');
    _entries = rows.map((r) => HistoryEntry.fromMap(r)).toList();
    notifyListeners();
  }

  /// Number of consecutive days (ending today or yesterday) that have at
  /// least one 'done' entry. If today has no completions yet, the streak
  /// still counts as active as long as yesterday had one (so it doesn't
  /// reset to 0 first thing in the morning).
  int get currentStreak {
    final doneDates = <DateTime>{};
    for (final e in _entries) {
      if (e.action == HistoryAction.done) {
        final d = e.timestamp;
        doneDates.add(DateTime(d.year, d.month, d.day));
      }
    }
    if (doneDates.isEmpty) return 0;

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!doneDates.contains(cursor)) {
      // no completion yet today - start checking from yesterday instead
      cursor = cursor.subtract(const Duration(days: 1));
      if (!doneDates.contains(cursor)) return 0;
    }

    var streak = 0;
    while (doneDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
