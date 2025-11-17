/// Constantes de la aplicación
class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://192.168.18.10:3000';
  static const int connectionTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos

  // Database
  static const String databaseName = 'todo_app.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String tasksTable = 'tasks';
  static const String queueOperationsTable = 'queue_operations';

  // Sync Configuration
  static const int maxRetryAttempts = 3;
  static const int initialBackoffDelay = 1000; // 1 segundo
  static const int maxBackoffDelay = 60000; // 1 minuto
}
