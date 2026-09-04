import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_categories_usecase.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_products_usecase.dart';

/// Estado de la pantalla de catálogo: categorías (para los chips de
/// filtro), la búsqueda y filtros activos, la página de productos
/// acumulada hasta el momento, y las banderas de carga necesarias para
/// distinguir "cargando por primera vez" de "cargando la siguiente
/// página" (no deben mostrar la misma UI).
class CatalogState {
  final List<Category> categories;
  final List<Product> products;
  final int page;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Failure? error;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool onlyAvailable;
  final double? minPrice;
  final double? maxPrice;

  const CatalogState({
    required this.categories,
    required this.products,
    required this.page,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.onlyAvailable,
    required this.minPrice,
    required this.maxPrice,
  });

  /// Indica si hay algún filtro (además de la categoría) activo, para
  /// mostrar un indicador visual en el botón de filtros.
  bool get hasActiveFilters => onlyAvailable || minPrice != null || maxPrice != null;

  factory CatalogState.initial() => const CatalogState(
        categories: [],
        products: [],
        page: 0,
        isInitialLoading: true,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        selectedCategoryId: null,
        searchQuery: '',
        onlyAvailable: false,
        minPrice: null,
        maxPrice: null,
      );
}

/// Controla la carga paginada del catálogo, la búsqueda por texto y los
/// filtros (categoría, disponibilidad, rango de precio).
///
/// No usa AsyncValue porque necesita distinguir la carga inicial (que
/// reemplaza toda la pantalla por un loader) de "cargar más" (que debe
/// mantener visibles los productos ya cargados mientras llega la
/// siguiente página).
class CatalogController extends Notifier<CatalogState> {
  static const _pageSize = 12;

  @override
  CatalogState build() {
    // IMPORTANTE: build() todavía no terminó de inicializar el provider
    // en este punto, así que _loadFirstPage() no debe leer ni escribir
    // `state` antes de su primer await (Riverpod lanza "Tried to read
    // the state of an uninitialized provider" si se hace).
    _loadFirstPage();
    return CatalogState.initial();
  }

  Future<void> _loadFirstPage() async {
    final categoriesResult = await ref.read(getCategoriesUseCaseProvider).call();

    if (categoriesResult case ResultError(:final failure)) {
      state = CatalogState(
        categories: const [],
        products: const [],
        page: 0,
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: false,
        error: failure,
        selectedCategoryId: null,
        searchQuery: '',
        onlyAvailable: false,
        minPrice: null,
        maxPrice: null,
      );
      return;
    }
    final categories = (categoriesResult as Success<List<Category>>).data;

    final productsResult =
        await ref.read(getProductsUseCaseProvider).call(page: 1, pageSize: _pageSize);

    state = _stateAfterFirstPage(
      categories: categories,
      result: productsResult,
      categoryId: null,
      query: '',
      onlyAvailable: false,
      minPrice: null,
      maxPrice: null,
    );
  }

