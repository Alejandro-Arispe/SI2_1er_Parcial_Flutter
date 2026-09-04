import 'package:fashion_store/features/catalog/data/models/product_color_model.dart';
import 'package:fashion_store/features/catalog/data/models/product_size_model.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';

class ProductVariantModel extends ProductVariant {
  const ProductVariantModel({
    required super.id,
    required super.productId,
    required ProductSizeModel super.size,
    required ProductColorModel super.color,
    required super.isAvailable,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      size: ProductSizeModel.fromJson(json['size'] as Map<String, dynamic>),
      color: ProductColorModel.fromJson(json['color'] as Map<String, dynamic>),
      isAvailable: json['is_available'] as bool,
    );
  }
}
