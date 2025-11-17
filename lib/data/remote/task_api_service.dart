import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart' as custom_exceptions;
import '../../domain/models/task.dart';

/// Servicio para comunicación con la API REST de tareas
class TaskApiService {
  final http.Client _client;
  final String baseUrl;

  TaskApiService({
    http.Client? client,
    this.baseUrl = AppConstants.baseUrl,
  }) : _client = client ?? http.Client();

  /// Headers comunes para las peticiones
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Obtiene todas las tareas del servidor
  Future<List<Task>> getTasks() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/tasks'),
            headers: _headers,
          )
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
          );

      return _handleResponse<List<Task>>(
        response,
        (data) {
          final List<dynamic> tasksList = data as List<dynamic>;
          return tasksList
              .map((json) => Task.fromJson(json as Map<String, dynamic>))
              .toList();
        },
      );
    } on TimeoutException {
      throw custom_exceptions.TimeoutException(
        'La solicitud ha excedido el tiempo de espera',
      );
    } catch (e) {
      if (e is custom_exceptions.NetworkException ||
          e is custom_exceptions.TimeoutException) {
        rethrow;
      }
      throw custom_exceptions.NetworkException(
        'Error al obtener tareas: $e',
      );
    }
  }

  /// Obtiene una tarea específica por ID
  Future<Task> getTaskById(String id) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/tasks/$id'),
            headers: _headers,
          )
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
          );

      return _handleResponse<Task>(
        response,
        (data) => Task.fromJson(data as Map<String, dynamic>),
      );
    } on TimeoutException {
      throw custom_exceptions.TimeoutException(
        'La solicitud ha excedido el tiempo de espera',
      );
    } catch (e) {
      if (e is custom_exceptions.NetworkException ||
          e is custom_exceptions.TimeoutException) {
        rethrow;
      }
      throw custom_exceptions.NetworkException(
        'Error al obtener tarea: $e',
      );
    }
  }

  /// Crea una nueva tarea en el servidor
  Future<Task> createTask(Task task) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/tasks'),
            headers: _headers,
            body: jsonEncode(task.toJson()),
          )
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
          );

      return _handleResponse<Task>(
        response,
        (data) => Task.fromJson(data as Map<String, dynamic>),
      );
    } on TimeoutException {
      throw custom_exceptions.TimeoutException(
        'La solicitud ha excedido el tiempo de espera',
      );
    } catch (e) {
      if (e is custom_exceptions.NetworkException ||
          e is custom_exceptions.TimeoutException) {
        rethrow;
      }
      throw custom_exceptions.NetworkException(
        'Error al crear tarea: $e',
      );
    }
  }

  /// Actualiza una tarea existente en el servidor
  Future<Task> updateTask(Task task) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/tasks/${task.id}'),
            headers: _headers,
            body: jsonEncode(task.toJson()),
          )
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
          );

      return _handleResponse<Task>(
        response,
        (data) => Task.fromJson(data as Map<String, dynamic>),
      );
    } on TimeoutException {
      throw custom_exceptions.TimeoutException(
        'La solicitud ha excedido el tiempo de espera',
      );
    } catch (e) {
      if (e is custom_exceptions.NetworkException ||
          e is custom_exceptions.TimeoutException) {
        rethrow;
      }
      throw custom_exceptions.NetworkException(
        'Error al actualizar tarea: $e',
      );
    }
  }

  /// Elimina una tarea del servidor
  Future<void> deleteTask(String id) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/tasks/$id'),
            headers: _headers,
          )
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
          );

      _handleResponse<void>(
        response,
        (_) => null,
      );
    } on TimeoutException {
      throw custom_exceptions.TimeoutException(
        'La solicitud ha excedido el tiempo de espera',
      );
    } catch (e) {
      if (e is custom_exceptions.NetworkException ||
          e is custom_exceptions.TimeoutException) {
        rethrow;
      }
      throw custom_exceptions.NetworkException(
        'Error al eliminar tarea: $e',
      );
    }
  }

  /// Maneja la respuesta HTTP y los posibles errores
  T _handleResponse<T>(
    http.Response response,
    T Function(dynamic) parseData,
  ) {
    // Respuestas exitosas (2xx)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return parseData(null);
      }
      final dynamic data = jsonDecode(response.body);
      return parseData(data);
    }

    // Errores del cliente (4xx)
    if (response.statusCode >= 400 && response.statusCode < 500) {
      String message = 'Error del cliente';
      
      switch (response.statusCode) {
        case 400:
          message = 'Solicitud inválida';
          break;
        case 401:
          message = 'No autorizado';
          break;
        case 403:
          message = 'Acceso prohibido';
          break;
        case 404:
          throw custom_exceptions.NotFoundException('Recurso no encontrado');
        case 409:
          message = 'Conflicto con el estado actual del recurso';
          break;
        case 422:
          message = 'Datos no procesables';
          break;
      }

      throw custom_exceptions.NetworkException(
        message,
        response.statusCode,
      );
    }

    // Errores del servidor (5xx)
    if (response.statusCode >= 500) {
      String message = 'Error del servidor';
      
      switch (response.statusCode) {
        case 500:
          message = 'Error interno del servidor';
          break;
        case 502:
          message = 'Puerta de enlace incorrecta';
          break;
        case 503:
          message = 'Servicio no disponible';
          break;
        case 504:
          message = 'Tiempo de espera de la puerta de enlace agotado';
          break;
      }

      throw custom_exceptions.NetworkException(
        message,
        response.statusCode,
      );
    }

    throw custom_exceptions.NetworkException(
      'Error desconocido: ${response.statusCode}',
      response.statusCode,
    );
  }

  /// Cierra el cliente HTTP
  void dispose() {
    _client.close();
  }
}
