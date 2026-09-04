import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/utils/validators.dart';
import 'package:fashion_store/core/widgets/app_button.dart';
import 'package:fashion_store/core/widgets/app_text_field.dart';
import 'package:fashion_store/features/auth/presentation/controllers/login_controller.dart';

/// Pantalla de inicio de sesión.
///
/// Valida el formulario localmente antes de llamar a LoginController.
/// El controller actualiza sessionControllerProvider en caso de éxito,
/// lo que hace que GoRouter redirija automáticamente a Home (ver
/// app_router.dart), así que esta pantalla no navega manualmente en el
/// caso exitoso.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginControllerProvider.notifier).submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Bienvenida de nuevo', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Inicia sesión para ver tus favoritos, reservas y compras.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Correo electrónico',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  enabled: !isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                if (loginState.hasError) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    (loginState.error as Failure).message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Iniciar sesión',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: isLoading ? null : () => context.push(RoutePaths.register),
                  child: const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
