import 'package:fashion_store/features/catalog/data/models/category_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';

/// Contrato común para las fuentes de datos del catálogo. Dos
/// implementaciones intercambiables: CatalogApiDataSource (real, contra
/// FastAPI) y CatalogMockDataSource (temporal, datos de desarrollo).
abstract class CatalogDataSource {
  Future<List<CategoryModel>> getCategories();

  Future<List<ProductModel>> getFeaturedProducts();

  /// Listado paginado del catálogo, opcionalmente filtrado por
  /// categoría. `page` comienza en 1. Menos resultados que `pageSize`
  /// indica que no hay más páginas.
  Future<List<ProductModel>> getProducts({
    required int page,
    required int pageSize,
    String? categoryId,
  });
}
