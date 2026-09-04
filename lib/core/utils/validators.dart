/// Validadores de formulario reutilizables, para no repetir expresiones
/// regulares ni mensajes de error en cada pantalla con formularios
/// (login, registro y, más adelante, checkout y perfil).
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!_emailPattern.hasMatch(trimmed)) return 'Ingresa un correo electrónico válido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }

  static String? requiredField(String? value, {String message = 'Este campo es obligatorio.'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }
}
