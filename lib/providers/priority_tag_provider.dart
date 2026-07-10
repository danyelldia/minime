import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/priority_tag.dart';

/// Gestioneaza tag-urile de prioritizare: cele implicite (seed-uite la
/// crearea bazei de date) plus orice tag custom adaugat de utilizator.
class PriorityTagProvider extends ChangeNotifier {
  List<PriorityTag> _tags = [];

  List<PriorityTag> get tags => List.unmodifiable(_tags);

  PriorityTag? byId(String? id) {
    if (id == null) return null;
    for (final t in _tags) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('priority_tags');
    _tags = rows.map((r) => PriorityTag.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addCustomTag(String label, Color color) async {
    final db = await DatabaseHelper.instance.database;
    final tag = PriorityTag(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      color: color,
      type: PriorityTagType.custom,
    );
    await db.insert('priority_tags', tag.toMap());
    _tags.add(tag);
    notifyListeners();
  }
}
