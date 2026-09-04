import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch_stock.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

/// Caso de uso: disponibilidad por sucursal de una variante concreta
/// (Fase 11, ver sección 8 del documento).
class GetVariantAvailabilityUseCase {
  final CatalogRepository _repository;

  const GetVariantAvailabilityUseCase(this._repository);

  Future<Result<List<BranchStock>>> call(String variantId) {
    return _repository.getVariantAvailability(variantId);
  }
}

final getVariantAvailabilityUseCaseProvider = Provider<GetVariantAvailabilityUseCase>((ref) {
  return GetVariantAvailabilityUseCase(ref.watch(catalogRepositoryProvider));
});
