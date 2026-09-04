import 'package:fashion_store/features/catalog/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.categoryId,
    required super.basePrice,
    required super.imageUrl,
    required super.isAvailable,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      isAvailable: json['is_available'] as bool,
    );
  }
}
