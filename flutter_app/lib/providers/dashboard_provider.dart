import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

final selectedDateProvider = StateProvider<String>((ref) {
  return DateTime.now().toIso8601String().split('T')[0];
});

final dashboardProvider = FutureProvider.autoDispose<DashboardSummaryModel?>((ref) async {
  final date = ref.watch(selectedDateProvider);
  return await ApiService.getDashboardSummary(date);
});

class TasksNotifier extends StateNotifier<AsyncValue<List<ScheduledTaskModel>>> {
  final String date;
  TasksNotifier(this.date) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final tasks = await ApiService.getTasks(date);
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTask(int taskId) async {
    // 1. Persist to storage & remote
    final isCompleted = await ApiService.toggleTaskCompletion(date, taskId);
    // 2. Update Riverpod state immediately
    final currentTasks = state.value ?? [];
    state = AsyncValue.data(
      currentTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(isCompleted: isCompleted);
        }
        return t;
      }).toList(),
    );
  }

  Future<void> addTask(
    String title,
    String scheduledTime,
    String category,
    int durationMinutes,
    String priority,
  ) async {
    await ApiService.addTask(date, title, scheduledTime, category, durationMinutes, priority);
    await loadTasks();
  }

  Future<void> deleteTask(int taskId) async {
    await ApiService.deleteTask(date, taskId);
    await loadTasks();
  }

  Future<void> resetToDefault() async {
    await ApiService.resetTasksToDefault(date);
    await loadTasks();
  }
}

final tasksProvider = StateNotifierProvider.autoDispose<TasksNotifier, AsyncValue<List<ScheduledTaskModel>>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return TasksNotifier(date);
});
