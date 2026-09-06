import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/cart/data/datasources/cart_api_data_source.dart';
import 'package:fashion_store/features/cart/data/datasources/cart_data_source.dart';
import 'package:fashion_store/features/cart/data/datasources/cart_mock_data_source.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/cart/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final CartDataSource _dataSource;

  const CartRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<CartItem>>> getCart() async {
    try {
      return Success(await _dataSource.getCart());
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<CartItem>> addItem({
    required ProductVariant variant,
    required String productId,
    required String productName,
    required String imageUrl,
    required double unitPrice,
    required int quantity,
  }) async {
    try {
      final item = await _dataSource.addItem(
        variant: variant,
        productId: productId,
        productName: productName,
        imageUrl: imageUrl,
        unitPrice: unitPrice,
        quantity: quantity,
      );
      return Success(item);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<void>> updateQuantity(String cartItemId, int quantity) async {
    try {
      await _dataSource.updateQuantity(cartItemId, quantity);
      return const Success(null);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<void>> removeItem(String cartItemId) async {
    try {
      await _dataSource.removeItem(cartItemId);
      return const Success(null);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<void>> clearCart() async {
    try {
      await _dataSource.clearCart();
      return const Success(null);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }
}

final cartDataSourceProvider = Provider<CartDataSource>((ref) {
  return AppConfig.useMockData ? CartMockDataSource() : CartApiDataSource(ref.watch(dioClientProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(ref.watch(cartDataSourceProvider));
});
