import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fashion_store/features/auth/domain/entities/auth_user.dart';
import 'package:fashion_store/features/auth/domain/repositories/auth_repository.dart';

/// Caso de uso: registrar un nuevo cliente. El registro es únicamente
/// como cliente (ver sección 5 del documento del proyecto).
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<Result<AuthUser>> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.register(name: name, email: email, password: password);
  }
}

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});
