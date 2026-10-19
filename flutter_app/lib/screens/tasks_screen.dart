import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Routine & Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.refresh(tasksProvider);
              ref.refresh(dashboardProvider);
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) => _buildTaskList(context, ref, tasks.isEmpty ? ApiService.getOfflineTasks(selectedDate) : tasks, selectedDate),
        loading: () => _buildTaskList(context, ref, ApiService.getOfflineTasks(selectedDate), selectedDate),
        error: (_, __) => _buildTaskList(context, ref, ApiService.getOfflineTasks(selectedDate), selectedDate),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref, List<ScheduledTaskModel> tasks, String selectedDate) {
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final pct = totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily Task Completion Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Everyday Tasks Completion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark)),
                  Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                ],
              ),
              const SizedBox(height: 4),
              Text('$completedCount of $totalCount completed for $selectedDate', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: totalCount > 0 ? (completedCount / totalCount) : 0,
                backgroundColor: Colors.white.withOpacity(0.6),
                color: AppTheme.primaryColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Task Items
        for (var task in tasks)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: CheckboxListTile(
              value: task.isCompleted,
              onChanged: (_) async {
                await ref.read(tasksProvider.notifier).toggleTask(task.id);
                ref.refresh(dashboardProvider);
              },
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                  color: task.isCompleted ? AppTheme.textLight : AppTheme.textMain,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${task.scheduledTime ?? "Anytime"} • ${task.category}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          ),
      ],
    );
  }
}
