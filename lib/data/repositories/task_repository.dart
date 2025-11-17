import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../core/utils/connectivity_utils.dart';
import '../../domain/models/task.dart';
import '../../domain/models/queue_operation.dart';
import '../local/database_helper.dart';
import '../remote/task_api_service.dart';

/// Repositorio que coordina entre almacenamiento local y remoto
/// Implementa estrategia offline-first
class TaskRepository {
  final DatabaseHelper _databaseHelper;
  final TaskApiService _apiService;
  final Uuid _uuid = const Uuid();

  TaskRepository({
    DatabaseHelper? databaseHelper,
    TaskApiService? apiService,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _apiService = apiService ?? TaskApiService();

  // ==================== Operaciones principales (Offline-First) ====================

  /// Obtiene todas las tareas (primero local, luego sincroniza en background)
  Future<List<Task>> getTasks() async {
    // 1. Retornar datos locales inmediatamente
    final localTasks = await _databaseHelper.getAllTasks();

    // 2. Intentar sincronizar en background si hay conexión
    _syncInBackground();

    return localTasks;
  }

  /// Obtiene una tarea por ID
  Future<Task?> getTaskById(String id) async {
    return await _databaseHelper.getTaskById(id);
  }

  /// Crea una nueva tarea (offline-first)
  Future<Task> createTask(String title) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      completed: false,
      updatedAt: DateTime.now(),
    );

    // 1. Guardar en local primero
    await _databaseHelper.insertTask(task);

    // 2. Encolar operación para sincronización
    await _enqueueOperation(
      entityId: task.id,
      operation: OperationType.create,
      task: task,
    );

    // 3. Intentar sincronizar inmediatamente si hay conexión
    _syncInBackground();

    return task;
  }

  /// Actualiza una tarea existente (offline-first)
  Future<Task> updateTask(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());

    // 1. Actualizar en local primero
    await _databaseHelper.updateTask(updatedTask);

    // 2. Encolar operación para sincronización
    await _enqueueOperation(
      entityId: updatedTask.id,
      operation: OperationType.update,
      task: updatedTask,
    );

    // 3. Intentar sincronizar inmediatamente si hay conexión
    _syncInBackground();

    return updatedTask;
  }

  /// Marca una tarea como completada o no completada
  Future<Task> toggleTaskCompletion(String id) async {
    final task = await _databaseHelper.getTaskById(id);
    if (task == null) throw Exception('Tarea no encontrada');

    return await updateTask(task.copyWith(completed: !task.completed));
  }

  /// Elimina una tarea (offline-first)
  Future<void> deleteTask(String id) async {
    // 1. Marcar como eliminada en local
    await _databaseHelper.deleteTask(id);

    // 2. Encolar operación para sincronización
    final task = await _databaseHelper.getTaskById(id);
    if (task != null) {
      await _enqueueOperation(
        entityId: id,
        operation: OperationType.delete,
        task: task,
      );
    }

    // 3. Intentar sincronizar inmediatamente si hay conexión
    _syncInBackground();
  }

  /// Obtiene tareas filtradas por estado
  Future<List<Task>> getTasksByStatus({required bool completed}) async {
    if (completed) {
      return await _databaseHelper.getCompletedTasks();
    } else {
      return await _databaseHelper.getPendingTasks();
    }
  }

  // ==================== Sincronización ====================

  /// Sincroniza en background sin bloquear la UI
  void _syncInBackground() async {
    try {
      final hasConnection = await ConnectivityUtils.hasConnection();
      if (!hasConnection) return;

      // Ejecutar sincronización sin await para no bloquear
      _syncPendingOperations();
    } catch (e) {
      // Log error but don't throw - background operation
      print('Error en sincronización background: $e');
    }
  }

  /// Sincroniza todas las operaciones pendientes
  Future<void> _syncPendingOperations() async {
    final hasConnection = await ConnectivityUtils.hasConnection();
    if (!hasConnection) return;

    final pendingOps = await _databaseHelper.getPendingOperations();

    for (final op in pendingOps) {
      try {
        await _processSyncOperation(op);
        // Si tuvo éxito, eliminar de la cola
        await _databaseHelper.deleteQueueOperation(op.id);
      } catch (e) {
        // Actualizar contador de intentos y error
        final updatedOp = op.copyWith(
          attemptCount: op.attemptCount + 1,
          lastError: e.toString(),
        );
        await _databaseHelper.updateQueueOperation(updatedOp);
      }
    }
  }

  /// Procesa una operación de sincronización individual
  Future<void> _processSyncOperation(QueueOperation operation) async {
    final taskData = jsonDecode(operation.payload) as Map<String, dynamic>;
    final task = Task.fromJson(taskData);

    switch (operation.op) {
      case OperationType.create:
        await _apiService.createTask(task);
        break;
      case OperationType.update:
        await _apiService.updateTask(task);
        break;
      case OperationType.delete:
        await _apiService.deleteTask(task.id);
        // Eliminar permanentemente después de sincronizar
        await _databaseHelper.permanentDeleteTask(task.id);
        break;
    }
  }

  /// Encola una operación para sincronización posterior
  Future<void> _enqueueOperation({
    required String entityId,
    required OperationType operation,
    required Task task,
  }) async {
    final queueOp = QueueOperation(
      id: _uuid.v4(),
      entity: 'task',
      entityId: entityId,
      op: operation,
      payload: jsonEncode(task.toJson()),
      createdAt: DateTime.now(),
    );

    await _databaseHelper.insertQueueOperation(queueOp);
  }

  /// Sincroniza manualmente (llamado por el usuario o al recuperar conexión)
  Future<void> syncNow() async {
    final hasConnection = await ConnectivityUtils.hasConnection();
    if (!hasConnection) {
      throw Exception('No hay conexión a internet');
    }

    // 1. Sincronizar operaciones pendientes
    await _syncPendingOperations();

    // 2. Obtener tareas del servidor y actualizar local
    try {
      final remoteTasks = await _apiService.getTasks();
      
      for (final remoteTask in remoteTasks) {
        final localTask = await _databaseHelper.getTaskById(remoteTask.id);
        
        // Estrategia Last-Write-Wins
        if (localTask == null) {
          // Nueva tarea del servidor
          await _databaseHelper.insertTask(remoteTask);
        } else if (remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          // Tarea del servidor es más reciente
          await _databaseHelper.updateTask(remoteTask);
        }
      }
    } catch (e) {
      print('Error al obtener tareas del servidor: $e');
      // No lanzar excepción, las operaciones locales ya se sincronizaron
    }
  }

  /// Limpia la base de datos local (útil para testing)
  Future<void> clearLocalData() async {
    final tasks = await _databaseHelper.getAllTasks();
    for (final task in tasks) {
      await _databaseHelper.permanentDeleteTask(task.id);
    }
    await _databaseHelper.clearQueueOperations();
  }

  /// Libera recursos
  void dispose() {
    _apiService.dispose();
  }
}
