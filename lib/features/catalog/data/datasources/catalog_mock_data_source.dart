import 'package:fashion_store/features/catalog/data/datasources/catalog_data_source.dart';
import 'package:fashion_store/features/catalog/data/models/category_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';

/// Datasource temporal de desarrollo: catálogo de moda femenina de
/// ejemplo mientras FastAPI no está disponible (ver sección 42 del
/// documento del proyecto). Las imágenes son placeholders públicos de
/// picsum.photos, aislados y fáciles de reemplazar por URLs reales.
class CatalogMockDataSource implements CatalogDataSource {
  const CatalogMockDataSource();

  static const _categories = [
    CategoryModel(id: 'cat-vestidos', name: 'Vestidos', imageUrl: 'https://picsum.photos/seed/cat-vestidos/300/300'),
    CategoryModel(id: 'cat-blusas', name: 'Blusas', imageUrl: 'https://picsum.photos/seed/cat-blusas/300/300'),
    CategoryModel(id: 'cat-pantalones', name: 'Pantalones', imageUrl: 'https://picsum.photos/seed/cat-pantalones/300/300'),
    CategoryModel(id: 'cat-faldas', name: 'Faldas', imageUrl: 'https://picsum.photos/seed/cat-faldas/300/300'),
    CategoryModel(id: 'cat-chaquetas', name: 'Chaquetas', imageUrl: 'https://picsum.photos/seed/cat-chaquetas/300/300'),
    CategoryModel(id: 'cat-zapatos', name: 'Zapatos', imageUrl: 'https://picsum.photos/seed/cat-zapatos/300/300'),
  ];

  // Nombres de ejemplo por categoría, usados para generar un catálogo lo
  // bastante grande como para probar paginación real sin escribir a mano
  // decenas de productos casi idénticos.
  static const _namesByCategory = {
    'cat-vestidos': ['Vestido Floral', 'Vestido Casual', 'Vestido de Noche', 'Vestido Midi'],
    'cat-blusas': ['Blusa Satinada', 'Blusa Manga Larga', 'Blusa Estampada', 'Blusa Cuello V'],
    'cat-pantalones': ['Pantalón Palazzo', 'Pantalón Recto', 'Pantalón Skinny', 'Pantalón Culotte'],
    'cat-faldas': ['Falda Plisada', 'Falda Lápiz', 'Falda Midi', 'Falda Corta'],
    'cat-chaquetas': ['Chaqueta de Mezclilla', 'Chaqueta Blazer', 'Chaqueta Acolchada', 'Chaqueta de Cuero'],
    'cat-zapatos': ['Sandalias de Tacón', 'Zapatillas Urbanas', 'Botines', 'Balerinas'],
  };

  static final List<ProductModel> _allProducts = _generateProducts();

  static List<ProductModel> _generateProducts() {
    final products = <ProductModel>[];
    var counter = 1;
    for (final entry in _namesByCategory.entries) {
      for (final name in entry.value) {
        products.add(
          ProductModel(
            id: 'prod-$counter',
            name: name,
            categoryId: entry.key,
            basePrice: (100 + (counter * 37) % 250).toDouble(),
            imageUrl: 'https://picsum.photos/seed/prod-$counter/400/500',
            // Un producto de cada siete aparece agotado, para poder
            // probar el estado "no disponible" sin ocultar productos.
            isAvailable: counter % 7 != 0,
          ),
        );
        counter++;
      }
    }
    return products;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _categories;
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _allProducts.take(6).toList();
  }

  @override
  Future<List<ProductModel>> getProducts({
    required int page,
    required int pageSize,
    String? categoryId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final filtered = categoryId == null
        ? _allProducts
        : _allProducts.where((product) => product.categoryId == categoryId).toList();

    final start = (page - 1) * pageSize;
    if (start >= filtered.length) return [];

    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }
}
