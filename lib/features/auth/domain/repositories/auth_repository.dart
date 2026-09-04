import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/auth/domain/entities/auth_user.dart';

/// Contrato que debe cumplir cualquier fuente de autenticación (API real
/// o datasource de desarrollo). La capa de presentación solo depende de
/// esta interfaz, nunca de Dio ni de flutter_secure_storage directamente.
abstract class AuthRepository {
  Future<Result<AuthUser>> login({required String email, required String password});

  Future<Result<AuthUser>> register({
    required String name,
    required String email,
    required String password,
  });
}
