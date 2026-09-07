import 'dart:typed_data';

import 'package:fashion_store/features/try_on/data/models/try_on_result_model.dart';

abstract class TryOnDataSource {
  Future<TryOnResultModel> generate({
    required Uint8List photoBytes,
    required String productId,
    required String productName,
    String? colorHex,
  });
}
