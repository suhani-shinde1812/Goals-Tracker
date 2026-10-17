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
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) => _buildTaskList(ref, tasks.isEmpty ? ApiService.getOfflineTasks(selectedDate) : tasks),
        loading: () => _buildTaskList(ref, ApiService.getOfflineTasks(selectedDate)),
        error: (_, __) => _buildTaskList(ref, ApiService.getOfflineTasks(selectedDate)),
      ),
    );
  }

  Widget _buildTaskList(WidgetRef ref, List<ScheduledTaskModel> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: CheckboxListTile(
            value: task.isCompleted,
            onChanged: (_) {
              ref.read(tasksProvider.notifier).toggleTask(task.id);
              ref.refresh(dashboardProvider);
            },
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600,
                color: task.isCompleted ? AppTheme.textLight : AppTheme.textMain,
              ),
            ),
            subtitle: Text('${task.scheduledTime ?? "Anytime"} • ${task.category}'),
          ),
        );
      },
    );
  }
}
