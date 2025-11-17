import '../../../core/utils/date_utils.dart';

/// Modelo de una tarea
class Task {
  final String id;
  final String title;
  final bool completed;
  final DateTime updatedAt;
  final bool deleted;

  Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.updatedAt,
    this.deleted = false,
  });

  /// Crea una copia de la tarea con algunos campos modificados
  Task copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Convierte el modelo a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'updated_at': DateTimeUtils.toIso8601String(updatedAt),
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Crea un modelo desde Map de SQLite
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as int) == 1,
      updatedAt: DateTimeUtils.fromIso8601String(map['updated_at'] as String),
      deleted: (map['deleted'] as int) == 1,
    );
  }

  /// Convierte el modelo a JSON para API REST
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'updatedAt': DateTimeUtils.toIso8601String(updatedAt),
    };
  }

  /// Crea un modelo desde JSON de API REST
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool,
      updatedAt: DateTimeUtils.fromIso8601String(json['updatedAt'] as String),
      deleted: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.completed == completed &&
        other.updatedAt == updatedAt &&
        other.deleted == deleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        completed.hashCode ^
        updatedAt.hashCode ^
        deleted.hashCode;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $completed, updatedAt: $updatedAt, deleted: $deleted)';
  }
}
