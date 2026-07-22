import 'package:flutter/material.dart';

class GanttTask {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double progress; // 0.0 to 1.0
  final Color color;

  GanttTask({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.progress = 0.0,
    required this.color,
  });
}

class GanttChartWidget extends StatelessWidget {
  final List<GanttTask> tasks;
  final DateTime projectStartDate;
  final DateTime projectEndDate;
  final double dayWidth;

  const GanttChartWidget({
    super.key,
    required this.tasks,
    required this.projectStartDate,
    required this.projectEndDate,
    this.dayWidth = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final int totalDays = projectEndDate.difference(projectStartDate).inDays + 1;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Timeline)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Task Name',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Container(
                  height: 40,
                  width: totalDays * dayWidth,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                  child: Stack(
                    children: List.generate(totalDays, (index) {
                      final currentDay = projectStartDate.add(Duration(days: index));
                      return Positioned(
                        left: index * dayWidth,
                        child: Container(
                          width: dayWidth,
                          alignment: Alignment.center,
                          child: Text(
                            '${currentDay.day}/${currentDay.month}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tasks
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasks.map((task) {
                    final startOffsetDays = task.startDate.difference(projectStartDate).inDays;
                    final durationDays = task.endDate.difference(task.startDate).inDays + 1;

                    return Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              task.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          width: totalDays * dayWidth,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Grid Lines
                              ...List.generate(totalDays, (index) {
                                return Positioned(
                                  left: index * dayWidth,
                                  child: Container(
                                    width: 1,
                                    height: 40,
                                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                );
                              }),
                              // Task Bar
                              if (startOffsetDays >= 0 && durationDays > 0)
                                Positioned(
                                  left: startOffsetDays * dayWidth + 2,
                                  top: 8,
                                  child: Container(
                                    height: 24,
                                    width: (durationDays * dayWidth) - 4,
                                    decoration: BoxDecoration(
                                      color: task.color.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: task.color),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: task.progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: task.color,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
