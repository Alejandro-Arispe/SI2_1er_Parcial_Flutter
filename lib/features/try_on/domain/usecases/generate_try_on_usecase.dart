import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/try_on/data/repositories/try_on_repository_impl.dart';
import 'package:fashion_store/features/try_on/domain/entities/try_on_result.dart';
import 'package:fashion_store/features/try_on/domain/repositories/try_on_repository.dart';

class GenerateTryOnUseCase {
  final TryOnRepository _repository;

  const GenerateTryOnUseCase(this._repository);

  Future<Result<TryOnResult>> call({
    required Uint8List photoBytes,
    required String productId,
    required String productName,
    String? colorHex,
  }) {
    return _repository.generate(
      photoBytes: photoBytes,
      productId: productId,
      productName: productName,
      colorHex: colorHex,
    );
  }
}

final generateTryOnUseCaseProvider = Provider<GenerateTryOnUseCase>((ref) {
  return GenerateTryOnUseCase(ref.watch(tryOnRepositoryProvider));
});
