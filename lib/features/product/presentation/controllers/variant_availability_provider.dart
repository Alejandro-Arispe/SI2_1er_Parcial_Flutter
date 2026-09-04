import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch_stock.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_variant_availability_usecase.dart';

/// Carga la disponibilidad por sucursal de una variante concreta
/// (Fase 11). Igual que productDetailProvider, es un FutureProvider ya
/// que solo lee datos; se crea una instancia por variantId con family.
final variantAvailabilityProvider = FutureProvider.family<List<BranchStock>, String>((ref, variantId) async {
  final result = await ref.read(getVariantAvailabilityUseCaseProvider).call(variantId);

  if (result case ResultError(:final failure)) {
    throw failure;
  }
  return (result as Success<List<BranchStock>>).data;
});