  /// Recarga desde la primera página con el conjunto de filtros dado.
  /// Se llama solo desde la UI (categoría, búsqueda, filtros, refresh),
  /// siempre después de que build() ya terminó, así que aquí sí es
  /// seguro leer/escribir `state` de inmediato (mismo patrón que
  /// LoginController.submit).
  Future<void> _reload({
    required String? categoryId,
    required String query,
    required bool onlyAvailable,
    required double? minPrice,
    required double? maxPrice,
  }) async {
    state = CatalogState(
      categories: state.categories,
      products: const [],
      page: 0,
      isInitialLoading: true,
      isLoadingMore: false,
      hasMore: true,
      error: null,
      selectedCategoryId: categoryId,
      searchQuery: query,
      onlyAvailable: onlyAvailable,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    final productsResult = await ref.read(getProductsUseCaseProvider).call(
          page: 1,
          pageSize: _pageSize,
          categoryId: categoryId,
          query: query,
          onlyAvailable: onlyAvailable,
          minPrice: minPrice,
          maxPrice: maxPrice,
        );

    state = _stateAfterFirstPage(
      categories: state.categories,
      result: productsResult,
      categoryId: categoryId,
      query: query,
      onlyAvailable: onlyAvailable,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  Future<void> selectCategory(String? categoryId) => _reload(
        categoryId: categoryId,
        query: state.searchQuery,
        onlyAvailable: state.onlyAvailable,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      );

  Future<void> search(String query) => _reload(
        categoryId: state.selectedCategoryId,
        query: query,
        onlyAvailable: state.onlyAvailable,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      );

  Future<void> applyFilters({
    required bool onlyAvailable,
    required double? minPrice,
    required double? maxPrice,
  }) =>
      _reload(
        categoryId: state.selectedCategoryId,
        query: state.searchQuery,
        onlyAvailable: onlyAvailable,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

  Future<void> refresh() => _reload(
        categoryId: state.selectedCategoryId,
        query: state.searchQuery,
        onlyAvailable: state.onlyAvailable,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      );

  CatalogState _stateAfterFirstPage({
    required List<Category> categories,
    required Result<List<Product>> result,
    required String? categoryId,
    required String query,
    required bool onlyAvailable,
    required double? minPrice,
    required double? maxPrice,
  }) {
    switch (result) {
      case Success(data: final products):
        return CatalogState(
          categories: categories,
          products: products,
          page: 1,
          isInitialLoading: false,
          isLoadingMore: false,
          hasMore: products.length == _pageSize,
          error: null,
          selectedCategoryId: categoryId,
          searchQuery: query,
          onlyAvailable: onlyAvailable,
          minPrice: minPrice,
          maxPrice: maxPrice,
        );
      case ResultError(failure: final failure):
        return CatalogState(
          categories: categories,
          products: const [],
          page: 0,
          isInitialLoading: false,
          isLoadingMore: false,
          hasMore: false,
          error: failure,
          selectedCategoryId: categoryId,
          searchQuery: query,
          onlyAvailable: onlyAvailable,
          minPrice: minPrice,
          maxPrice: maxPrice,
        );
    }
  }

  /// Carga la siguiente página y la agrega al final del listado actual.
  /// Se ignora si ya hay una carga en curso o no quedan más páginas.
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isInitialLoading || !state.hasMore) return;

    state = CatalogState(
      categories: state.categories,
      products: state.products,
      page: state.page,
      isInitialLoading: false,
      isLoadingMore: true,
      hasMore: state.hasMore,
      error: null,
      selectedCategoryId: state.selectedCategoryId,
      searchQuery: state.searchQuery,
      onlyAvailable: state.onlyAvailable,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
    );

    final nextPage = state.page + 1;
    final result = await ref.read(getProductsUseCaseProvider).call(
          page: nextPage,
          pageSize: _pageSize,
          categoryId: state.selectedCategoryId,
          query: state.searchQuery,
          onlyAvailable: state.onlyAvailable,
          minPrice: state.minPrice,
          maxPrice: state.maxPrice,
        );

    switch (result) {
      case Success(data: final products):
        state = CatalogState(
          categories: state.categories,
          products: [...state.products, ...products],
          page: nextPage,
          isInitialLoading: false,
          isLoadingMore: false,
          hasMore: products.length == _pageSize,
          error: null,
          selectedCategoryId: state.selectedCategoryId,
          searchQuery: state.searchQuery,
          onlyAvailable: state.onlyAvailable,
          minPrice: state.minPrice,
          maxPrice: state.maxPrice,
        );
      case ResultError():
        // No se borra lo ya cargado ante un error al pedir más
        // resultados: solo se deja de intentar automáticamente.
        state = CatalogState(
          categories: state.categories,
          products: state.products,
          page: state.page,
          isInitialLoading: false,
          isLoadingMore: false,
          hasMore: false,
          error: null,
          selectedCategoryId: state.selectedCategoryId,
          searchQuery: state.searchQuery,
          onlyAvailable: state.onlyAvailable,
          minPrice: state.minPrice,
          maxPrice: state.maxPrice,
        );
    }
  }
}

final catalogControllerProvider = NotifierProvider<CatalogController, CatalogState>(CatalogController.new);
