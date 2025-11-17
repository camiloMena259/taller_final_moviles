import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database_helper.dart';
import '../../data/remote/task_api_service.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/sync_service.dart';

// ==================== Providers de Servicios Base ====================

/// Provider del DatabaseHelper (Singleton)
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// Provider del API Service
final taskApiServiceProvider = Provider<TaskApiService>((ref) {
  return TaskApiService();
});

/// Provider del TaskRepository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final apiService = ref.watch(taskApiServiceProvider);
  
  return TaskRepository(
    databaseHelper: databaseHelper,
    apiService: apiService,
  );
});

/// Provider del SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final databaseHelper = ref.watch(databaseHelperProvider);
  
  final syncService = SyncService(
    repository: repository,
    databaseHelper: databaseHelper,
  );
  
  // Iniciar el servicio automáticamente
  syncService.start();
  
  // Limpiar cuando se dispose el provider
  ref.onDispose(() {
    syncService.stop();
  });
  
  return syncService;
});
