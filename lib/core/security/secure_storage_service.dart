import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fashion_store/core/error/exceptions.dart';

/// Envuelve flutter_secure_storage para guardar información sensible de
/// sesión (tokens) cifrada en el dispositivo (Keystore en Android).
///
/// Esta es la única clase autorizada a leer/escribir el token de acceso;
/// el resto de la app lo obtiene a través de AuthInterceptor o del
/// feature de autenticación, nunca accediendo a este storage directamente.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userProfileKey = 'user_profile';

  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
    } catch (_) {
      throw const CacheException('No se pudo guardar la sesión.');
    }
  }

  Future<String?> readAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (_) {
      throw const CacheException('No se pudo leer la sesión.');
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (_) {
      throw const CacheException('No se pudo guardar la sesión.');
    }
  }

  Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (_) {
      throw const CacheException('No se pudo leer la sesión.');
    }
  }

  /// Guarda los datos mínimos del usuario (id, nombre, correo) junto al
  /// token, para poder restaurar la sesión al arrancar la app sin
  /// depender de una llamada de red adicional (ver SessionController).
  Future<void> saveUserProfile(Map<String, String> profile) async {
    try {
      await _storage.write(key: _userProfileKey, value: jsonEncode(profile));
    } catch (_) {
      throw const CacheException('No se pudo guardar el perfil de sesión.');
    }
  }

  Future<Map<String, String>?> readUserProfile() async {
    try {
      final raw = await _storage.read(key: _userProfileKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      throw const CacheException('No se pudo leer el perfil de sesión.');
    }
  }

  /// Elimina los tokens y el perfil guardados. Se usa al cerrar sesión o
  /// cuando el backend indica que la sesión expiró (401).
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userProfileKey);
    } catch (_) {
      throw const CacheException('No se pudo cerrar la sesión correctamente.');
    }
  }
}

/// Provider global del almacenamiento seguro. Se mantiene vivo durante
/// toda la vida de la app porque contiene el estado de sesión.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});
