import 'package:fashion_store/features/catalog/data/datasources/catalog_data_source.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';
import 'package:fashion_store/features/favorites/data/datasources/favorite_data_source.dart';

/// Datasource temporal de desarrollo: guarda los ids favoritos en
/// memoria (ver sección 42 del documento del proyecto) y resuelve los
/// datos completos del producto reutilizando el catálogo, en lugar de
/// duplicar información de producto en un almacén aparte.
///
/// Los ids se guardan en un `static final Set`, no en una instancia,
/// para que persistan mientras dure la sesión de desarrollo aunque se
/// reconstruya el datasource (mismo criterio que el resto de los mocks
/// del proyecto: datos aislados, fáciles de reemplazar por la API real).
class FavoriteMockDataSource implements FavoriteDataSource {
  final CatalogDataSource _catalogDataSource;

  FavoriteMockDataSource(this._catalogDataSource);

  static final Set<String> _favoriteProductIds = {};

  @override
  Future<List<ProductModel>> getFavorites() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_favoriteProductIds.isEmpty) return [];

    // pageSize amplio para cubrir todo el catálogo de desarrollo; en la
    // API real este método simplemente pedirá /favorites al backend,
    // que ya sabe qué productos marcó el cliente.
    final allProducts = await _catalogDataSource.getProducts(page: 1, pageSize: 200);
    return allProducts.where((product) => _favoriteProductIds.contains(product.id)).toList();
  }

  @override
  Future<void> addFavorite(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _favoriteProductIds.add(productId);
  }

  @override
  Future<void> removeFavorite(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _favoriteProductIds.remove(productId);
  }
}
