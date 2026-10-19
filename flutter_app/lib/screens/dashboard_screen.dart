import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
                label: const Text('Add to Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
        content: Text('Remove "${task.title}" from your schedule?'),
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

  void _showManualWeightDialog(BuildContext context, WidgetRef ref, double currentWeight) {
    final controller = TextEditingController(text: currentWeight.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Today\'s Weight', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your current weight in kg:', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                suffixText: 'kg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale_rounded),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Target Weight: 56.0 kg', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 30 && val < 200) {
                await ApiService.setManualWeight(val);
                ref.refresh(dashboardProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Weight updated to $val kg!')),
                  );
                }
              }
            },
            child: const Text('Save Weight'),
          ),
        ],
      ),
    );
  }

  void _showPeriodDatePicker(BuildContext context, WidgetRef ref) async {
    final lastLogged = await ApiService.getLastPeriodDate();
    final initialDate = lastLogged != null ? DateTime.tryParse(lastLogged) ?? DateTime.now() : DateTime.now();

    if (!context.mounted) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'SELECT LAST PERIOD START DATE',
    );

    if (picked != null) {
      final dateStr = picked.toIso8601String().split('T')[0];
      await ApiService.setLastPeriodDate(dateStr);
      ref.refresh(dashboardProvider);
      if (context.mounted) {
        final days = DateTime.now().difference(picked).inDays;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Period start date set: $dateStr (Day $days of cycle)')),
        );
      }
    }
  }

  void _showMonthlyReportDialog(BuildContext context) async {
    final report = await ApiService.generateMonthlyReportText();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Progress Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: SelectableText(
                  report,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: report));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report copied to clipboard! Ready to paste or save.')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy / Export Report to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HerBloom',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Today: $selectedDate',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Task',
            onPressed: () => _showAddTaskSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Monthly Report',
            onPressed: () => _showMonthlyReportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.refresh(dashboardProvider);
              ref.refresh(tasksProvider);
            },
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (summary) => _buildDashboardContent(
          context,
          ref,
          summary ?? DashboardSummaryModel.defaultOffline(selectedDate),
          tasksAsync,
          selectedDate,
        ),
        loading: () => _buildDashboardContent(
          context,
          ref,
          DashboardSummaryModel.defaultOffline(selectedDate),
          tasksAsync,
          selectedDate,
        ),
        error: (_, __) => _buildDashboardContent(
          context,
          ref,
          DashboardSummaryModel.defaultOffline(selectedDate),
          tasksAsync,
          selectedDate,
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    DashboardSummaryModel summary,
    AsyncValue<List<ScheduledTaskModel>> tasksAsync,
    String selectedDate,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.welcomeMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Small habits. Better health. Bigger goals.',
                  style: TextStyle(fontSize: 13, color: AppTheme.primaryColor.withOpacity(0.9)),
                ),
                const SizedBox(height: 12),
                // Daily Task Percentage Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Tasks: ${summary.completedTasksToday}/${summary.totalTasksToday} Done',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    ),
                    Text(
                      '${summary.completionPercentage.round()}%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: summary.totalTasksToday > 0 ? (summary.completedTasksToday / summary.totalTasksToday) : 0,
                  backgroundColor: Colors.white.withOpacity(0.6),
                  color: AppTheme.primaryColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stat Cards Grid / Wrap
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard(
                context,
                title: 'Tasks Done',
                value: '${summary.completedTasksToday}/${summary.totalTasksToday}',
                sub: '${summary.completionPercentage.round()}% Completed',
                icon: Icons.checklist_rounded,
                color: AppTheme.accentMint,
              ),
              _buildStatCard(
                context,
                title: 'Hydration',
                value: '${summary.waterIntakeTodayMl} ml',
                sub: 'Target: ${summary.waterTargetMl} ml',
                icon: Icons.water_drop_rounded,
                color: AppTheme.accentBlue,
              ),
              _buildStatCard(
                context,
                title: 'Current Weight',
                value: '${summary.currentWeightKg.toStringAsFixed(1)} kg',
                sub: 'Target: 56.0 kg (Tap to edit)',
                icon: Icons.scale_rounded,
                color: AppTheme.accentWarm,
                onTap: () => _showManualWeightDialog(context, ref, summary.currentWeightKg),
              ),
              _buildStatCard(
                context,
                title: 'PCOD Cycle',
                value: summary.daysSinceLastPeriod != null ? 'Day ${summary.daysSinceLastPeriod}' : 'Set Date',
                sub: summary.daysSinceLastPeriod != null ? 'Since last period' : 'Tap to log start',
                icon: Icons.favorite_rounded,
                color: Colors.pink.shade400,
                onTap: () => _showPeriodDatePicker(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showManualWeightDialog(context, ref, summary.currentWeightKg),
                  icon: const Icon(Icons.monitor_weight_outlined, size: 16),
                  label: const Text('Log Weight', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPeriodDatePicker(context, ref),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Set Period Date', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Hydration Add
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.local_drink_rounded, color: AppTheme.accentBlue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Quick Water Log',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await ApiService.addHydration(selectedDate, 250);
                      ref.refresh(dashboardProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added +250ml. Today: ${updated}ml / 2200ml'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+250ml'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await ApiService.addHydration(selectedDate, 500);
                      ref.refresh(dashboardProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added +500ml. Today: ${updated}ml / 2200ml'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+500ml'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Today Schedule Header with Add Task Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Routine Checklist",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              TextButton.icon(
                onPressed: () => _showAddTaskSheet(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Task', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          tasksAsync.when(
            data: (tasks) => _buildTasksList(context, ref, tasks),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildTasksList(context, ref, ApiService.getOfflineTasks(selectedDate)),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, WidgetRef ref, List<ScheduledTaskModel> tasks) {
    if (tasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 36, color: AppTheme.textMuted),
                const SizedBox(height: 8),
                const Text('No tasks scheduled for today.'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showAddTaskSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a Custom Goal / Task'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
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
                color: task.isCompleted ? AppTheme.textLight : AppTheme.textMain,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${task.scheduledTime ?? 'Anytime'} • ${task.category}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              tooltip: 'Delete Task',
              onPressed: () => _confirmDeleteTask(context, ref, task),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width > 160 ? width : 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 26),
                if (onTap != null)
                  const Icon(Icons.edit_outlined, size: 14, color: AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
