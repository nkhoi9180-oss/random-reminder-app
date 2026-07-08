import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;
  final ValueChanged<double> onProgressChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleDone,
    required this.onDelete,
    required this.onProgressChanged,
  });

  Color _priorityColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (task.priority) {
      case TaskPriority.high:
        return scheme.error;
      case TaskPriority.medium:
        return scheme.tertiary;
      case TaskPriority.low:
        return scheme.outline;
    }
  }

  String _priorityLabel() {
    switch (task.priority) {
      case TaskPriority.high:
        return 'Cao';
      case TaskPriority.medium:
        return 'Trung bình';
      case TaskPriority.low:
        return 'Thấp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: task.isDone,
                      onChanged: (_) => onToggleDone(),
                      shape: const CircleBorder(),
                    ),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isDone
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    if (task.isImportant)
                      Icon(Icons.star_rounded, color: scheme.tertiary, size: 20),
                  ],
                ),
                if (task.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 44, top: 2),
                    child: Text(
                      task.note,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(task.category, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      Chip(
                        label: Text(_priorityLabel(), style: const TextStyle(fontSize: 12)),
                        avatar: CircleAvatar(backgroundColor: _priorityColor(context), radius: 5),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      if (task.notificationEnabled)
                        Icon(Icons.notifications_active_outlined,
                            size: 16, color: scheme.primary),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 10, right: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          ),
                          child: Slider(
                            value: task.progress.toDouble().clamp(0, 100),
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${task.progress}%',
                            onChanged: onProgressChanged,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text('${task.progress}%',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
