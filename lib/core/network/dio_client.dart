import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/network/interceptors/auth_interceptor.dart';
import 'package:fashion_store/core/network/interceptors/error_interceptor.dart';
import 'package:fashion_store/core/security/secure_storage_service.dart';

/// Construye la instancia única de Dio usada por todos los data sources
/// remotos de la aplicación, ya configurada con la URL base del backend,
/// los tiempos de espera y los interceptores de autenticación/errores.
///
/// Los data sources nunca crean su propio Dio: siempre lo obtienen a
/// través de dioClientProvider, para que la configuración quede en un
/// único lugar (ver sección 26 del documento).
final dioClientProvider = Provider<Dio>((ref) {
  final secureStorageService = ref.watch(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.networkTimeout,
      receiveTimeout: AppConfig.networkTimeout,
      sendTimeout: AppConfig.networkTimeout,
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(secureStorageService),
    ErrorInterceptor(secureStorageService),
  ]);

  return dio;
});
