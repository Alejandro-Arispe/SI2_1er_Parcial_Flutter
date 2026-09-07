import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/recommendations/domain/usecases/get_recommendations_usecase.dart';
import 'package:fashion_store/features/recommendations/presentation/controllers/recently_viewed_controller.dart';

/// Recomendaciones personalizadas para la clienta autenticada (Fase 19).
/// Se recalculan solas cuando cambian los últimos productos consultados
/// (ver RecentlyViewedController), sin que la pantalla tenga que pedirlo
/// explícitamente.
final recommendationsProvider = FutureProvider<List<Product>>((ref) async {
  final recentlyViewed = ref.watch(recentlyViewedControllerProvider);
  final result = await ref.read(getRecommendationsUseCaseProvider).call(
        recentlyViewedProductIds: recentlyViewed,
      );

  if (result case ResultError(:final failure)) {
    throw failure;
  }
  return (result as Success<List<Product>>).data;
});
