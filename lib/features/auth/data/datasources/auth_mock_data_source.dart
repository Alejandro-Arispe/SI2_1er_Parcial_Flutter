import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/features/auth/data/datasources/auth_data_source.dart';
import 'package:fashion_store/features/auth/data/models/auth_session_model.dart';
import 'package:fashion_store/features/auth/data/models/auth_user_model.dart';

/// Datasource temporal de desarrollo: simula el comportamiento del
/// backend mientras FastAPI no está disponible (ver sección 42 del
/// documento del proyecto). Se activa cuando AppConfig.useMockData es
/// true. No debe usarse en producción.
///
/// Para poder probar el manejo de errores de autenticación sin backend,
/// la contraseña "wrongpassword" simula credenciales inválidas.
class AuthMockDataSource implements AuthDataSource {
  const AuthMockDataSource();

  @override
  Future<AuthSessionModel> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (password == 'wrongpassword') {
      throw const AuthException('Correo o contraseña incorrectos.');
    }

    return AuthSessionModel(
      user: AuthUserModel(id: 'mock-user-1', name: _nameFromEmail(email), email: email),
      accessToken: 'mock-access-token',
    );
  }

  @override
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return AuthSessionModel(
      user: AuthUserModel(id: 'mock-user-1', name: name, email: email),
      accessToken: 'mock-access-token',
    );
  }

  String _nameFromEmail(String email) => email.split('@').first;
}
