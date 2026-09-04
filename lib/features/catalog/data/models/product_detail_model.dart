import 'package:fashion_store/features/catalog/data/models/product_variant_model.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_detail.dart';

class ProductDetailModel extends ProductDetail {
  const ProductDetailModel({
    required super.id,
    required super.name,
    required super.description,
    required super.categoryId,
    required super.categoryName,
    required super.basePrice,
    required super.imageUrls,
    required super.isAvailable,
    required List<ProductVariantModel> super.variants,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      imageUrls: (json['image_urls'] as List<dynamic>).cast<String>(),
      isAvailable: json['is_available'] as bool,
      variants: (json['variants'] as List<dynamic>)
          .map((json) => ProductVariantModel.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }
}
