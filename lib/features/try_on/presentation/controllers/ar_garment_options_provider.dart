import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_products_usecase.dart';

/// Prendas de la misma categoría que la elegida al entrar al probador
/// AR, para poder cambiar de prenda sin salir de la cámara en vivo
/// (sección 17.2 del documento: "selección/cambio de prendas").
final arGarmentOptionsProvider = FutureProvider.autoDispose.family<List<Product>, String>((
  ref,
  categoryId,
) async {
  final result = await ref.watch(getProductsUseCaseProvider).call(
    page: 1,
    pageSize: 8,
    categoryId: categoryId,
    onlyAvailable: true,
  );

  if (result case ResultError()) return const [];
  return (result as Success<List<Product>>).data;
});
