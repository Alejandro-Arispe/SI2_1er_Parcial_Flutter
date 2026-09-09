import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Informa la conectividad de red del dispositivo (Fase 23, sección 19
/// del documento: las operaciones críticas -pago, compra, confirmación
/// de reserva- deben depender del backend y de la conectividad, así que
/// la app necesita poder consultarla explícitamente antes de intentarlas
/// en lugar de enterarse recién cuando la llamada ya falló).
///
/// No distingue si esa red realmente llega a internet, solo si hay una
/// interfaz de red activa: es la señal que da connectivity_plus y
/// alcanza para las decisiones de esta app (mostrar el aviso de sin
/// conexión, evitar iniciar una operación crítica sin red).
class ConnectivityService {
  const ConnectivityService();

  /// Consulta puntual y siempre fresca (no cacheada): se usa justo antes
  /// de una operación crítica, nunca se reutiliza un resultado viejo.
  Future<bool> isOnline() async {
    return _hasConnection(await Connectivity().checkConnectivity());
  }

  /// Cambios de conectividad en vivo, para un aviso persistente mientras
  /// no haya conexión (ver MainScaffold).
  Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return const ConnectivityService();
});

/// Stream ya conectado al provider, para que MainScaffold (y cualquier
/// otro consumidor) no tenga que suscribirse a ConnectivityService por
/// su cuenta.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});
