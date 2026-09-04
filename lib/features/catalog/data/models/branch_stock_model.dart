import 'package:fashion_store/features/catalog/data/models/branch_model.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch_stock.dart';

class BranchStockModel extends BranchStock {
  const BranchStockModel({
    required BranchModel super.branch,
    required super.isAvailable,
    required super.stock,
  });

  factory BranchStockModel.fromJson(Map<String, dynamic> json) {
    return BranchStockModel(
      branch: BranchModel.fromJson(json['branch'] as Map<String, dynamic>),
      isAvailable: json['is_available'] as bool,
      stock: json['stock'] as int,
    );
  }
}
