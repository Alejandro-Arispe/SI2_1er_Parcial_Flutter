import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';

/// Contrato del catálogo: categorías, productos destacados (Home) y
/// listado paginado con filtro por categoría (Catálogo, Fase 7). La
/// búsqueda por texto y los filtros avanzados (talla, color, precio,
/// temporada) se agregan en la Fase 8.
abstract class CatalogRepository {
  Future<Result<List<Category>>> getCategories();

  Future<Result<List<Product>>> getFeaturedProducts();

  Future<Result<List<Product>>> getProducts({
    required int page,
    required int pageSize,
    String? categoryId,
  });
}
