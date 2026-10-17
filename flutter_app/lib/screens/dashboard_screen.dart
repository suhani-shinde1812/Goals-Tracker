import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BloomTrack',
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(dashboardProvider);
              ref.refresh(tasksProvider);
            },
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (summary) {
          if (summary == null) {
            return const Center(child: Text('Could not load dashboard summary'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                      const SizedBox(height: 6),
                      Text(
                        'Small habits. Better health. Bigger goals.',
                        style: TextStyle(fontSize: 13, color: AppTheme.primaryColor.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stat Cards Row
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Tasks',
                      value: '${summary.completedTasksToday}/${summary.totalTasksToday}',
                      sub: '${summary.completionPercentage.round()}% Done',
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
                      title: 'Weight',
                      value: '${summary.currentWeightKg} kg',
                      sub: 'Target: ${summary.targetWeightKg} kg',
                      icon: Icons.scale_rounded,
                      color: AppTheme.accentWarm,
                    ),
                    _buildStatCard(
                      context,
                      title: 'GATE CS',
                      value: '${summary.gateTopicsCompleted}/${summary.gateTotalTopics}',
                      sub: 'Topics Done',
                      icon: Icons.school_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

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
                            await ApiService.addHydration(selectedDate, 250);
                            ref.refresh(dashboardProvider);
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+250ml'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ApiService.addHydration(selectedDate, 500);
                            ref.refresh(dashboardProvider);
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+500ml'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Today Schedule
                const Text(
                  "Today's Schedule & Routine",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                const SizedBox(height: 10),

                tasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No tasks scheduled for today.'),
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
                              onChanged: (_) {
                                ref.read(tasksProvider.notifier).toggleTask(task.id);
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
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading tasks: $err'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return Container(
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}
