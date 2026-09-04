import 'package:fashion_store/features/auth/domain/entities/auth_user.dart';

/// Representación del usuario tal como la devuelve la API (o el mock).
/// Extiende la entidad de dominio y agrega (de)serialización JSON.
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
