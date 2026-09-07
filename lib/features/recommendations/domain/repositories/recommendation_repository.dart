import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';

/// Contrato de recomendaciones (Fase 19, ver sección 16 del documento):
/// combina favoritos, historial de compras y últimos productos
/// consultados para sugerir prendas reales del catálogo. Nunca inventa
/// productos (mismo criterio que el asistente, sección 15); si no hay
/// señales suficientes, el datasource decide un resultado razonable
/// (por ejemplo, destacados).
abstract class RecommendationRepository {
  /// [recentlyViewedProductIds] viene de RecentlyViewedController (Fase
  /// 19: estado local, no persistente todavía — el almacenamiento local
  /// llega en la Fase 23), la única señal que no puede leer un
  /// repositorio por sí solo porque vive en la capa de presentación.
  Future<Result<List<Product>>> getRecommendations({
    required List<String> recentlyViewedProductIds,
  });
}
