import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/history_entry.dart';

/// Istoricul actiunilor pe remindere: creat, Done, Snooze, Not Today,
/// Move Tomorrow - populat atat din actiunile din aplicatie cat si din
/// actiunile apasate direct din notificare.
class HistoryProvider extends ChangeNotifier {
  List<HistoryEntry> _entries = [];

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('history_entries', orderBy: 'timestamp DESC');
    _entries = rows.map((r) => HistoryEntry.fromMap(r)).toList();
    notifyListeners();
  }
}
