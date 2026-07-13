import 'package:flutter/services.dart';

/// Thin wrapper around a MethodChannel implemented natively in
/// MainActivity.kt (see native/tts_alarm/*). Schedules a Kotlin-only
/// alarm (via AlarmManager) that speaks a task's title aloud when it
/// fires, independent of the Dart/Flutter engine - so it still works
/// even if the app process has been killed. Runs alongside the regular
/// flutter_local_notifications banner+sound, giving a "beep + spoken
/// title" reminder without needing a "listen" button.
class TtsAlarmService {
  TtsAlarmService._();
  static final TtsAlarmService instance = TtsAlarmService._();

  static const MethodChannel _channel = MethodChannel('com.danyell.minime/tts_alarm');

  Future<void> schedule({
    required int id,
    required String title,
    required String message,
    required DateTime when,
  }) async {
    try {
      await _channel.invokeMethod('scheduleTtsAlarm', {
        'id': id,
        'title': title,
        'message': message,
        'triggerAtMillis': when.millisecondsSinceEpoch,
      });
    } catch (e) {
      // Best-effort: the visual notification still works even if the
      // native TTS alarm can't be scheduled for some reason.
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _channel.invokeMethod('cancelTtsAlarm', {'id': id});
    } catch (e) {
      // ignore
    }
  }
}
