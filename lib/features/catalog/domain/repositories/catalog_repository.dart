import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch_stock.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_detail.dart';

/// Contrato del catálogo: categorías, productos destacados (Home) y
/// listado paginado con búsqueda por texto y filtros (categoría,
/// disponibilidad, rango de precio; ver Fase 8). Los filtros de talla,
/// color y temporada se agregan cuando exista el modelo de variantes
/// (Fase 10): no tiene sentido filtrar por un dato que el producto
/// todavía no tiene.
abstract class CatalogRepository {
  Future<Result<List<Category>>> getCategories();

  Future<Result<List<Product>>> getFeaturedProducts();

  Future<Result<List<Product>>> getProducts({
    required int page,
    required int pageSize,
    String? categoryId,
    String query = '',
    bool onlyAvailable = false,
    double? minPrice,
    double? maxPrice,
  });

  Future<Result<ProductDetail>> getProductDetail(String productId);

  Future<Result<List<BranchStock>>> getVariantAvailability(String variantId);
}
