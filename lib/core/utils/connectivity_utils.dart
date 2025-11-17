import 'package:connectivity_plus/connectivity_plus.dart';

/// Utilidades para verificar conectividad
class ConnectivityUtils {
  static final Connectivity _connectivity = Connectivity();

  /// Verifica si hay conexión a internet
  static Future<bool> hasConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);
  }

  /// Stream de cambios en la conectividad
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    });
  }
}
