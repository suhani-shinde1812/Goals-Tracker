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
    final currentTasks = state.value ?? [];
    // Optimistic update
    state = AsyncValue.data(
      currentTasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(isCompleted: !t.isCompleted);
        }
        return t;
      }).toList(),
    );

    // Sync with backend database
    final updated = await ApiService.toggleTaskCompletion(taskId);
    if (updated != null) {
      state = AsyncValue.data(
        currentTasks.map((t) => t.id == taskId ? updated : t).toList(),
      );
    }
  }
}

final tasksProvider = StateNotifierProvider.autoDispose<TasksNotifier, AsyncValue<List<ScheduledTaskModel>>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return TasksNotifier(date);
});
