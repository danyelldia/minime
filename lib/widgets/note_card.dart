import 'package:flutter/material.dart';

import '../models/note_task.dart';
import '../models/priority_tag.dart';

class NoteTaskCard extends StatelessWidget {
  final NoteTask task;
  final PriorityTag? priorityTag;
  final VoidCallback onTap;
  final VoidCallback? onToggleDone;

  const NoteTaskCard({
    super.key,
    required this.task,
    required this.priorityTag,
    required this.onTap,
    this.onToggleDone,
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
                            Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isDone ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.w600,
                              ),
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
                                    label: Text('${task.durationMinutes} min', style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ],
                        ),
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
}
