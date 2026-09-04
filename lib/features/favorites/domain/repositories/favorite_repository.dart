import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';

/// Contrato de favoritos (ver sección 9 del documento del proyecto):
/// marcar, quitar y consultar productos favoritos. Reutiliza la
/// entidad Product del catálogo en lugar de duplicarla, porque un
/// favorito no es más que "este producto, marcado por el cliente".
abstract class FavoriteRepository {
  Future<Result<List<Product>>> getFavorites();

  Future<Result<void>> addFavorite(String productId);

  Future<Result<void>> removeFavorite(String productId);
}
