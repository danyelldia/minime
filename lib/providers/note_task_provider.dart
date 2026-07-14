import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/note_task.dart';
import '../services/notification_service.dart';

class NoteTaskProvider extends ChangeNotifier {
  List<NoteTask> _tasks = [];

  List<NoteTask> get tasks => List.unmodifiable(_tasks);

  /// Looks up a single task by id (e.g. for deep-linking straight into a
  /// task's edit screen from a tapped reminder notification). Returns
  /// null if it doesn't exist (deleted in the meantime, etc).
  NoteTask? byId(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Top-level items only (no subtasks) for a category, sorted by the
  /// user's custom drag-and-drop order, then by creation date.
  List<NoteTask> byCategory(String categoryId) {
    final list = _tasks.where((t) => t.categoryId == categoryId && !t.isSubtask).toList();
    list.sort((a, b) {
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  List<NoteTask> subtasksOf(String parentTaskId) {
    final list = _tasks.where((t) => t.parentTaskId == parentTaskId).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  int doneSubtasksCount(String parentTaskId) =>
      subtasksOf(parentTaskId).where((t) => t.isDone).length;

  List<NoteTask> get pendingTodos =>
      _tasks.where((t) => t.type == ItemType.todo && !t.isDone && !t.isSubtask).toList();

  List<NoteTask> get recentNotes {
    final notes = _tasks.where((t) => t.type == ItemType.note && !t.isSubtask).toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  List<NoteTask> get tasksWithLocation =>
      _tasks.where((t) => t.type == ItemType.todo && !t.isDone && t.hasLocation).toList();

  /// All distinct free-form tags currently in use, for filter chips.
  List<String> get allTags {
    final set = <String>{};
    for (final t in _tasks) {
      set.addAll(t.tags);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<NoteTask> byTag(String tag) =>
      _tasks.where((t) => t.tags.contains(tag) && !t.isSubtask).toList();

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
    await db.update('note_tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) _tasks[idx] = task;
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final db = await DatabaseHelper.instance.database;
    // cascade: delete subtasks of this task too
    final subIds = _tasks.where((t) => t.parentTaskId == id).map((t) => t.id).toList();
    for (final subId in subIds) {
      await db.delete('note_tasks', where: 'id = ?', whereArgs: [subId]);
      await NotificationService.instance.cancelReminder(subId);
    }
    await db.delete('note_tasks', where: 'id = ?', whereArgs: [id]);
    _tasks.removeWhere((t) => t.id == id || subIds.contains(t.id));
    await NotificationService.instance.cancelReminder(id);
    notifyListeners();
  }

  Future<void> toggleDone(NoteTask task) async {
    final newDone = !task.isDone;
    final updated = task.copyWith(isDone: newDone, completedAt: newDone ? DateTime.now() : null);
    // copyWith uses ?? so it can't null-out completedAt when un-checking;
    // build the object directly to allow that.
    final rebuilt = NoteTask(
      id: task.id,
      title: updated.title,
      description: updated.description,
      type: updated.type,
      categoryId: updated.categoryId,
      priorityTagId: updated.priorityTagId,
      urgencyColor: updated.urgencyColor,
      durationMinutes: updated.durationMinutes,
      durationUnit: updated.durationUnit,
      dueDate: updated.dueDate,
      reminderTime: updated.reminderTime,
      recurrenceRule: updated.recurrenceRule,
      isDone: newDone,
      createdAt: updated.createdAt,
      completedAt: newDone ? DateTime.now() : null,
      googleCalendarEventId: updated.googleCalendarEventId,
      parentTaskId: updated.parentTaskId,
      tags: updated.tags,
      isUrgent: updated.isUrgent,
      isImportant: updated.isImportant,
      sortOrder: updated.sortOrder,
      locationName: updated.locationName,
      locationLat: updated.locationLat,
      locationLng: updated.locationLng,
      locationRadius: updated.locationRadius,
      locationLastTriggeredDate: updated.locationLastTriggeredDate,
      voiceNotificationEnabled: updated.voiceNotificationEnabled,
    );
    await updateTask(rebuilt);
    if (newDone) {
      await NotificationService.instance.cancelReminder(task.id);
      await _logHistory(task.id, 'done');
    }
  }

  /// Persists a new drag-and-drop order for a list of tasks (all from the
  /// same category/context). Assigns sortOrder 0..n in list order.
  Future<void> reorder(List<NoteTask> orderedTasks) async {
    final db = await DatabaseHelper.instance.database;
    for (var i = 0; i < orderedTasks.length; i++) {
      final t = orderedTasks[i];
      if (t.sortOrder == i) continue;
      await db.update('note_tasks', {'sortOrder': i}, where: 'id = ?', whereArgs: [t.id]);
      final idx = _tasks.indexWhere((x) => x.id == t.id);
      if (idx != -1) _tasks[idx] = _tasks[idx].copyWith(sortOrder: i);
    }
    notifyListeners();
  }

  Future<void> markLocationTriggered(String taskId, String yyyyMmDd) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(locationLastTriggeredDate: yyyyMmDd);
    await updateTask(updated);
  }
}
