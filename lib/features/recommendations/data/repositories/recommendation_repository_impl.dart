import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/favorites/data/repositories/favorite_repository_impl.dart';
import 'package:fashion_store/features/orders/data/repositories/order_repository_impl.dart';
import 'package:fashion_store/features/recommendations/data/datasources/recommendation_api_data_source.dart';
import 'package:fashion_store/features/recommendations/data/datasources/recommendation_data_source.dart';
import 'package:fashion_store/features/recommendations/data/datasources/recommendation_mock_data_source.dart';
import 'package:fashion_store/features/recommendations/domain/repositories/recommendation_repository.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  final RecommendationDataSource _dataSource;

  const RecommendationRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Product>>> getRecommendations({required List<String> recentlyViewedProductIds}) async {
    try {
      return Success(await _dataSource.getRecommendations(recentlyViewedProductIds: recentlyViewedProductIds));
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }
}

final recommendationDataSourceProvider = Provider<RecommendationDataSource>((ref) {
  return AppConfig.useMockData
      ? RecommendationMockDataSource(
          ref.watch(catalogDataSourceProvider),
          ref.watch(favoriteDataSourceProvider),
          ref.watch(orderDataSourceProvider),
        )
      : RecommendationApiDataSource(ref.watch(dioClientProvider));
});

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  return RecommendationRepositoryImpl(ref.watch(recommendationDataSourceProvider));
});
