import 'package:fashion_store/shared/session/authenticated_user.dart';

/// Estado de sesión del usuario, compartido entre el router (para
/// decidir redirecciones) y cualquier feature que necesite saber si hay
/// una sesión activa (ver sección 21 del documento: acceso sin cuenta
/// vs. operaciones que requieren autenticación).
sealed class SessionState {
  const SessionState();
}

/// Estado inicial: todavía no se determinó si hay una sesión guardada.
/// El router mantiene al usuario en la pantalla de splash mientras dure.
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionAuthenticated extends SessionState {
  final AuthenticatedUser user;
  const SessionAuthenticated(this.user);
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}
