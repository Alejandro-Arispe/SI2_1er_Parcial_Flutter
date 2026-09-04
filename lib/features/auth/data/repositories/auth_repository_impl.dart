import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/security/secure_storage_service.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/auth/data/datasources/auth_api_data_source.dart';
import 'package:fashion_store/features/auth/data/datasources/auth_data_source.dart';
import 'package:fashion_store/features/auth/data/datasources/auth_mock_data_source.dart';
import 'package:fashion_store/features/auth/data/models/auth_session_model.dart';
import 'package:fashion_store/features/auth/domain/entities/auth_user.dart';
import 'package:fashion_store/features/auth/domain/repositories/auth_repository.dart';

/// Implementación de AuthRepository: delega en un AuthDataSource (real o
/// mock, según AppConfig.useMockData) y, tras un login/registro exitoso,
/// persiste el token y el perfil del usuario en almacenamiento seguro
/// para que SessionController pueda restaurar la sesión al reabrir la app.
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;
  final SecureStorageService _secureStorageService;

  const AuthRepositoryImpl(this._dataSource, this._secureStorageService);

  @override
  Future<Result<AuthUser>> login({required String email, required String password}) async {
    try {
      final session = await _dataSource.login(email: email, password: password);
      await _persistSession(session);
      return Success(session.user);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<AuthUser>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final session = await _dataSource.register(name: name, email: email, password: password);
      await _persistSession(session);
      return Success(session.user);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  Future<void> _persistSession(AuthSessionModel session) async {
    await _secureStorageService.saveAccessToken(session.accessToken);
    await _secureStorageService.saveUserProfile({
      'id': session.user.id,
      'name': session.user.name,
      'email': session.user.email,
    });
  }
}

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AppConfig.useMockData
      ? const AuthMockDataSource()
      : AuthApiDataSource(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authDataSourceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});
