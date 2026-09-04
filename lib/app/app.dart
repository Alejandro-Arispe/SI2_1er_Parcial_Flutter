import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/app/router/app_router.dart';
import 'package:fashion_store/core/theme/app_theme.dart';

/// Widget raíz de la aplicación: aplica el tema global y delega toda la
/// navegación al GoRouter configurado en app/router/app_router.dart.
class FashionStoreApp extends ConsumerWidget {
  const FashionStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FashionStore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
