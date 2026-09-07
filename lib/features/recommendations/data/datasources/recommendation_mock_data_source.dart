import 'package:fashion_store/features/catalog/data/datasources/catalog_data_source.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';
import 'package:fashion_store/features/favorites/data/datasources/favorite_data_source.dart';
import 'package:fashion_store/features/orders/data/datasources/order_data_source.dart';
import 'package:fashion_store/features/recommendations/data/datasources/recommendation_data_source.dart';

/// Cuántas categorías distintas se usan como base de la recomendación.
/// Un número bajo mantiene las sugerencias enfocadas en lo que
/// realmente le interesa a la clienta, en lugar de diluirlas en todo el
/// catálogo.
const _topCategoryCount = 2;
const _maxRecommendations = 6;

/// Datasource temporal de desarrollo: combina señales reales del
/// catálogo (ver sección 42 del documento del proyecto) en lugar de
/// llamar a un servicio de IA. Las señales, de más a menos fuertes
/// (sección 16 del documento):
///
/// - Historial de compras: ya pagó por algo de esa categoría.
/// - Favoritos: la marcó a propósito, pero todavía no la compró.
/// - Últimos productos consultados: solo la miró de pasada.
///
/// Nunca inventa productos (sección 15): todo sale de
/// CatalogDataSource.getProducts, igual que el resto del catálogo.
class RecommendationMockDataSource implements RecommendationDataSource {
  final CatalogDataSource _catalogDataSource;
  final FavoriteDataSource _favoriteDataSource;
  final OrderDataSource _orderDataSource;

  RecommendationMockDataSource(this._catalogDataSource, this._favoriteDataSource, this._orderDataSource);

  @override
  Future<List<ProductModel>> getRecommendations({required List<String> recentlyViewedProductIds}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Las tres señales son independientes entre sí: se piden en paralelo
    // (los Future ya arrancan al llamarlos) en lugar de encadenar sus
    // latencias una tras otra.
    final productsFuture = _catalogDataSource.getProducts(page: 1, pageSize: 200);
    final favoritesFuture = _favoriteDataSource.getFavorites();
    final ordersFuture = _orderDataSource.getOrders();

    final allProducts = await productsFuture;
    final favorites = await favoritesFuture;
    final orders = await ordersFuture;

    final productsById = {for (final product in allProducts) product.id: product};

    final categoryScores = <String, int>{};
    void addSignal(String? categoryId, int weight) {
      if (categoryId == null) return;
      categoryScores.update(categoryId, (score) => score + weight, ifAbsent: () => weight);
    }

    for (final order in orders) {
      for (final item in order.items) {
        addSignal(productsById[item.productId]?.categoryId, 3);
      }
    }
    for (final product in favorites) {
      addSignal(product.categoryId, 2);
    }
    for (final productId in recentlyViewedProductIds) {
      addSignal(productsById[productId]?.categoryId, 1);
    }

    final excludedIds = <String>{
      ...favorites.map((product) => product.id),
      for (final order in orders) for (final item in order.items) item.productId,
    };

    // Sin ninguna señal (clienta nueva o sin sesión), no hay base real
    // para personalizar: se muestran productos disponibles al azar del
    // catálogo en lugar de simular un gusto que no se conoce.
    if (categoryScores.isEmpty) {
      return allProducts.where((product) => product.isAvailable).take(_maxRecommendations).toList();
    }

    final topCategoryIds = (categoryScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(_topCategoryCount)
        .map((entry) => entry.key)
        .toSet();

    final recommended = allProducts
        .where(
          (product) =>
              topCategoryIds.contains(product.categoryId) &&
              product.isAvailable &&
              !excludedIds.contains(product.id),
        )
        .take(_maxRecommendations)
        .toList();

    return recommended;
  }
}
