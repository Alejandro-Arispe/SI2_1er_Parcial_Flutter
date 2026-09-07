import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/recommendations/data/repositories/recommendation_repository_impl.dart';
import 'package:fashion_store/features/recommendations/domain/repositories/recommendation_repository.dart';

class GetRecommendationsUseCase {
  final RecommendationRepository _repository;

  const GetRecommendationsUseCase(this._repository);

  Future<Result<List<Product>>> call({required List<String> recentlyViewedProductIds}) {
    return _repository.getRecommendations(recentlyViewedProductIds: recentlyViewedProductIds);
  }
}

final getRecommendationsUseCaseProvider = Provider<GetRecommendationsUseCase>((ref) {
  return GetRecommendationsUseCase(ref.watch(recommendationRepositoryProvider));
});
