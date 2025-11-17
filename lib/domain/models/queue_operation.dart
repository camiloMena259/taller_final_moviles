import '../../../core/utils/date_utils.dart';

/// Tipos de operaciones en la cola de sincronización
enum OperationType {
  create,
  update,
  delete;

  String toJson() => name.toUpperCase();

  static OperationType fromJson(String value) {
    return OperationType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => OperationType.create,
    );
  }
}

/// Modelo para operaciones en cola de sincronización
class QueueOperation {
  final String id;
  final String entity;
  final String entityId;
  final OperationType op;
  final String payload;
  final DateTime createdAt;
  final int attemptCount;
  final String? lastError;

  QueueOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
  });

  /// Crea una copia con algunos campos modificados
  QueueOperation copyWith({
    String? id,
    String? entity,
    String? entityId,
    OperationType? op,
    String? payload,
    DateTime? createdAt,
    int? attemptCount,
    String? lastError,
  }) {
    return QueueOperation(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Convierte el modelo a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity': entity,
      'entity_id': entityId,
      'op': op.toJson(),
      'payload': payload,
      'created_at': DateTimeUtils.getTimestampMilliseconds(createdAt),
      'attempt_count': attemptCount,
      'last_error': lastError,
    };
  }

  /// Crea un modelo desde Map de SQLite
  factory QueueOperation.fromMap(Map<String, dynamic> map) {
    return QueueOperation(
      id: map['id'] as String,
      entity: map['entity'] as String,
      entityId: map['entity_id'] as String,
      op: OperationType.fromJson(map['op'] as String),
      payload: map['payload'] as String,
      createdAt: DateTimeUtils.fromTimestampMilliseconds(map['created_at'] as int),
      attemptCount: map['attempt_count'] as int,
      lastError: map['last_error'] as String?,
    );
  }

  @override
  String toString() {
    return 'QueueOperation(id: $id, entity: $entity, entityId: $entityId, op: $op, attemptCount: $attemptCount)';
  }
}
