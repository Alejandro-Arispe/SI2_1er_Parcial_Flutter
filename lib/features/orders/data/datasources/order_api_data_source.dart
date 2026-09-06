import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/orders/data/datasources/order_data_source.dart';
import 'package:fashion_store/features/orders/data/models/order_model.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';

/// Implementación real: crea el pedido contra FastAPI. El servidor
/// recalcula el total a partir de las variantes y cantidades (nunca se
/// confía en un total calculado en el cliente para cobrar, ver
/// sección 13 del documento); el total enviado aquí es solo para que el
/// mock de desarrollo lo use mientras no hay backend.
class OrderApiDataSource implements OrderDataSource {
  final Dio _dio;

  const OrderApiDataSource(this._dio);

  @override
  Future<List<OrderModel>> getOrders() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.orders);
    return response.data!
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> createOrder({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    Branch? pickupBranch,
    required double total,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.orders,
      data: {
        'items': items.map((item) => {'variant_id': item.variant.id, 'quantity': item.quantity}).toList(),
        'delivery_method': deliveryMethod.name,
        'delivery_address': ?deliveryAddress,
        'branch_id': ?pickupBranch?.id,
      },
    );
    return OrderModel.fromJson(response.data!);
  }

  @override
  Future<OrderModel> payOrder({required String orderId, String? paymentMethodId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.orderPayment(orderId),
      data: {'payment_method_id': ?paymentMethodId},
    );
    return OrderModel.fromJson(response.data!);
  }
}
