import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fashion_store/features/auth/domain/entities/auth_user.dart';
import 'package:fashion_store/features/auth/domain/repositories/auth_repository.dart';

/// Caso de uso: iniciar sesión con correo y contraseña.
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<Result<AuthUser>> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});
