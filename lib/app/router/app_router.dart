import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/main_scaffold.dart';
import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/app/router/splash_page.dart';
import 'package:fashion_store/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:fashion_store/features/auth/presentation/pages/login_page.dart';
import 'package:fashion_store/features/auth/presentation/pages/register_page.dart';
import 'package:fashion_store/features/cart/presentation/pages/cart_page.dart';
import 'package:fashion_store/features/catalog/presentation/pages/catalog_page.dart';
import 'package:fashion_store/features/checkout/presentation/pages/checkout_page.dart';
import 'package:fashion_store/features/favorites/presentation/pages/favorites_page.dart';
import 'package:fashion_store/features/home/presentation/pages/home_page.dart';
import 'package:fashion_store/features/orders/presentation/pages/orders_page.dart';
import 'package:fashion_store/features/product/presentation/pages/product_detail_page.dart';
import 'package:fashion_store/features/profile/presentation/pages/profile_page.dart';
import 'package:fashion_store/features/reservations/presentation/pages/reservations_page.dart';
import 'package:fashion_store/features/try_on/presentation/pages/try_on_page.dart';
import 'package:fashion_store/shared/session/session_controller.dart';
import 'package:fashion_store/shared/session/session_state.dart';

/// Puente entre Riverpod y GoRouter: GoRouter necesita un Listenable para
/// saber cuándo debe volver a evaluar la función [redirect]. Este
/// notifier se suscribe a sessionControllerProvider y notifica a
/// GoRouter cada vez que el estado de sesión cambia.
class _SessionRefreshNotifier extends ChangeNotifier {
  _SessionRefreshNotifier(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
  }
}

/// Configuración única de navegación de la app.
///
/// La redirección implementa las reglas de la sección 21 del documento:
/// el catálogo y el detalle de producto son públicos; favoritos,
/// reservas, checkout, historial, perfil y el asistente de IA requieren
/// sesión iniciada.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _SessionRefreshNotifier(ref);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      // Mientras no se sepa si hay sesión guardada, todo el tráfico se
      // mantiene en splash.
      if (session is SessionUnknown) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }

      // Ya se resolvió el estado de sesión: splash redirige a Home,
      // que es la pantalla pública de entrada de la app.
      if (location == RoutePaths.splash) {
        return RoutePaths.home;
      }

      final isAuthenticated = session is SessionAuthenticated;
      final isProtectedRoute = RoutePaths.protectedPaths.any(location.startsWith);
      final isAuthRoute = RoutePaths.authPaths.contains(location);

      if (!isAuthenticated && isProtectedRoute) {
        return RoutePaths.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: RoutePaths.register, builder: (context, state) => const RegisterPage()),

      // Rutas de nivel superior fuera del shell: se abren sobre la pila
      // de navegación actual (context.push) y muestran su propio botón
      // de volver, en lugar de convivir con la barra de navegación.
      GoRoute(path: RoutePaths.cart, builder: (context, state) => const CartPage()),
      GoRoute(path: RoutePaths.checkout, builder: (context, state) => const CheckoutPage()),
      GoRoute(path: RoutePaths.orders, builder: (context, state) => const OrdersPage()),
      GoRoute(path: RoutePaths.reservations, builder: (context, state) => const ReservationsPage()),
      GoRoute(path: RoutePaths.tryOn, builder: (context, state) => const TryOnPage()),
      GoRoute(path: RoutePaths.aiAssistant, builder: (context, state) => const AiAssistantPage()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: RoutePaths.home, builder: (context, state) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.catalog,
                builder: (context, state) => const CatalogPage(),
                routes: [
                  GoRoute(
                    path: RoutePaths.productDetailPattern,
                    builder: (context, state) => ProductDetailPage(
                      productId: state.pathParameters['productId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: RoutePaths.favorites, builder: (context, state) => const FavoritesPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: RoutePaths.profile, builder: (context, state) => const ProfilePage())],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: const Center(child: Text('La ruta solicitada no existe.')),
    ),
  );
});
