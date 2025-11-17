import 'package:intl/intl.dart';

/// Utilidades para manejo de fechas
class DateTimeUtils {
  /// Convierte DateTime a String en formato ISO8601
  static String toIso8601String(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Convierte String ISO8601 a DateTime
  static DateTime fromIso8601String(String dateString) {
    return DateTime.parse(dateString);
  }

  /// Formatea DateTime para mostrar al usuario
  static String formatForDisplay(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Hoy ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Ayer ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  /// Obtiene timestamp en milisegundos
  static int getTimestampMilliseconds(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  /// Convierte timestamp en milisegundos a DateTime
  static DateTime fromTimestampMilliseconds(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}
