import 'package:fashion_store/features/auth/data/models/auth_session_model.dart';

/// Contrato común para cualquier fuente de datos de autenticación. Tiene
/// dos implementaciones intercambiables: AuthApiDataSource (real, contra
/// FastAPI) y AuthMockDataSource (temporal, para desarrollar sin
/// backend). El repositorio no sabe cuál de las dos está usando.
abstract class AuthDataSource {
  Future<AuthSessionModel> login({required String email, required String password});

  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  });
}
