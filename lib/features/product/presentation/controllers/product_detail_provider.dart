import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_detail.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_product_detail_usecase.dart';

/// Carga el detalle de un producto (Fase 9).
///
/// Es un FutureProvider.family en lugar de un Notifier porque esta
/// pantalla, por ahora, solo lee datos: no hay acciones del usuario que
/// muten este estado (eso llega con variantes/carrito en fases
/// posteriores). `family` crea una instancia independiente por
/// productId, y ref.invalidate/ref.refresh sirven para reintentar.
final productDetailProvider = FutureProvider.family<ProductDetail, String>((ref, productId) async {
  final result = await ref.read(getProductDetailUseCaseProvider).call(productId);

  if (result case ResultError(:final failure)) {
    throw failure;
  }
  return (result as Success<ProductDetail>).data;
});
