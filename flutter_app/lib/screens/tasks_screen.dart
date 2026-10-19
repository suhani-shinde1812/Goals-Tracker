import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '08:00 - 09:00');
    final durationController = TextEditingController(text: '60');
    String selectedCategory = 'Health';
    String selectedPriority = 'high';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Custom Goal / Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task / Goal Title',
                  hintText: 'e.g., Morning Yoga, Practice DSA, Client Meeting',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task_alt),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Scheduled Time',
                        hintText: 'e.g. 07:00 - 08:00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (min)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Health', child: Text('Health')),
                        DropdownMenuItem(value: 'Study', child: Text('Study')),
                        DropdownMenuItem(value: 'Work', child: Text('Work')),
                        DropdownMenuItem(value: 'Wellness', child: Text('Wellness')),
                        DropdownMenuItem(value: 'GATE', child: Text('GATE')),
                        DropdownMenuItem(value: 'Placement', child: Text('Placement')),
                        DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedPriority = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  final time = timeController.text.trim();
                  final duration = int.tryParse(durationController.text.trim()) ?? 30;

                  await ref.read(tasksProvider.notifier).addTask(
                    title,
                    time,
                    selectedCategory,
                    duration,
                    selectedPriority,
                  );
                  ref.refresh(dashboardProvider);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added task "$title" at $time!')),
                    );
                  }
                },
                icon: const Icon(Icons.add_task),
                label: const Text('Add to Today\'s Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, WidgetRef ref, ScheduledTaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${task.title}" from your schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(tasksProvider.notifier).deleteTask(task.id);
              ref.refresh(dashboardProvider);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed "${task.title}"')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Routine & Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom Task',
            onPressed: () => _showAddTaskSheet(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'reset') {
                await ref.read(tasksProvider.notifier).resetToDefault();
                ref.refresh(dashboardProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset to default template schedule')),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reset', child: Text('Reset to Default Routine')),
            ],
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showAddTaskSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: tasksAsync.when(
        data: (tasks) => _buildTaskList(context, ref, tasks, selectedDate),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildTaskList(context, ref, ApiService.getOfflineTasks(selectedDate), selectedDate),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref, List<ScheduledTaskModel> tasks, String selectedDate) {
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final pct = totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
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

        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text(
                'No tasks scheduled for today.\nTap "+ Add Task" below to create custom goals!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ),
          ),

        // Task Items
        for (var task in tasks)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (_) async {
                  await ref.read(tasksProvider.notifier).toggleTask(task.id);
                  ref.refresh(dashboardProvider);
                },
              ),
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
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                tooltip: 'Delete Task',
                onPressed: () => _confirmDeleteTask(context, ref, task),
              ),
            ),
          ),
      ],
    );
  }
}
