import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/try_on/data/datasources/try_on_api_data_source.dart';
import 'package:fashion_store/features/try_on/data/datasources/try_on_data_source.dart';
import 'package:fashion_store/features/try_on/data/datasources/try_on_mock_data_source.dart';
import 'package:fashion_store/features/try_on/domain/entities/try_on_result.dart';
import 'package:fashion_store/features/try_on/domain/repositories/try_on_repository.dart';

class TryOnRepositoryImpl implements TryOnRepository {
  final TryOnDataSource _dataSource;

  const TryOnRepositoryImpl(this._dataSource);

  @override
  Future<Result<TryOnResult>> generate({
    required Uint8List photoBytes,
    required String productId,
    required String productName,
    String? colorHex,
  }) async {
    try {
      return Success(
        await _dataSource.generate(
          photoBytes: photoBytes,
          productId: productId,
          productName: productName,
          colorHex: colorHex,
        ),
      );
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }
}

final tryOnDataSourceProvider = Provider<TryOnDataSource>((ref) {
  return AppConfig.useMockData
      ? const TryOnMockDataSource()
      : TryOnApiDataSource(ref.watch(dioClientProvider));
});

final tryOnRepositoryProvider = Provider<TryOnRepository>((ref) {
  return TryOnRepositoryImpl(ref.watch(tryOnDataSourceProvider));
});
