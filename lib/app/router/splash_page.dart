import 'package:flutter/material.dart';
import 'package:fashion_store/core/theme/app_colors.dart';

/// Pantalla mostrada mientras SessionController determina si existe una
/// sesión guardada. El router redirige automáticamente en cuanto el
/// estado deja de ser SessionUnknown (ver app_router.dart).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FashionStore',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
