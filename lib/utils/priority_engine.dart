import '../models/note_task.dart';
import '../models/priority_tag.dart';

/// Rezultatul motorului de prioritizare zilnica.
class DailyPlan {
  final List<NoteTask> scheduled;
  final List<NoteTask> leftover;
  final List<NoteTask> noDuration;
  final int minutesUsed;

  const DailyPlan({
    required this.scheduled,
    required this.leftover,
    required this.noDuration,
    required this.minutesUsed,
  });
}

int _priorityRank(NoteTask task, List<PriorityTag> tags) {
  if (task.priorityTagId == null) return 99;
  PriorityTag? tag;
  for (final t in tags) {
    if (t.id == task.priorityTagId) {
      tag = t;
      break;
    }
  }
  if (tag == null) return 99;
  switch (tag.type) {
    case PriorityTagType.thisWeek:
      return 0;
    case PriorityTagType.thisMonth:
      return 1;
    case PriorityTagType.nextMonth:
      return 2;
    case PriorityTagType.thisYear:
      return 3;
    case PriorityTagType.custom:
      return 4;
  }
}

/// Calculeaza automat ce to-do-uri incap azi in functie de durata
/// disponibila (in minute), prioritizand dupa tag (this week > this month
/// > next month > this year > custom > fara tag), apoi dupa data limita
/// cea mai apropiata, apoi dupa durata cea mai scurta.
///
/// To-do-urile fara durata setata sunt separate intr-o lista proprie -
/// nu pot intra in calcul pana cand utilizatorul le seteaza o durata.
DailyPlan buildDailyPlan({
  required List<NoteTask> pendingTodos,
  required List<PriorityTag> tags,
  required int availableMinutes,
}) {
  final withDuration = pendingTodos.where((t) => t.durationMinutes != null).toList();
  final noDuration = pendingTodos.where((t) => t.durationMinutes == null).toList();

  withDuration.sort((a, b) {
    final rankA = _priorityRank(a, tags);
    final rankB = _priorityRank(b, tags);
    if (rankA != rankB) return rankA.compareTo(rankB);

    final dueA = a.dueDate;
    final dueB = b.dueDate;
    if (dueA != null && dueB != null) {
      final cmp = dueA.compareTo(dueB);
      if (cmp != 0) return cmp;
    } else if (dueA != null) {
      return -1;
    } else if (dueB != null) {
      return 1;
    }

    return a.durationMinutes!.compareTo(b.durationMinutes!);
  });

  final scheduled = <NoteTask>[];
  final leftover = <NoteTask>[];
  int used = 0;

  for (final task in withDuration) {
    final duration = task.durationMinutes!;
    if (used + duration <= availableMinutes) {
      scheduled.add(task);
      used += duration;
    } else {
      leftover.add(task);
    }
  }

  return DailyPlan(
    scheduled: scheduled,
    leftover: leftover,
    noDuration: noDuration,
    minutesUsed: used,
  );
}
