import 'package:fashion_store/features/auth/data/models/auth_user_model.dart';

/// Respuesta completa de login/registro: el usuario más el token de
/// acceso que debe guardarse para las siguientes peticiones autenticadas.
class AuthSessionModel {
  final AuthUserModel user;
  final String accessToken;

  const AuthSessionModel({required this.user, required this.accessToken});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
    );
  }
}
