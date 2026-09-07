import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product.dart';
import 'package:fashion_store/features/try_on/domain/entities/try_on_result.dart';
import 'package:fashion_store/features/try_on/domain/usecases/generate_try_on_usecase.dart';

class TryOnState {
  final Product? product;
  final String? colorHex;
  final Uint8List? photoBytes;
  final bool isGenerating;
  final TryOnResult? result;
  final Failure? error;

  const TryOnState({
    this.product,
    this.colorHex,
    this.photoBytes,
    this.isGenerating = false,
    this.result,
    this.error,
  });

  TryOnState copyWith({
    Uint8List? photoBytes,
    bool? isGenerating,
    TryOnResult? result,
    Failure? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return TryOnState(
      product: product,
      colorHex: colorHex,
      photoBytes: photoBytes ?? this.photoBytes,
      isGenerating: isGenerating ?? this.isGenerating,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controla el flujo del probador virtual por fotografía (Fase 20, ver
/// sección 17 del documento): elegir prenda, elegir/tomar foto y generar
/// la vista previa. Es `autoDispose` a propósito: al salir de la pantalla
/// se descarta la foto y el resultado de memoria (sección 17.4, reglas de
/// privacidad de fotos: nada de conservarlas más de lo necesario).
class TryOnController extends Notifier<TryOnState> {
  @override
  TryOnState build() => const TryOnState();

  /// Reinicia el estado con la prenda elegida: cambiar de prenda descarta
  /// cualquier foto o resultado anterior, ya no corresponden a ella.
  void selectProduct(Product product, {String? colorHex}) {
    state = TryOnState(product: product, colorHex: colorHex);
  }

  void setPhoto(Uint8List bytes) {
    state = state.copyWith(photoBytes: bytes, clearResult: true, clearError: true);
  }

  Future<void> generate() async {
    final product = state.product;
    final photoBytes = state.photoBytes;
    if (product == null || photoBytes == null) return;

    state = state.copyWith(isGenerating: true, clearError: true);

    final result = await ref.read(generateTryOnUseCaseProvider).call(
      photoBytes: photoBytes,
      productId: product.id,
      productName: product.name,
      colorHex: state.colorHex,
    );

    state = switch (result) {
      Success(:final data) => state.copyWith(isGenerating: false, result: data),
      ResultError(:final failure) => state.copyWith(isGenerating: false, error: failure),
    };
  }
}

final tryOnControllerProvider = NotifierProvider.autoDispose<TryOnController, TryOnState>(
  TryOnController.new,
);
