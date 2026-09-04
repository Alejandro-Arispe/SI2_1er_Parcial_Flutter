/// Entidad de dominio: el cliente autenticado. No conoce nada de JSON ni
/// de la API; eso es responsabilidad de AuthUserModel en la capa data.
class AuthUser {
  final String id;
  final String name;
  final String email;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
  });
}
