import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/cart/data/models/cart_item_model.dart';

/// Contrato común para las fuentes de datos del carrito. Dos
/// implementaciones intercambiables: CartApiDataSource (real, contra
/// FastAPI) y CartMockDataSource (temporal, datos de desarrollo).
abstract class CartDataSource {
  Future<List<CartItemModel>> getCart();

  Future<CartItemModel> addItem({
    required ProductVariant variant,
    required String productId,
    required String productName,
    required String imageUrl,
    required double unitPrice,
    required int quantity,
  });

  Future<void> updateQuantity(String cartItemId, int quantity);

  Future<void> removeItem(String cartItemId);

  Future<void> clearCart();
}
