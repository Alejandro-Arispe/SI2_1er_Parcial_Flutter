import 'package:fashion_store/features/catalog/data/models/product_model.dart';

/// Contrato común para las fuentes de datos de favoritos. Dos
/// implementaciones intercambiables: FavoriteApiDataSource (real,
/// contra FastAPI) y FavoriteMockDataSource (temporal, datos de
/// desarrollo).
abstract class FavoriteDataSource {
  Future<List<ProductModel>> getFavorites();

  Future<void> addFavorite(String productId);

  Future<void> removeFavorite(String productId);
}
