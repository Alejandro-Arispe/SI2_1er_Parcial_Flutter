import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/cart/data/datasources/cart_data_source.dart';
import 'package:fashion_store/features/cart/data/models/cart_item_model.dart';

/// Datasource temporal de desarrollo: guarda los ítems del carrito en
/// memoria (ver sección 42 del documento del proyecto).
///
/// La lista se guarda en un `static final`, no en una instancia, por el
/// mismo motivo que FavoriteMockDataSource: persistir mientras dure la
/// sesión de desarrollo aunque se reconstruya el datasource.
class CartMockDataSource implements CartDataSource {
  static final List<CartItemModel> _items = [];
  static int _nextId = 1;

  @override
  Future<List<CartItemModel>> getCart() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_items);
  }

  @override
  Future<CartItemModel> addItem({
    required ProductVariant variant,
    required String productId,
    required String productName,
    required String imageUrl,
    required double unitPrice,
    required int quantity,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final existingIndex = _items.indexWhere((item) => item.variant.id == variant.id);
    if (existingIndex != -1) {
      final merged = CartItemModel(
        id: _items[existingIndex].id,
        productId: _items[existingIndex].productId,
        productName: _items[existingIndex].productName,
        imageUrl: _items[existingIndex].imageUrl,
        variant: _items[existingIndex].variant,
        unitPrice: _items[existingIndex].unitPrice,
        quantity: _items[existingIndex].quantity + quantity,
      );
      _items[existingIndex] = merged;
      return merged;
    }

    final item = CartItemModel(
      id: 'cart-item-${_nextId++}',
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      variant: variant,
      unitPrice: unitPrice,
      quantity: quantity,
    );
    _items.add(item);
    return item;
  }

  @override
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return;
    _items[index] = CartItemModel(
      id: _items[index].id,
      productId: _items[index].productId,
      productName: _items[index].productName,
      imageUrl: _items[index].imageUrl,
      variant: _items[index].variant,
      unitPrice: _items[index].unitPrice,
      quantity: quantity,
    );
  }

  @override
  Future<void> removeItem(String cartItemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _items.removeWhere((item) => item.id == cartItemId);
  }

  @override
  Future<void> clearCart() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _items.clear();
  }
}
