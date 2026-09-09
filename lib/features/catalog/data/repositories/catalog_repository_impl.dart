import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/storage/local_storage_service.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/datasources/catalog_api_data_source.dart';
import 'package:fashion_store/features/catalog/data/datasources/catalog_data_source.dart';
import 'package:fashion_store/features/catalog/data/datasources/catalog_mock_data_source.dart';
import 'package:fashion_store/features/catalog/data/repositories/caching_catalog_repository.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch_stock.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_detail.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogDataSource _dataSource;

  const CatalogRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      return Success(await _dataSource.getCategories());
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<List<Product>>> getFeaturedProducts() async {
    try {
      return Success(await _dataSource.getFeaturedProducts());
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<List<Product>>> getProducts({
    required int page,
    required int pageSize,
    String? categoryId,
    String query = '',
    bool onlyAvailable = false,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      return Success(
        await _dataSource.getProducts(
          page: page,
          pageSize: pageSize,
          categoryId: categoryId,
          query: query,
          onlyAvailable: onlyAvailable,
          minPrice: minPrice,
          maxPrice: maxPrice,
        ),
      );
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<ProductDetail>> getProductDetail(String productId) async {
    try {
      return Success(await _dataSource.getProductDetail(productId));
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<List<BranchStock>>> getVariantAvailability(String variantId) async {
    try {
      return Success(await _dataSource.getVariantAvailability(variantId));
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<List<Branch>>> getBranches() async {
    try {
      return Success(await _dataSource.getBranches());
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }
}

final catalogDataSourceProvider = Provider<CatalogDataSource>((ref) {
  return AppConfig.useMockData
      ? const CatalogMockDataSource()
      : CatalogApiDataSource(ref.watch(dioClientProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final baseRepository = CatalogRepositoryImpl(ref.watch(catalogDataSourceProvider));
  // Se envuelve con la caché offline (Fase 23) para todos los modos: en
  // mock nunca se activa el camino de respaldo (el mock no falla por
  // conectividad), pero deja el catálogo real listo para funcionar sin
  // conexión apenas se conecte al backend (Fase 24).
  return CachingCatalogRepository(baseRepository, ref.watch(localStorageServiceProvider));
});
