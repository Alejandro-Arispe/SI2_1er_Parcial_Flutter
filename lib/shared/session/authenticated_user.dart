/// Datos mínimos del usuario autenticado, compartidos entre el router y
/// cualquier feature que necesite mostrar "quién es" el cliente actual
/// (perfil, saludo en Home, checkout).
///
/// Se define aquí, en shared/, en lugar de reusar la entidad AuthUser del
/// feature de autenticación, para que shared/ no dependa de un feature
/// concreto (los features pueden depender de shared/, nunca al revés).
/// AuthRepositoryImpl es responsable de mapear su entidad de dominio a
/// este valor al iniciar sesión.
class AuthenticatedUser {
  final String id;
  final String name;
  final String email;

  const AuthenticatedUser({
    required this.id,
    required this.name,
    required this.email,
  });
}
