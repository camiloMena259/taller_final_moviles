import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../data/repositories/task_repository.dart';
import 'providers.dart';

/// Enumeración para filtros de tareas
enum TaskFilter {
  all,
  pending,
  completed;

  String get displayName {
    switch (this) {
      case TaskFilter.all:
        return 'Todas';
      case TaskFilter.pending:
        return 'Pendientes';
      case TaskFilter.completed:
        return 'Completadas';
    }
  }
}

// ==================== Estado de la UI ====================

/// Provider del filtro actual
final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return TaskFilter.all;
});

/// Provider de estado de carga
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider de errores
final errorMessageProvider = StateProvider<String?>((ref) => null);

// ==================== Providers de Datos ====================

/// Provider de la lista de tareas (basado en el filtro)
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(taskFilterProvider);

  switch (filter) {
    case TaskFilter.all:
      return await repository.getTasks();
    case TaskFilter.pending:
      return await repository.getTasksByStatus(completed: false);
    case TaskFilter.completed:
      return await repository.getTasksByStatus(completed: true);
  }
});

/// Provider para refrescar las tareas manualmente
final refreshTasksProvider = StateProvider<int>((ref) => 0);

/// Provider de tareas con auto-refresh
final tasksWithRefreshProvider = FutureProvider<List<Task>>((ref) async {
  // Vigilar el contador de refresh para forzar recarga
  ref.watch(refreshTasksProvider);
  
  final repository = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(taskFilterProvider);

  switch (filter) {
    case TaskFilter.all:
      return await repository.getTasks();
    case TaskFilter.pending:
      return await repository.getTasksByStatus(completed: false);
    case TaskFilter.completed:
      return await repository.getTasksByStatus(completed: true);
  }
});

/// Provider del número de operaciones pendientes de sincronización
final pendingOperationsCountProvider = StreamProvider<int>((ref) async* {
  final syncService = ref.watch(syncServiceProvider);
  
  // Emitir el contador cada 5 segundos
  while (true) {
    yield await syncService.getPendingOperationsCount();
    await Future.delayed(const Duration(seconds: 5));
  }
});

// ==================== Providers de Acciones ====================

/// Provider para crear una tarea
final createTaskProvider = Provider<Future<void> Function(String)>((ref) {
  return (String title) async {
    if (title.trim().isEmpty) {
      throw Exception('El título no puede estar vacío');
    }

    final repository = ref.read(taskRepositoryProvider);
    await repository.createTask(title);
    
    // Refrescar la lista
    ref.read(refreshTasksProvider.notifier).state++;
  };
});

/// Provider para actualizar una tarea
final updateTaskProvider = Provider<Future<void> Function(Task)>((ref) {
  return (Task task) async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.updateTask(task);
    
    // Refrescar la lista
    ref.read(refreshTasksProvider.notifier).state++;
  };
});

/// Provider para alternar el estado de completado de una tarea
final toggleTaskCompletionProvider = Provider<Future<void> Function(String)>((ref) {
  return (String taskId) async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.toggleTaskCompletion(taskId);
    
    // Refrescar la lista
    ref.read(refreshTasksProvider.notifier).state++;
  };
});

/// Provider para eliminar una tarea
final deleteTaskProvider = Provider<Future<void> Function(String)>((ref) {
  return (String taskId) async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.deleteTask(taskId);
    
    // Refrescar la lista
    ref.read(refreshTasksProvider.notifier).state++;
  };
});

/// Provider para sincronizar manualmente
final syncNowProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.syncNow();
    
    // Refrescar la lista
    ref.read(refreshTasksProvider.notifier).state++;
  };
});
