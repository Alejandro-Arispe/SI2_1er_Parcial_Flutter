import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/auth/domain/usecases/register_usecase.dart';
import 'package:fashion_store/shared/session/authenticated_user.dart';
import 'package:fashion_store/shared/session/session_controller.dart';

/// Controla el envío del formulario de registro.
///
/// Tras un registro exitoso, la sesión queda autenticada de inmediato
/// (no se exige un login por separado): es la decisión de UX más simple
/// y habitual para el flujo de alta de un cliente nuevo.
class RegisterController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(registerUseCaseProvider)
        .call(name: name, email: email, password: password);

    switch (result) {
      case Success(data: final user):
        ref.read(sessionControllerProvider.notifier).markAuthenticated(
          AuthenticatedUser(id: user.id, name: user.name, email: user.email),
        );
        state = const AsyncData(null);
      case ResultError(failure: final failure):
        state = AsyncError(failure, StackTrace.current);
    }
  }
}

final registerControllerProvider =
    NotifierProvider<RegisterController, AsyncValue<void>>(RegisterController.new);
