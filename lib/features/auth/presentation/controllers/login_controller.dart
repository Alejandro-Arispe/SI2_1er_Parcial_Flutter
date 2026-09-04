import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/auth/domain/usecases/login_usecase.dart';
import 'package:fashion_store/shared/session/authenticated_user.dart';
import 'package:fashion_store/shared/session/session_controller.dart';

/// Controla el envío del formulario de login.
///
/// Expone el resultado como `AsyncValue<void>` para que la pantalla pueda
/// mostrar carga (AsyncLoading) y error (AsyncError) sin manejar banderas
/// manuales. En éxito, marca la sesión como autenticada, lo que dispara
/// la redirección del router hacia Home (ver app_router.dart).
class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();

    final result = await ref.read(loginUseCaseProvider).call(email: email, password: password);

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

final loginControllerProvider = NotifierProvider<LoginController, AsyncValue<void>>(LoginController.new);
