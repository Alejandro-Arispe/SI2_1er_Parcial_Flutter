import 'package:fashion_store/features/catalog/data/models/product_variant_model.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.imageUrl,
    required super.variant,
    required super.unitPrice,
    required super.quantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      imageUrl: json['image_url'] as String,
      variant: ProductVariantModel.fromJson(json['variant'] as Map<String, dynamic>),
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}
