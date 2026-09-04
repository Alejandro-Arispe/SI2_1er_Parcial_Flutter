import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/category.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_categories_usecase.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_featured_products_usecase.dart';

/// Datos que necesita la pantalla Home: categorías destacadas y
/// productos destacados.
class HomeData {
  final List<Category> categories;
  final List<Product> featuredProducts;

  const HomeData({required this.categories, required this.featuredProducts});
}

/// Carga los datos de Home. Se usa AsyncNotifier (API manual de
/// Riverpod 3, sin generación de código) porque el estado inicial
/// depende de una operación asíncrona (consultar el catálogo).
class HomeController extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() => _load();

  Future<HomeData> _load() async {
    final categoriesResult = await ref.read(getCategoriesUseCaseProvider).call();
    final productsResult = await ref.read(getFeaturedProductsUseCaseProvider).call();

    if (categoriesResult case ResultError(:final failure)) throw failure;
    if (productsResult case ResultError(:final failure)) throw failure;

    return HomeData(
      categories: (categoriesResult as Success<List<Category>>).data,
      featuredProducts: (productsResult as Success<List<Product>>).data,
    );
  }

  /// Reintenta la carga tras un error, o refresca manualmente (pull to
  /// refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeData>(HomeController.new);
