import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart' as custom_exceptions;
import '../../domain/models/task.dart';
import '../../domain/models/queue_operation.dart';

/// Helper para gestionar la base de datos SQLite local
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  // Constructor privado para patrón Singleton
  DatabaseHelper._();

  /// Obtiene la instancia única de DatabaseHelper
  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// Obtiene la base de datos (la crea si no existe)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    try {
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al inicializar la base de datos: $e');
    }
  }

  /// Crea las tablas iniciales
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de tareas
    await db.execute('''
      CREATE TABLE ${AppConstants.tasksTable} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla de cola de operaciones
    await db.execute('''
      CREATE TABLE ${AppConstants.queueOperationsTable} (
        id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('''
      CREATE INDEX idx_tasks_completed ON ${AppConstants.tasksTable}(completed)
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_deleted ON ${AppConstants.tasksTable}(deleted)
    ''');

    await db.execute('''
      CREATE INDEX idx_queue_created_at ON ${AppConstants.queueOperationsTable}(created_at)
    ''');
  }

  /// Maneja actualizaciones de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí se manejarían las migraciones futuras
  }

  // ==================== CRUD para Tasks ====================

  /// Inserta una tarea en la base de datos
  Future<void> insertTask(Task task) async {
    try {
      final db = await database;
      await db.insert(
        AppConstants.tasksTable,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al insertar tarea: $e');
    }
  }

  /// Obtiene todas las tareas no eliminadas
  Future<List<Task>> getAllTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.tasksTable,
        where: 'deleted = ?',
        whereArgs: [0],
        orderBy: 'updated_at DESC',
      );
      return maps.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al obtener tareas: $e');
    }
  }

  /// Obtiene una tarea por ID
  Future<Task?> getTaskById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.tasksTable,
        where: 'id = ? AND deleted = ?',
        whereArgs: [id, 0],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Task.fromMap(maps.first);
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al obtener tarea: $e');
    }
  }

  /// Actualiza una tarea
  Future<void> updateTask(Task task) async {
    try {
      final db = await database;
      await db.update(
        AppConstants.tasksTable,
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al actualizar tarea: $e');
    }
  }

  /// Elimina una tarea (marca como eliminada)
  Future<void> deleteTask(String id) async {
    try {
      final db = await database;
      await db.update(
        AppConstants.tasksTable,
        {'deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al eliminar tarea: $e');
    }
  }

  /// Elimina permanentemente una tarea de la base de datos
  Future<void> permanentDeleteTask(String id) async {
    try {
      final db = await database;
      await db.delete(
        AppConstants.tasksTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al eliminar permanentemente tarea: $e');
    }
  }

  /// Obtiene tareas completadas
  Future<List<Task>> getCompletedTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.tasksTable,
        where: 'completed = ? AND deleted = ?',
        whereArgs: [1, 0],
        orderBy: 'updated_at DESC',
      );
      return maps.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al obtener tareas completadas: $e');
    }
  }

  /// Obtiene tareas pendientes
  Future<List<Task>> getPendingTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.tasksTable,
        where: 'completed = ? AND deleted = ?',
        whereArgs: [0, 0],
        orderBy: 'updated_at DESC',
      );
      return maps.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al obtener tareas pendientes: $e');
    }
  }

  // ==================== CRUD para Queue Operations ====================

  /// Inserta una operación en la cola
  Future<void> insertQueueOperation(QueueOperation operation) async {
    try {
      final db = await database;
      await db.insert(
        AppConstants.queueOperationsTable,
        operation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al insertar operación en cola: $e');
    }
  }

  /// Obtiene todas las operaciones pendientes ordenadas por fecha de creación
  Future<List<QueueOperation>> getPendingOperations() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        AppConstants.queueOperationsTable,
        orderBy: 'created_at ASC',
      );
      return maps.map((map) => QueueOperation.fromMap(map)).toList();
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al obtener operaciones pendientes: $e');
    }
  }

  /// Actualiza una operación en la cola
  Future<void> updateQueueOperation(QueueOperation operation) async {
    try {
      final db = await database;
      await db.update(
        AppConstants.queueOperationsTable,
        operation.toMap(),
        where: 'id = ?',
        whereArgs: [operation.id],
      );
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al actualizar operación en cola: $e');
    }
  }

  /// Elimina una operación de la cola
  Future<void> deleteQueueOperation(String id) async {
    try {
      final db = await database;
      await db.delete(
        AppConstants.queueOperationsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al eliminar operación de cola: $e');
    }
  }

  /// Limpia todas las operaciones de la cola
  Future<void> clearQueueOperations() async {
    try {
      final db = await database;
      await db.delete(AppConstants.queueOperationsTable);
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al limpiar operaciones de cola: $e');
    }
  }

  // ==================== Utilidades ====================

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Elimina la base de datos (útil para testing)
  Future<void> deleteDatabaseFile() async {
    try {
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, AppConstants.databaseName);
      final File dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      _database = null;
    } catch (e) {
      throw custom_exceptions.DatabaseException('Error al eliminar base de datos: $e');
    }
  }
}
