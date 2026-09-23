import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(databaseProvider)),
);

final allTasksProvider = StreamProvider<List<TaskItem>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAll(),
);

/// Pending tasks due today or overdue, sorted, for the dashboard.
final todayTasksProvider = Provider<AsyncValue<List<TaskItem>>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(allTasksProvider)
      .whenData(
        (items) => TaskRepository.sort(
          items
              .where(
                (i) => TaskRepository.matches(i.task, TaskView.today, today),
              )
              .toList(),
          TaskSort.dueDate,
        ),
      );
});
