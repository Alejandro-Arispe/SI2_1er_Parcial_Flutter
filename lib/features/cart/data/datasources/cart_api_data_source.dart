import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/cart/data/datasources/cart_data_source.dart';
import 'package:fashion_store/features/cart/data/models/cart_item_model.dart';

/// Implementación real: consulta los endpoints de carrito de FastAPI.
/// El servidor resuelve nombre/imagen/precio a partir de variant_id, así
/// que solo se envían los identificadores necesarios.
class CartApiDataSource implements CartDataSource {
  final Dio _dio;

  const CartApiDataSource(this._dio);

  @override
  Future<List<CartItemModel>> getCart() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.cart);
    return response.data!
        .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
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
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.cartItems,
      data: {'variant_id': variant.id, 'quantity': quantity},
    );
    return CartItemModel.fromJson(response.data!);
  }

  @override
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _dio.patch<void>(ApiEndpoints.cartItem(cartItemId), data: {'quantity': quantity});
  }

  @override
  Future<void> removeItem(String cartItemId) async {
    await _dio.delete<void>(ApiEndpoints.cartItem(cartItemId));
  }

  @override
  Future<void> clearCart() async {
    await _dio.delete<void>(ApiEndpoints.cart);
  }
}
