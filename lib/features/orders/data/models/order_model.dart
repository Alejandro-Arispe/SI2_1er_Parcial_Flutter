import 'package:fashion_store/features/catalog/data/models/branch_model.dart';
import 'package:fashion_store/features/cart/data/models/cart_item_model.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.items,
    required super.deliveryMethod,
    required super.deliveryAddress,
    required super.pickupBranch,
    required super.total,
    required super.status,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
          .toList(),
      deliveryMethod: DeliveryMethod.values.byName(json['delivery_method'] as String),
      deliveryAddress: json['delivery_address'] as String?,
      pickupBranch: json['pickup_branch'] == null
          ? null
          : BranchModel.fromJson(json['pickup_branch'] as Map<String, dynamic>),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
