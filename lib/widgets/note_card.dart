import 'package:flutter/material.dart';

import '../models/note_task.dart';
import '../models/priority_tag.dart';
import '../services/tts_service.dart';

class NoteTaskCard extends StatelessWidget {
  final NoteTask task;
  final PriorityTag? priorityTag;
  final VoidCallback onTap;
  final VoidCallback? onToggleDone;
  final int subtaskDone;
  final int subtaskTotal;

  const NoteTaskCard({
    super.key,
    required this.task,
    required this.priorityTag,
    required this.onTap,
    this.onToggleDone,
    this.subtaskDone = 0,
    this.subtaskTotal = 0,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = task.urgencyColor != null ? Color(task.urgencyColor!) : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: urgency ?? priorityTag?.color ?? Colors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (task.type == ItemType.todo)
                        Checkbox(
                          value: task.isDone,
                          onChanged: onToggleDone != null ? (_) => onToggleDone!() : null,
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (task.isUrgent)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.bolt_rounded, size: 16, color: Colors.orange),
                                  ),
                                if (task.isImportant)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                  ),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (task.description != null && task.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  task.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            if (subtaskTotal > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '$subtaskDone/$subtaskTotal subtasks done',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (priorityTag != null)
                                  Chip(
                                    label: Text(priorityTag!.label, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: priorityTag!.color.withOpacity(0.15),
                                    labelStyle: TextStyle(color: priorityTag!.color),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (task.durationMinutes != null)
                                  Chip(
                                    avatar: const Icon(Icons.schedule, size: 14),
                                    label: Text(_durationLabel(task), style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (task.reminderTime != null)
                                  Chip(
                                    avatar: const Icon(Icons.notifications_active_rounded, size: 14),
                                    label: Text(
                                      '${task.reminderTime!.hour.toString().padLeft(2, '0')}:'
                                      '${task.reminderTime!.minute.toString().padLeft(2, '0')}'
                                      '${task.recurrenceRule == 'DAILY' ? ' daily' : ''}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (task.hasLocation)
                                  Chip(
                                    avatar: const Icon(Icons.place_rounded, size: 14),
                                    label: Text(
                                      task.locationName?.isNotEmpty == true
                                          ? task.locationName!
                                          : 'Place',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ...task.tags.map((t) => Chip(
                                      label: Text(t, style: const TextStyle(fontSize: 11)),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, size: 20),
                        tooltip: 'Read aloud',
                        onPressed: () {
                          final text = task.description != null && task.description!.isNotEmpty
                              ? '${task.title}. ${task.description}'
                              : task.title;
                          TtsService.instance.speak(text);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _durationLabel(NoteTask task) {
    final minutes = task.durationMinutes!;
    final unit = task.durationUnit ?? 'min';
    final display = minutesToDisplay(minutes, unit);
    final rounded = display == display.roundToDouble() ? display.toInt().toString() : display.toStringAsFixed(1);
    switch (unit) {
      case 'day':
        return '$rounded d';
      case 'hour':
        return '$rounded h';
      default:
        return '$rounded min';
    }
  }
}
