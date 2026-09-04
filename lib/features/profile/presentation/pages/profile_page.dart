import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/app_button.dart';
import 'package:fashion_store/shared/session/session_controller.dart';
import 'package:fashion_store/shared/session/session_state.dart';

/// Perfil del cliente autenticado.
///
/// La gestión completa (edición de datos, direcciones, preferencias) se
/// implementará más adelante; por ahora muestra los datos guardados en
/// la sesión y permite cerrar sesión.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(user?.name ?? 'Cliente', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'La gestión completa del perfil (datos personales, direcciones) se implementará más adelante.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            AppButton(
              label: 'Cerrar sesión',
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                await ref.read(sessionControllerProvider.notifier).logout();
                if (context.mounted) context.go(RoutePaths.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}
