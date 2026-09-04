import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/utils/validators.dart';
import 'package:fashion_store/core/widgets/app_button.dart';
import 'package:fashion_store/core/widgets/app_text_field.dart';
import 'package:fashion_store/features/auth/presentation/controllers/register_controller.dart';

/// Pantalla de registro. Únicamente como cliente (ver sección 5 del
/// documento del proyecto): no existe ninguna variante de registro
/// administrativo en esta app.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(registerControllerProvider.notifier).submit(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final isLoading = registerState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Crea tu cuenta', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Regístrate para reservar prendas, guardar favoritos y comprar.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Nombre completo',
                  controller: _nameController,
                  validator: Validators.requiredField,
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSpacing.md),
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
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirmar contraseña',
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value != _passwordController.text) return 'Las contraseñas no coinciden.';
                    return null;
                  },
                ),
                if (registerState.hasError) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    (registerState.error as Failure).message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Crear cuenta',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
