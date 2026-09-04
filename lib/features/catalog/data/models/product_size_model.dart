import 'package:fashion_store/features/catalog/domain/entities/product_size.dart';

class ProductSizeModel extends ProductSize {
  const ProductSizeModel({required super.id, required super.label});

  factory ProductSizeModel.fromJson(Map<String, dynamic> json) {
    return ProductSizeModel(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}
