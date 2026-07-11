import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/note_task.dart';
import '../services/notification_service.dart';

/// Gestioneaza notitele si to-do-urile: incarcare, adaugare, editare,
/// stergere, marcare Done/Not Done - si logheaza in istoric evenimentele
/// relevante (creat, bifat Done).
class NoteTaskProvider extends ChangeNotifier {
  List<NoteTask> _tasks = [];

  List<NoteTask> get tasks => List.unmodifiable(_tasks);

  List<NoteTask> byCategory(String categoryId) =>
      _tasks.where((t) => t.categoryId == categoryId).toList();

  List<NoteTask> get pendingTodos =>
      _tasks.where((t) => t.type == ItemType.todo && !t.isDone).toList();

  List<NoteTask> get recentNotes {
    final notes = _tasks.where((t) => t.type == ItemType.note).toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('note_tasks', orderBy: 'createdAt DESC');
    _tasks = rows.map((r) => NoteTask.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> _logHistory(String taskId, String action) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('history_entries', {
      'id': 'h_${DateTime.now().microsecondsSinceEpoch}',
      'noteTaskId': taskId,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      'snoozeMinutes': null,
    });
  }

  Future<void> addTask(NoteTask task) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('note_tasks', task.toMap());
    _tasks.insert(0, task);
    await _logHistory(task.id, 'created');
    notifyListeners();
  }

  Future<void> updateTask(NoteTask task) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'note_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) _tasks[idx] = task;
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('note_tasks', where: 'id = ?', whereArgs: [id]);
    _tasks.removeWhere((t) => t.id == id);
    await NotificationService.instance.cancelReminder(id);
    notifyListeners();
  }

  /// Comuta starea Done <-> Not Done, seteaza/curata completedAt,
  /// anuleaza reminder-ul cand devine Done si logheaza in istoric.
  Future<void> toggleDone(NoteTask task) async {
    final newDone = !task.isDone;
    final updated = NoteTask(
      id: task.id,
      title: task.title,
      description: task.description,
      type: task.type,
      categoryId: task.categoryId,
      priorityTagId: task.priorityTagId,
      urgencyColor: task.urgencyColor,
      durationMinutes: task.durationMinutes,
      dueDate: task.dueDate,
      reminderTime: task.reminderTime,
      recurrenceRule: task.recurrenceRule,
      isDone: newDone,
      createdAt: task.createdAt,
      completedAt: newDone ? DateTime.now() : null,
      googleCalendarEventId: task.googleCalendarEventId,
    );
    await updateTask(updated);
    if (newDone) {
      await NotificationService.instance.cancelReminder(task.id);
      await _logHistory(task.id, 'done');
    }
  }
}
