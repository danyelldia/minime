import 'dart:async';

import 'package:flutter/services.dart';

/// Thin wrapper around a MethodChannel implemented natively in
/// MainActivity.kt (see native/tts_alarm/*). Schedules a Kotlin-only
/// alarm (via AlarmManager) that speaks a task's title aloud when it
/// fires, independent of the Dart/Flutter engine - so it still works
/// even if the app process has been killed. Runs alongside the regular
/// flutter_local_notifications banner+sound, giving a "beep + spoken
/// title" reminder without needing a "listen" button.
///
/// Also relays two things the native side reports back over the same
/// channel: which task id (if any) MiniMe should open right now because
/// the user tapped a reminder notification's body (see onOpenTask /
/// getInitialOpenTaskId), used to deep-link straight into that task's
/// edit screen instead of just opening the app.
class TtsAlarmService {
  TtsAlarmService._() {
    _channel.setMethodCallHandler(_onMethodCall);
  }
  static final TtsAlarmService instance = TtsAlarmService._();

  static const MethodChannel _channel = MethodChannel('com.danyell.minime/tts_alarm');

  final StreamController<String> _openTaskController = StreamController<String>.broadcast();

  /// Emits a taskId whenever the user taps a reminder notification's body
  /// while the app is already running (native onNewIntent).
  Stream<String> get onOpenTask => _openTaskController.stream;

  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'onOpenTask') {
      final taskId = (call.arguments as Map?)?['taskId'] as String?;
      if (taskId != null && taskId.isNotEmpty) {
        _openTaskController.add(taskId);
      }
    }
  }

  /// Reads the taskId (if any) the app was cold-launched with, because the
  /// user tapped a reminder notification's body instead of just opening
  /// the app icon. Returns null for a normal launch.
  Future<String?> getInitialOpenTaskId() async {
    try {
      final result = await _channel.invokeMethod<String>('getInitialOpenTaskId');
      return (result != null && result.isNotEmpty) ? result : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String message,
    required DateTime when,
    String? taskId,
    bool voiceEnabled = true,
  }) async {
    try {
      await _channel.invokeMethod('scheduleTtsAlarm', {
        'id': id,
        'title': title,
        'message': message,
        'triggerAtMillis': when.millisecondsSinceEpoch,
        'taskId': taskId,
        'voiceEnabled': voiceEnabled,
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
