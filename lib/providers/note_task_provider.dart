import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/note_task.dart';

/// Gestioneaza notitele si to-do-urile: incarcare, adaugare, editare,
/// stergere si marcare Done/Not Done.
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

  Future<void> addTask(NoteTask task) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('note_tasks', task.toMap());
    _tasks.insert(0, task);
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
    notifyListeners();
  }

  /// Comuta starea Done <-> Not Done si seteaza/curata completedAt.
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
  }
}
