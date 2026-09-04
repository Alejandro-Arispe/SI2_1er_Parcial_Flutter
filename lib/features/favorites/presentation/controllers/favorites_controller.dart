import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/favorites/domain/usecases/add_favorite_usecase.dart';
import 'package:fashion_store/features/favorites/domain/usecases/get_favorites_usecase.dart';
import 'package:fashion_store/features/favorites/domain/usecases/remove_favorite_usecase.dart';

/// Estado de favoritos: la lista completa de productos favoritos (para
/// la pantalla de Favoritos) y las banderas de carga/error.
class FavoritesState {
  final List<Product> products;
  final bool isLoading;
  final Failure? error;

  const FavoritesState({required this.products, required this.isLoading, required this.error});

  factory FavoritesState.initial() =>
      const FavoritesState(products: [], isLoading: true, error: null);

  bool isFavorite(String productId) => products.any((product) => product.id == productId);
}

/// Controla los favoritos del cliente. Es un provider global (no ligado
/// a una pantalla concreta) porque el estado "¿este producto es
/// favorito?" lo necesitan Home, Catálogo, Detalle y la propia pantalla
/// de Favoritos al mismo tiempo: mantenerlo en un único lugar evita que
/// el corazón de un producto quede desincronizado entre pantallas.
class FavoritesController extends Notifier<FavoritesState> {
  @override
  FavoritesState build() {
    // IMPORTANTE: igual que CatalogController, _load() no debe leer ni
    // escribir `state` antes de su primer await (el provider todavía
    // se está inicializando durante build()).
    _load();
    return FavoritesState.initial();
  }

  Future<void> _load() async {
    final result = await ref.read(getFavoritesUseCaseProvider).call();
    switch (result) {
      case Success(data: final products):
        state = FavoritesState(products: products, isLoading: false, error: null);
      case ResultError(failure: final failure):
        state = FavoritesState(products: const [], isLoading: false, error: failure);
    }
  }

  Future<void> refresh() async {
    state = FavoritesState(products: state.products, isLoading: true, error: null);
    await _load();
  }

  /// Marca o quita un producto de favoritos. Recibe el Product completo
  /// (no solo el id) para poder actualizar la lista de inmediato sin
  /// esperar al backend; si la llamada falla, revierte el cambio.
  Future<void> toggle(Product product) async {
    final wasFavorite = state.isFavorite(product.id);
    final previousProducts = state.products;

    state = FavoritesState(
      products: wasFavorite
          ? previousProducts.where((p) => p.id != product.id).toList()
          : [...previousProducts, product],
      isLoading: false,
      error: null,
    );

    final result = wasFavorite
        ? await ref.read(removeFavoriteUseCaseProvider).call(product.id)
        : await ref.read(addFavoriteUseCaseProvider).call(product.id);

    if (result case ResultError()) {
      state = FavoritesState(products: previousProducts, isLoading: false, error: null);
    }
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, FavoritesState>(FavoritesController.new);
