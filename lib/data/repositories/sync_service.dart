import 'dart:async';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/utils/connectivity_utils.dart';
import '../../domain/models/queue_operation.dart';
import '../local/database_helper.dart';
import '../repositories/task_repository.dart';

/// Servicio para gestionar la sincronización de operaciones pendientes
class SyncService {
  final TaskRepository _repository;
  final DatabaseHelper _databaseHelper;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isSyncing = false;

  SyncService({
    required TaskRepository repository,
    DatabaseHelper? databaseHelper,
  })  : _repository = repository,
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Inicia el servicio de sincronización
  void start() {
    // Escuchar cambios en la conectividad
    _connectivitySubscription = ConnectivityUtils.onConnectivityChanged.listen(
      (hasConnection) {
        if (hasConnection && !_isSyncing) {
          // Cuando se recupera la conexión, sincronizar
          syncPendingOperations();
        }
      },
    );

    // Intentar sincronizar inmediatamente si hay conexión
    _attemptInitialSync();
  }

  /// Intenta sincronizar al iniciar el servicio
  Future<void> _attemptInitialSync() async {
    try {
      final hasConnection = await ConnectivityUtils.hasConnection();
      if (hasConnection) {
        await syncPendingOperations();
      }
    } catch (e) {
      print('Error en sincronización inicial: $e');
    }
  }

  /// Sincroniza todas las operaciones pendientes con backoff exponencial
  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      
      final hasConnection = await ConnectivityUtils.hasConnection();
      if (!hasConnection) {
        _scheduleRetry();
        return;
      }

      final pendingOps = await _databaseHelper.getPendingOperations();
      
      if (pendingOps.isEmpty) {
        _isSyncing = false;
        return;
      }

      print('Sincronizando ${pendingOps.length} operaciones pendientes...');

      for (final op in pendingOps) {
        try {
          // Verificar si se debe reintentar según el backoff
          if (_shouldRetry(op)) {
            await _repository.syncNow();
            print('Operación ${op.id} sincronizada exitosamente');
          } else {
            print('Operación ${op.id} esperando backoff (intentos: ${op.attemptCount})');
          }
        } catch (e) {
          print('Error al sincronizar operación ${op.id}: $e');
          
          // Actualizar contador de intentos y último error
          final updatedOp = op.copyWith(
            attemptCount: op.attemptCount + 1,
            lastError: e.toString(),
          );
          await _databaseHelper.updateQueueOperation(updatedOp);

          // Si se alcanzó el máximo de intentos, marcar como fallida
          if (updatedOp.attemptCount >= AppConstants.maxRetryAttempts) {
            print('Operación ${op.id} alcanzó el máximo de intentos (${AppConstants.maxRetryAttempts})');
            // Aquí podrías mover la operación a una tabla de "operaciones fallidas"
            // o notificar al usuario
          }
        }
      }

      _isSyncing = false;
      
      // Verificar si quedan operaciones pendientes
      final remaining = await _databaseHelper.getPendingOperations();
      if (remaining.isNotEmpty) {
        _scheduleRetry();
      }
    } catch (e) {
      _isSyncing = false;
      print('Error general en sincronización: $e');
      _scheduleRetry();
    }
  }

  /// Determina si se debe reintentar una operación según backoff exponencial
  bool _shouldRetry(QueueOperation operation) {
    if (operation.attemptCount == 0) return true;
    if (operation.attemptCount >= AppConstants.maxRetryAttempts) return false;

    // Calcular delay exponencial: initialDelay * 2^(attemptCount - 1)
    final backoffDelay = min(
      AppConstants.initialBackoffDelay * pow(2, operation.attemptCount - 1),
      AppConstants.maxBackoffDelay.toDouble(),
    ).toInt();

    final timeSinceCreation = DateTime.now().difference(operation.createdAt).inMilliseconds;
    
    // Calcular el tiempo que debería haber esperado según el número de intentos
    final expectedWaitTime = _calculateTotalWaitTime(operation.attemptCount);

    return timeSinceCreation >= expectedWaitTime;
  }

  /// Calcula el tiempo total de espera acumulado para un número de intentos
  int _calculateTotalWaitTime(int attempts) {
    int totalWait = 0;
    for (int i = 0; i < attempts; i++) {
      final delay = min(
        AppConstants.initialBackoffDelay * pow(2, i),
        AppConstants.maxBackoffDelay.toDouble(),
      ).toInt();
      totalWait += delay;
    }
    return totalWait;
  }

  /// Programa un reintento de sincronización
  void _scheduleRetry() {
    _retryTimer?.cancel();
    
    // Reintentar después de 30 segundos
    _retryTimer = Timer(const Duration(seconds: 30), () {
      syncPendingOperations();
    });
  }

  /// Obtiene el número de operaciones pendientes
  Future<int> getPendingOperationsCount() async {
    final ops = await _databaseHelper.getPendingOperations();
    return ops.length;
  }

  /// Obtiene todas las operaciones pendientes
  Future<List<QueueOperation>> getPendingOperations() async {
    return await _databaseHelper.getPendingOperations();
  }

  /// Verifica si hay operaciones pendientes
  Future<bool> hasPendingOperations() async {
    final count = await getPendingOperationsCount();
    return count > 0;
  }

  /// Limpia operaciones antiguas que han fallado muchas veces
  Future<void> cleanupFailedOperations() async {
    final pendingOps = await _databaseHelper.getPendingOperations();
    
    for (final op in pendingOps) {
      if (op.attemptCount >= AppConstants.maxRetryAttempts) {
        final daysSinceCreation = DateTime.now().difference(op.createdAt).inDays;
        
        // Eliminar operaciones que llevan más de 7 días y han fallado
        if (daysSinceCreation > 7) {
          await _databaseHelper.deleteQueueOperation(op.id);
          print('Operación ${op.id} eliminada por antigüedad');
        }
      }
    }
  }

  /// Detiene el servicio de sincronización
  void stop() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _connectivitySubscription = null;
    _retryTimer = null;
  }

  /// Verifica el estado de sincronización
  bool get isSyncing => _isSyncing;
}
