import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/database_helper.dart';
import '../models/note_task.dart';

const String _channelId = 'minime_reminders';
const String _channelName = 'MiniMe - Remindere';
const String _channelDesc = 'Notificari pentru to-do-uri si remindere MiniMe';

const String actionDone = 'done';
const String actionSnooze = 'snooze15';
const String actionNotToday = 'not_today';
const String actionMoveTomorrow = 'move_tomorrow';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

/// Handler pentru actiunile din notificare (Done / Snooze / Not Today /
/// Move Tomorrow) - trebuie sa fie o functie top-level sau statica, pentru
/// ca poate rula intr-un isolate separat cand aplicatia e inchisa complet.
/// De-aia interactioneaza direct cu baza de date (nu prin Provider).
@pragma('vm:entry-point')
void notificationActionBackgroundHandler(NotificationResponse response) {
  handleNotificationAction(response.actionId, response.payload);
}

Future<void> handleNotificationAction(String? actionId, String? taskId) async {
  if (taskId == null) return;
  final db = await DatabaseHelper.instance.database;
  final rows = await db.query('note_tasks', where: 'id = ?', whereArgs: [taskId]);
  if (rows.isEmpty) return;
  final task = NoteTask.fromMap(rows.first);

  switch (actionId) {
    case actionDone:
      final map = task.toMap();
      map['isDone'] = 1;
      map['completedAt'] = DateTime.now().toIso8601String();
      await db.update('note_tasks', map, where: 'id = ?', whereArgs: [taskId]);
      await _logHistory(taskId, 'done');
      await NotificationService.instance.cancelReminder(taskId);
      break;
    case actionSnooze:
      final newTime = DateTime.now().add(const Duration(minutes: 15));
      await NotificationService.instance.scheduleOneOffAt(task, newTime);
      await _logHistory(taskId, 'snoozed', snoozeMinutes: 15);
      break;
    case actionNotToday:
      await _logHistory(taskId, 'notToday');
      break;
    case actionMoveTomorrow:
      final base = task.reminderTime ?? DateTime.now();
      final tomorrow = base.add(const Duration(days: 1));
      await NotificationService.instance.scheduleOneOffAt(task, tomorrow);
      await _logHistory(taskId, 'movedTomorrow');
      break;
    default:
      // tap simplu pe notificare (fara actiune specifica) - nu facem nimic special aici,
      // aplicatia se deschide normal.
      break;
  }
}

Future<void> _logHistory(String taskId, String action, {int? snoozeMinutes}) async {
  final db = await DatabaseHelper.instance.database;
  await db.insert('history_entries', {
    'id': 'h_${DateTime.now().microsecondsSinceEpoch}',
    'noteTaskId': taskId,
    'action': action,
    'timestamp': DateTime.now().toIso8601String(),
    'snoozeMinutes': snoozeMinutes,
  });
}

/// Programeaza si anuleaza notificari locale pentru to-do-uri, cu suport
/// pentru recurenta zilnica si actiuni: Done / Snooze 15m / Not azi / Maine.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) =>
          handleNotificationAction(response.actionId, response.payload),
      onDidReceiveBackgroundNotificationResponse: notificationActionBackgroundHandler,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
      ));
    }

    _initialized = true;
  }

  int _notificationIdFor(String taskId) => taskId.hashCode & 0x7fffffff;

  AndroidNotificationDetails _androidDetails() => const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(actionDone, 'Done'),
          AndroidNotificationAction(actionSnooze, 'Snooze 15m'),
          AndroidNotificationAction(actionNotToday, 'Not azi'),
          AndroidNotificationAction(actionMoveTomorrow, 'Maine'),
        ],
      );

  /// Programeaza reminder-ul unui task in functie de reminderTime si
  /// recurrenceRule ('DAILY' = se repeta zilnic la aceeasi ora).
  Future<void> scheduleReminder(NoteTask task) async {
    await cancelReminder(task.id);
    final reminderTime = task.reminderTime;
    if (reminderTime == null) return;

    final isDaily = task.recurrenceRule == 'DAILY';
    await _scheduleAt(task, reminderTime, daily: isDaily);
  }

  /// Reprogrameaza o singura data (folosit de Snooze / Move Tomorrow),
  /// fara sa afecteze recurenta de baza a task-ului.
  Future<void> scheduleOneOffAt(NoteTask task, DateTime when) async {
    await _scheduleAt(task, when, daily: false);
  }

  Future<void> _scheduleAt(NoteTask task, DateTime when, {required bool daily}) async {
    final id = _notificationIdFor(task.id);
    var scheduled = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(now)) {
      scheduled = daily ? scheduled.add(const Duration(days: 1)) : now.add(const Duration(minutes: 1));
    }

    await _plugin.zonedSchedule(
      id,
      task.title,
      (task.description != null && task.description!.isNotEmpty)
          ? task.description!
          : 'Reminder MiniMe',
      scheduled,
      NotificationDetails(android: _androidDetails(), iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: daily ? DateTimeComponents.time : null,
      payload: task.id,
    );
  }

  Future<void> cancelReminder(String taskId) async {
    await _plugin.cancel(_notificationIdFor(taskId));
  }
}
