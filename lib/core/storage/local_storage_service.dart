import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_store/core/error/exceptions.dart';

/// Envuelve shared_preferences para guardar información local NO
/// crítica (Fase 23, sección 19 del documento): caché de catálogo,
/// últimos productos consultados, configuración. A diferencia de
/// SecureStorageService (sesión, cifrado), esto no guarda nada sensible
/// ni se usa para operaciones críticas (pago, compra, reserva), que
/// siempre dependen del backend y de la conectividad.
class LocalStorageService {
  const LocalStorageService();

  Future<void> writeString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      throw const CacheException('No se pudo guardar en el almacenamiento local.');
    }
  }

  Future<String?> readString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      throw const CacheException('No se pudo leer el almacenamiento local.');
    }
  }

  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      throw const CacheException('No se pudo actualizar el almacenamiento local.');
    }
  }
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return const LocalStorageService();
});
