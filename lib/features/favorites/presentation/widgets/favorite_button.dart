import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/favorites/presentation/controllers/favorites_controller.dart';
import 'package:fashion_store/shared/session/session_controller.dart';
import 'package:fashion_store/shared/session/session_state.dart';

/// Botón de corazón para marcar/quitar un producto de favoritos.
/// Reutilizable desde ProductCard (Home, Catálogo) y el detalle de
/// producto, para que el estado se vea igual en toda la app.
///
/// Favoritos requiere sesión iniciada (ver sección 21 del documento):
/// si se toca sin sesión, se navega a login en lugar de intentar
/// guardar el favorito.
class FavoriteButton extends ConsumerWidget {
  final Product product;
  final double size;

  const FavoriteButton({super.key, required this.product, this.size = 20});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesControllerProvider.select((state) => state.isFavorite(product.id)),
    );

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        final session = ref.read(sessionControllerProvider);
        if (session is! SessionAuthenticated) {
          // Se usa go() y no push(): el redirect automático del router
          // (ver app_router.dart) reacciona a cambios de sesión sobre
          // la "ubicación actual", que push() no actualiza. Con go(),
          // iniciar sesión desde aquí vuelve a Home correctamente en
          // lugar de dejar a la usuaria atascada en login.
          context.go(RoutePaths.login);
          return;
        }
        ref.read(favoritesControllerProvider.notifier).toggle(product);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background.withValues(alpha: 0.85),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: size,
          color: isFavorite ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    );
  }
}
