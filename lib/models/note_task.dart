enum ItemType { note, todo }

/// A note or a to-do. Belongs to a category/subcategory, can have a
/// priority tag, its own urgency color, an estimated duration (used by
/// the daily prioritization engine), free-form tags, an optional parent
/// task (for subtasks), an optional location reminder, and a scheduled
/// reminder (used by the notification system).
class NoteTask {
  final String id;
  final String title;
  final String? description;
  final ItemType type;
  final String categoryId;
  final String? priorityTagId;
  final int? urgencyColor; // ARGB color code, chosen manually by the user
  final int? durationMinutes; // canonical total, always stored in minutes
  final String? durationUnit; // 'min' | 'hour' | 'day' - display hint only
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final String? recurrenceRule; // e.g. 'DAILY', null = one-off
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? googleCalendarEventId;
  final String? parentTaskId; // non-null => this is a subtask
  final List<String> tags; // free-form tags, in addition to categories
  final bool isUrgent;
  final bool isImportant;
  final int sortOrder;
  final String? locationName;
  final double? locationLat;
  final double? locationLng;
  final double? locationRadius; // meters
  final String? locationLastTriggeredDate; // yyyy-MM-dd, avoids repeat spam
  final bool voiceNotificationEnabled; // spoken TTS reminder on/off per task

  const NoteTask({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.categoryId,
    this.priorityTagId,
    this.urgencyColor,
    this.durationMinutes,
    this.durationUnit,
    this.dueDate,
    this.reminderTime,
    this.recurrenceRule,
    this.isDone = false,
    required this.createdAt,
    this.completedAt,
    this.googleCalendarEventId,
    this.parentTaskId,
    this.tags = const [],
    this.isUrgent = false,
    this.isImportant = false,
    this.sortOrder = 0,
    this.locationName,
    this.locationLat,
    this.locationLng,
    this.locationRadius,
    this.locationLastTriggeredDate,
    this.voiceNotificationEnabled = true,
  });

  bool get isSubtask => parentTaskId != null;
  bool get hasLocation => locationLat != null && locationLng != null;

  NoteTask copyWith({
    String? title,
    String? description,
    ItemType? type,
    String? categoryId,
    String? priorityTagId,
    int? urgencyColor,
    int? durationMinutes,
    String? durationUnit,
    DateTime? dueDate,
    DateTime? reminderTime,
    String? recurrenceRule,
    bool? isDone,
    DateTime? completedAt,
    String? googleCalendarEventId,
    String? parentTaskId,
    List<String>? tags,
    bool? isUrgent,
    bool? isImportant,
    int? sortOrder,
    String? locationName,
    double? locationLat,
    double? locationLng,
    double? locationRadius,
    String? locationLastTriggeredDate,
    bool? voiceNotificationEnabled,
  }) {
    return NoteTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      priorityTagId: priorityTagId ?? this.priorityTagId,
      urgencyColor: urgencyColor ?? this.urgencyColor,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      durationUnit: durationUnit ?? this.durationUnit,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      tags: tags ?? this.tags,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      sortOrder: sortOrder ?? this.sortOrder,
      locationName: locationName ?? this.locationName,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationRadius: locationRadius ?? this.locationRadius,
      locationLastTriggeredDate: locationLastTriggeredDate ?? this.locationLastTriggeredDate,
      voiceNotificationEnabled: voiceNotificationEnabled ?? this.voiceNotificationEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'categoryId': categoryId,
        'priorityTagId': priorityTagId,
        'urgencyColor': urgencyColor,
        'durationMinutes': durationMinutes,
        'durationUnit': durationUnit,
        'dueDate': dueDate?.toIso8601String(),
        'reminderTime': reminderTime?.toIso8601String(),
        'recurrenceRule': recurrenceRule,
        'isDone': isDone ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'googleCalendarEventId': googleCalendarEventId,
        'parentTaskId': parentTaskId,
        'tags': tags.isEmpty ? null : tags.join(','),
        'isUrgent': isUrgent ? 1 : 0,
        'isImportant': isImportant ? 1 : 0,
        'sortOrder': sortOrder,
        'locationName': locationName,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'locationRadius': locationRadius,
        'locationLastTriggeredDate': locationLastTriggeredDate,
        'voiceNotificationEnabled': voiceNotificationEnabled ? 1 : 0,
      };

  factory NoteTask.fromMap(Map<String, dynamic> map) => NoteTask(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        type: ItemType.values.byName(map['type'] as String),
        categoryId: map['categoryId'] as String,
        priorityTagId: map['priorityTagId'] as String?,
        urgencyColor: map['urgencyColor'] as int?,
        durationMinutes: map['durationMinutes'] as int?,
        durationUnit: map['durationUnit'] as String?,
        dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
        reminderTime: map['reminderTime'] != null ? DateTime.parse(map['reminderTime'] as String) : null,
        recurrenceRule: map['recurrenceRule'] as String?,
        isDone: (map['isDone'] as int) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
        completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
        googleCalendarEventId: map['googleCalendarEventId'] as String?,
        parentTaskId: map['parentTaskId'] as String?,
        tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? const [],
        isUrgent: ((map['isUrgent'] as int?) ?? 0) == 1,
        isImportant: ((map['isImportant'] as int?) ?? 0) == 1,
        sortOrder: (map['sortOrder'] as int?) ?? 0,
        locationName: map['locationName'] as String?,
        locationLat: (map['locationLat'] as num?)?.toDouble(),
        locationLng: (map['locationLng'] as num?)?.toDouble(),
        locationRadius: (map['locationRadius'] as num?)?.toDouble(),
        locationLastTriggeredDate: map['locationLastTriggeredDate'] as String?,
        voiceNotificationEnabled: ((map['voiceNotificationEnabled'] as int?) ?? 1) == 1,
      );
}

/// Converts a value expressed in the given unit ('min' | 'hour' | 'day')
/// into total minutes, for storage.
int durationToMinutes(num value, String unit) {
  switch (unit) {
    case 'day':
      return (value * 60 * 24).round();
    case 'hour':
      return (value * 60).round();
    case 'min':
    default:
      return value.round();
  }
}

/// Converts total minutes back into a display value for the given unit.
double minutesToDisplay(int minutes, String unit) {
  switch (unit) {
    case 'day':
      return minutes / (60 * 24);
    case 'hour':
      return minutes / 60;
    case 'min':
    default:
      return minutes.toDouble();
  }
}
