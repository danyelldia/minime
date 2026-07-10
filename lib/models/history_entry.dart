enum HistoryAction { created, done, snoozed, notToday, movedTomorrow }

/// Istoricul actiunilor pe un reminder/to-do: creat, bifat Done,
/// amanat (snooze), Not Today, sau mutat pe maine.
class HistoryEntry {
  final String id;
  final String noteTaskId;
  final HistoryAction action;
  final DateTime timestamp;
  final int? snoozeMinutes;

  const HistoryEntry({
    required this.id,
    required this.noteTaskId,
    required this.action,
    required this.timestamp,
    this.snoozeMinutes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'noteTaskId': noteTaskId,
        'action': action.name,
        'timestamp': timestamp.toIso8601String(),
        'snoozeMinutes': snoozeMinutes,
      };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
        id: map['id'] as String,
        noteTaskId: map['noteTaskId'] as String,
        action: HistoryAction.values.byName(map['action'] as String),
        timestamp: DateTime.parse(map['timestamp'] as String),
        snoozeMinutes: map['snoozeMinutes'] as int?,
      );
}
