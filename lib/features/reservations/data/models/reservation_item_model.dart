import 'package:fashion_store/features/catalog/data/models/product_variant_model.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';

class ReservationItemModel extends ReservationItem {
  const ReservationItemModel({
    required super.productId,
    required super.productName,
    required super.imageUrl,
    required super.variant,
    required super.quantity,
  });

  factory ReservationItemModel.fromJson(Map<String, dynamic> json) {
    return ReservationItemModel(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      imageUrl: json['image_url'] as String,
      variant: ProductVariantModel.fromJson(
        json['variant'] as Map<String, dynamic>,
      ),
      quantity: json['quantity'] as int,
    );
  }
}
