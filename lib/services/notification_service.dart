import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/database_helper.dart';
import '../models/note_task.dart';
import 'tts_alarm_service.dart';
import 'tts_service.dart';

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

/// Citeste numele userului direct din DB (fara Provider, ca acest serviciu
/// nu are BuildContext) - folosit ca sa personalizam mesajul vorbit.
Future<String> _userName() async {
  final db = await DatabaseHelper.instance.database;
  final rows = await db.query('user_profile', where: 'id = ?', whereArgs: ['me']);
  if (rows.isEmpty) return '';
  return (rows.first['name'] as String?)?.trim() ?? '';
}

/// Construieste fraza vorbita: nume (daca exista) + o formulare care
/// variaza dupa urgenta/importanta task-ului + titlul. Ex: "Daniel, this
/// is urgent, you must do: water the plants".
String composeSpokenMessage(NoteTask task, String name) {
  final String phrase;
  if (task.isUrgent) {
    phrase = 'this is urgent, you must do';
  } else if (task.isImportant) {
    phrase = 'you have an important task';
  } else {
    phrase = 'you have a task pending';
  }
  final namePart = name.trim().isEmpty ? '' : '${name.trim()}, ';
  return '$namePart$phrase: ${task.title}';
}

/// Programeaza si anuleaza notificari locale pentru to-do-uri, cu suport
/// pentru recurenta zilnica si actiuni: Done / Snooze 15m / Not azi / Maine.
///
/// Fiecare reminder programat porneste DOUA alarme in paralel, la aceeasi
/// ora: notificarea vizuala normala (cu sunetul standard de notificare) si
/// o alarma nativa separata (vezi tts_alarm_service.dart) care citeste cu
/// voce tare titlul task-ului, folosind motorul TextToSpeech al
/// telefonului direct din Kotlin - functioneaza chiar daca aplicatia a
/// fost inchisa complet, fara sa fie nevoie de niciun buton "asculta".
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
      try {
        // Android 12+ (API 31+): fara acest permis, alarmele "exacte" sunt
        // degradate silentios la "inexacte" de catre sistem, ceea ce poate
        // intarzia sau chiar sari peste un reminder programat la o ora
        // precisa. Cere permisiunea explicit (deschide ecranul de setari
        // daca nu e deja acordata).
        await androidPlugin?.requestExactAlarmsPermission();
      } catch (e) {
        // Nu toate versiunile de Android/plugin au aceasta metoda - ignora.
      }
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
        // Trateaza reminder-ul ca pe o alarma: apare peste ecranul de
        // blocare (nu doar "ascuns, deblocheaza ca sa vezi"), face heads-up
        // (peek) chiar daca telefonul e blocat, si porneste ecranul daca
        // era stins - la fel ca orice alarma standard de pe telefon.
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
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

    final body = (task.description != null && task.description!.isNotEmpty)
        ? task.description!
        : 'Reminder MiniMe';

    // IMPORTANT: pe multe telefoane (inclusiv ColorOS/Oppo) permisiunea de
    // "alarme exacte" nu e acordata automat pe Android 12+, iar in acel caz
    // zonedSchedule arunca o exceptie DIRECT AICI, inainte sa apuce sa
    // programeze ceva. Daca nu am prinde exceptia, ea s-ar propaga pana in
    // ecranul de Save (unde e apelat scheduleReminder), blocand navigarea
    // inapoi si dand impresia ca "nu s-a salvat" - iar userul care apasa
    // Save a doua oara ajunge sa creeze un task duplicat. De-aia incercam
    // intai exact, si daca esueaza cadem pe inexact, ca notificarea vizuala
    // sa apara oricum (poate cu o mica intarziere), fara sa stricam salvarea.
    try {
      await _plugin.zonedSchedule(
        id,
        task.title,
        body,
        scheduled,
        NotificationDetails(android: _androidDetails(), iOS: const DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: daily ? DateTimeComponents.time : null,
        payload: task.id,
      );
    } catch (e) {
      try {
        await _plugin.zonedSchedule(
          id,
          task.title,
          body,
          scheduled,
          NotificationDetails(android: _androidDetails(), iOS: const DarwinNotificationDetails()),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: daily ? DateTimeComponents.time : null,
          payload: task.id,
        );
      } catch (e2) {
        // Best-effort: chiar daca notificarea vizuala nu poate fi
        // programata deloc, alarma vocala nativa de mai jos tot va suna.
      }
    }

    // Recurenta zilnica nu se poate exprima direct pe alarma nativa (nu are
    // logica de "match time-of-day" ca zonedSchedule), asa ca pentru task-uri
    // DAILY programam doar urmatoarea aparitie; se reprogrameaza automat
    // maine cand notificarea vizuala e reafisata (vezi handleNotificationAction).
    final name = await _userName();
    final message = composeSpokenMessage(task, name);
    await TtsAlarmService.instance.schedule(
      id: id,
      title: task.title,
      message: message,
      when: scheduled,
    );
  }

  /// Fires an immediate (non-scheduled) notification for a location-based
  /// reminder - used by LocationService when the user enters range of a
  /// to-do's saved location. Aplicatia ruleaza deja in acest moment, asa
  /// ca citim task-ul cu voce tare direct prin flutter_tts, fara sa mai
  /// fie nevoie de alarma nativa.
  Future<void> showLocationReminder(NoteTask task) async {
    final id = _notificationIdFor('loc_${task.id}');
    try {
      await _plugin.show(
        id,
        'Near ${task.locationName ?? 'a saved place'}',
        task.title,
        NotificationDetails(android: _androidDetails(), iOS: const DarwinNotificationDetails()),
        payload: task.id,
      );
    } catch (e) {
      // best-effort - continua oricum cu vocea mai jos.
    }
    final name = await _userName();
    TtsService.instance.speak(composeSpokenMessage(task, name));
  }

  Future<void> cancelReminder(String taskId) async {
    final id = _notificationIdFor(taskId);
    try {
      await _plugin.cancel(id);
    } catch (e) {
      // best-effort
    }
    await TtsAlarmService.instance.cancel(id);
  }
}
