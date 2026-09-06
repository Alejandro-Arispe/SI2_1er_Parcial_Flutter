import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/catalog/domain/repositories/catalog_repository.dart';

/// Caso de uso: lista de sucursales físicas de la empresa. Usado por
/// reservas (Fase 14) y por la selección de recojo en checkout (Fase 15).
class GetBranchesUseCase {
  final CatalogRepository _repository;

  const GetBranchesUseCase(this._repository);

  Future<Result<List<Branch>>> call() => _repository.getBranches();
}

final getBranchesUseCaseProvider = Provider<GetBranchesUseCase>((ref) {
  return GetBranchesUseCase(ref.watch(catalogRepositoryProvider));
});
