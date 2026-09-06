import 'package:fashion_store/features/catalog/data/models/branch_model.dart';
import 'package:fashion_store/features/catalog/data/models/branch_stock_model.dart';
import 'package:fashion_store/features/catalog/data/models/category_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_detail_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';

/// Contrato común para las fuentes de datos del catálogo. Dos
/// implementaciones intercambiables: CatalogApiDataSource (real, contra
/// FastAPI) y CatalogMockDataSource (temporal, datos de desarrollo).
abstract class CatalogDataSource {
  Future<List<CategoryModel>> getCategories();

  Future<List<ProductModel>> getFeaturedProducts();

  /// Listado paginado del catálogo, con búsqueda por texto y filtros
  /// (categoría, disponibilidad, rango de precio). `page` comienza en 1.
  /// Menos resultados que `pageSize` indica que no hay más páginas.
  ///
  /// No incluye filtro por talla/color/temporada: esos datos viven en la
  /// variante del producto (ProductVariant), que se modela recién en la
  /// Fase 10. Filtrar por algo que el producto todavía no tiene sería
  /// simular un dato que no existe (ver sección 35 del documento).
  Future<List<ProductModel>> getProducts({
    required int page,
    required int pageSize,
    String? categoryId,
    String query = '',
    bool onlyAvailable = false,
    double? minPrice,
    double? maxPrice,
  });

  /// Detalle completo de un producto (descripción, galería). Lanza
  /// ServerException si no existe un producto con ese id.
  Future<ProductDetailModel> getProductDetail(String productId);

  /// Disponibilidad de una variante concreta (talla + color) por
  /// sucursal (ver sección 8 del documento). Se consulta recién cuando
  /// el cliente eligió ambas, porque antes de eso no hay una variante
  /// concreta sobre la cual consultar stock.
  Future<List<BranchStockModel>> getVariantAvailability(String variantId);

  /// Sucursales físicas de la empresa (ver sección 8 del documento).
  /// Usado por reservas (Fase 14) y por la selección de recojo en
  /// checkout (Fase 15); a diferencia de getVariantAvailability, no
  /// depende de una variante concreta.
  Future<List<BranchModel>> getBranches();
}
