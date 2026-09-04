import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/favorites/data/datasources/favorite_api_data_source.dart';
import 'package:fashion_store/features/favorites/data/datasources/favorite_data_source.dart';
import 'package:fashion_store/features/favorites/data/datasources/favorite_mock_data_source.dart';
import 'package:fashion_store/features/favorites/domain/repositories/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteDataSource _dataSource;

  const FavoriteRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Product>>> getFavorites() async {
    try {
      return Success(await _dataSource.getFavorites());
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<void>> addFavorite(String productId) async {
    try {
      await _dataSource.addFavorite(productId);
      return const Success(null);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<void>> removeFavorite(String productId) async {
    try {
      await _dataSource.removeFavorite(productId);
      return const Success(null);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }
}

final favoriteDataSourceProvider = Provider<FavoriteDataSource>((ref) {
  return AppConfig.useMockData
      ? FavoriteMockDataSource(ref.watch(catalogDataSourceProvider))
      : FavoriteApiDataSource(ref.watch(dioClientProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl(ref.watch(favoriteDataSourceProvider));
});
