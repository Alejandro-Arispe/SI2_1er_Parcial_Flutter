import 'package:fashion_store/features/catalog/domain/entities/branch.dart';

class BranchModel extends Branch {
  const BranchModel({required super.id, required super.name, required super.city});

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
    );
  }
}
