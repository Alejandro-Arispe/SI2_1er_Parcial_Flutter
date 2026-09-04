import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/security/secure_storage_service.dart';
import 'package:fashion_store/shared/session/authenticated_user.dart';
import 'package:fashion_store/shared/session/session_state.dart';

/// Controla el estado de sesión de la app.
///
/// Al arrancar, intenta restaurar la sesión leyendo el token y el perfil
/// mínimo del usuario guardados en almacenamiento seguro. El feature de
/// autenticación llama a [markAuthenticated] tras un login/registro
/// exitoso (después de persistir token y perfil en AuthRepositoryImpl),
/// y a [logout] al cerrar sesión. El router (app/router/app_router.dart)
/// observa este estado para decidir a qué pantalla redirigir.
///
/// Se usa Notifier (API manual de Riverpod 3, sin generación de código)
/// en lugar de StateNotifier, que en Riverpod 3 quedó como API legacy.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    _restoreSession();
    return const SessionUnknown();
  }

  Future<void> _restoreSession() async {
    try {
      final secureStorageService = ref.read(secureStorageServiceProvider);
      final token = await secureStorageService.readAccessToken();
      final profile = await secureStorageService.readUserProfile();

      if (token != null && token.isNotEmpty && profile != null) {
        state = SessionAuthenticated(
          AuthenticatedUser(
            id: profile['id'] ?? '',
            name: profile['name'] ?? '',
            email: profile['email'] ?? '',
          ),
        );
      } else {
        state = const SessionUnauthenticated();
      }
    } catch (_) {
      // Si el almacenamiento seguro falla al leer, se asume sin sesión
      // en lugar de bloquear el arranque de la app.
      state = const SessionUnauthenticated();
    }
  }

  void markAuthenticated(AuthenticatedUser user) => state = SessionAuthenticated(user);

  Future<void> logout() async {
    await ref.read(secureStorageServiceProvider).clearSession();
    state = const SessionUnauthenticated();
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
