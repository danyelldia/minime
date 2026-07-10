enum ItemType { note, todo }

/// O notita sau un to-do. Apartine unei categorii/subcategorii,
/// poate avea un tag de prioritate, o culoare de urgenta proprie,
/// o durata estimata (folosita de motorul de prioritizare zilnica)
/// si un reminder programat (folosit de sistemul de notificari).
class NoteTask {
  final String id;
  final String title;
  final String? description;
  final ItemType type;
  final String categoryId;
  final String? priorityTagId;
  final int? urgencyColor; // ARGB - cod culoare separat, ales manual de user
  final int? durationMinutes;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final String? recurrenceRule; // ex: 'DAILY', 'WEEKLY:MON,WED,FRI', null = o singura data
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? googleCalendarEventId;

  const NoteTask({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.categoryId,
    this.priorityTagId,
    this.urgencyColor,
    this.durationMinutes,
    this.dueDate,
    this.reminderTime,
    this.recurrenceRule,
    this.isDone = false,
    required this.createdAt,
    this.completedAt,
    this.googleCalendarEventId,
  });

  NoteTask copyWith({
    String? title,
    String? description,
    ItemType? type,
    String? categoryId,
    String? priorityTagId,
    int? urgencyColor,
    int? durationMinutes,
    DateTime? dueDate,
    DateTime? reminderTime,
    String? recurrenceRule,
    bool? isDone,
    DateTime? completedAt,
    String? googleCalendarEventId,
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
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
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
        'dueDate': dueDate?.toIso8601String(),
        'reminderTime': reminderTime?.toIso8601String(),
        'recurrenceRule': recurrenceRule,
        'isDone': isDone ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'googleCalendarEventId': googleCalendarEventId,
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
        dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
        reminderTime: map['reminderTime'] != null ? DateTime.parse(map['reminderTime'] as String) : null,
        recurrenceRule: map['recurrenceRule'] as String?,
        isDone: (map['isDone'] as int) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
        completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
        googleCalendarEventId: map['googleCalendarEventId'] as String?,
      );
}
