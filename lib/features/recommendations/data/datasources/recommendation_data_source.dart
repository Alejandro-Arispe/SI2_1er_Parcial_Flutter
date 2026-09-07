import 'package:fashion_store/features/catalog/data/models/product_model.dart';

/// Contrato común para las fuentes de datos de recomendaciones. Dos
/// implementaciones intercambiables: RecommendationApiDataSource (real,
/// contra FastAPI) y RecommendationMockDataSource (temporal, datos de
/// desarrollo).
abstract class RecommendationDataSource {
  Future<List<ProductModel>> getRecommendations({required List<String> recentlyViewedProductIds});
}
