import 'package:fashion_store/features/catalog/domain/entities/product_color.dart';

class ProductColorModel extends ProductColor {
  const ProductColorModel({
    required super.id,
    required super.name,
    required super.hexValue,
  });

  factory ProductColorModel.fromJson(Map<String, dynamic> json) {
    return ProductColorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      hexValue: json['hex_value'] as String,
    );
  }
}
