import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/features/catalog/data/datasources/catalog_data_source.dart';
import 'package:fashion_store/features/catalog/data/models/branch_model.dart';
import 'package:fashion_store/features/catalog/data/models/branch_stock_model.dart';
import 'package:fashion_store/features/catalog/data/models/category_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_color_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_detail_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_size_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_variant_model.dart';

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

  // Tallas y colores de ejemplo, compartidos por todos los productos.
  // En el sistema real, qué tallas/colores aplican a cada producto
  // vendrá determinado por la prenda concreta (no toda la ropa tiene
  // las mismas tallas), pero para datos de desarrollo alcanza con un
  // conjunto fijo razonable.
  static const _sizes = [
    ProductSizeModel(id: 'size-s', label: 'S'),
    ProductSizeModel(id: 'size-m', label: 'M'),
    ProductSizeModel(id: 'size-l', label: 'L'),
    ProductSizeModel(id: 'size-xl', label: 'XL'),
  ];

  static const _colorPalette = [
    ProductColorModel(id: 'color-negro', name: 'Negro', hexValue: '#1A1A1A'),
    ProductColorModel(id: 'color-blanco', name: 'Blanco', hexValue: '#FFFFFF'),
    ProductColorModel(id: 'color-rojo', name: 'Rojo', hexValue: '#C41E3A'),
    ProductColorModel(id: 'color-azul', name: 'Azul', hexValue: '#2A4D8F'),
    ProductColorModel(id: 'color-beige', name: 'Beige', hexValue: '#D9C7A3'),
    ProductColorModel(id: 'color-verde', name: 'Verde', hexValue: '#3F6B4F'),
  ];

  // Sucursales de ejemplo en distintas ciudades (ver sección 8 del
  // documento del proyecto).
  static const _branches = [
    BranchModel(id: 'branch-lapaz', name: 'FashionStore San Miguel', city: 'La Paz'),
    BranchModel(id: 'branch-santacruz', name: 'FashionStore Equipetrol', city: 'Santa Cruz'),
    BranchModel(id: 'branch-cochabamba', name: 'FashionStore Norte', city: 'Cochabamba'),
    BranchModel(id: 'branch-elalto', name: 'FashionStore 16 de Julio', city: 'El Alto'),
  ];

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
    String query = '',
    bool onlyAvailable = false,
    double? minPrice,
    double? maxPrice,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalizedQuery = query.trim().toLowerCase();

    final filtered = _allProducts.where((product) {
      if (categoryId != null && product.categoryId != categoryId) return false;
      if (normalizedQuery.isNotEmpty && !product.name.toLowerCase().contains(normalizedQuery)) {
        return false;
      }
      if (onlyAvailable && !product.isAvailable) return false;
      if (minPrice != null && product.basePrice < minPrice) return false;
      if (maxPrice != null && product.basePrice > maxPrice) return false;
      return true;
    }).toList();

    final start = (page - 1) * pageSize;
    if (start >= filtered.length) return [];

    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Future<ProductDetailModel> getProductDetail(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final matches = _allProducts.where((product) => product.id == productId);
    if (matches.isEmpty) {
      throw const ServerException('Producto no encontrado.', statusCode: 404);
    }
    final product = matches.first;
    final category = _categories.firstWhere((c) => c.id == product.categoryId);

    return ProductDetailModel(
      id: product.id,
      name: product.name,
      description:
          '${product.name} es una prenda de la colección ${category.name}, confeccionada '
          'con materiales de calidad y un corte pensado para el uso diario. Combina '
          'fácilmente con el resto de tu guardarropa.',
      categoryId: product.categoryId,
      categoryName: category.name,
      basePrice: product.basePrice,
      // Galería de ejemplo: 3 imágenes con semillas distintas para el
      // mismo producto, simulando ángulos o vistas diferentes.
      imageUrls: List.generate(
        3,
        (index) => 'https://picsum.photos/seed/${product.id}-$index/800/1000',
      ),
      isAvailable: product.isAvailable,
      variants: _generateVariants(product),
    );
  }

  /// Genera las variantes (talla x color) de un producto. Cada producto
  /// recibe 3 colores de la paleta (elegidos según su posición para que
  /// no todos los productos tengan los mismos 3 colores) combinados con
  /// las 4 tallas. Una de cada cinco combinaciones se marca sin stock,
  /// para poder probar ese estado sin dejar el producto entero agotado.
  List<ProductVariantModel> _generateVariants(ProductModel product) {
    final productIndex = int.parse(product.id.split('-').last);
    final colors = [
      _colorPalette[productIndex % _colorPalette.length],
      _colorPalette[(productIndex + 2) % _colorPalette.length],
      _colorPalette[(productIndex + 4) % _colorPalette.length],
    ];

    final variants = <ProductVariantModel>[];
    var combinationIndex = 0;
    for (final color in colors) {
      for (final size in _sizes) {
        variants.add(
          ProductVariantModel(
            id: '${product.id}-${size.id}-${color.id}',
            productId: product.id,
            size: size,
            color: color,
            isAvailable: (combinationIndex + productIndex) % 5 != 0,
          ),
        );
        combinationIndex++;
      }
    }
    return variants;
  }

  @override
  Future<List<BranchStockModel>> getVariantAvailability(String variantId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Stock pseudo-aleatorio pero determinístico por combinación
    // variante+sucursal (mismo variantId siempre da el mismo resultado),
    // usando el hash de ambos ids en lugar de un generador aleatorio
    // real, para que los datos de desarrollo sean reproducibles.
    return _branches.map((branch) {
      final stock = Object.hash(variantId, branch.id).abs() % 6;
      return BranchStockModel(branch: branch, isAvailable: stock > 0, stock: stock);
    }).toList();
  }
}
