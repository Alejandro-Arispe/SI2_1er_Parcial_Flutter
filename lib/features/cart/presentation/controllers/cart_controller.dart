import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:fashion_store/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:fashion_store/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:fashion_store/features/cart/domain/usecases/remove_from_cart_usecase.dart';
import 'package:fashion_store/features/cart/domain/usecases/update_cart_item_quantity_usecase.dart';

class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final Failure? error;

  const CartState({required this.items, required this.isLoading, required this.error});

  factory CartState.initial() => const CartState(items: [], isLoading: true, error: null);

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
}

/// Controller del carrito (Fase 13). El carrito es accesible sin sesión
/// iniciada (ver sección 21 y el comentario en CartPage): el login se
/// exige recién al pasar a checkout, no para ver o modificar el carrito.
class CartController extends Notifier<CartState> {
  @override
  CartState build() {
    _load(); // no debe tocar state antes del primer await (ver FavoritesController)
    return CartState.initial();
  }

  Future<void> _load() async {
    final result = await ref.read(getCartUseCaseProvider).call();
    state = switch (result) {
      Success(:final data) => CartState(items: data, isLoading: false, error: null),
      ResultError(:final failure) => CartState(items: state.items, isLoading: false, error: failure),
    };
  }

  Future<void> refresh() => _load();

  /// Agrega una variante al carrito. Devuelve el Result para que la
  /// pantalla que llama (detalle de producto) pueda mostrar una
  /// confirmación o el mensaje de error correspondiente.
  Future<Result<CartItem>> addToCart({
    required ProductVariant variant,
    required String productId,
    required String productName,
    required String imageUrl,
    required double unitPrice,
    int quantity = 1,
  }) async {
    final result = await ref.read(addToCartUseCaseProvider).call(
          variant: variant,
          productId: productId,
          productName: productName,
          imageUrl: imageUrl,
          unitPrice: unitPrice,
          quantity: quantity,
        );

    // Se recarga en lugar de actualizar de forma optimista porque el
    // mock/backend puede fusionar esta cantidad con un ítem ya existente
    // de la misma variante, y el resultado de esa fusión solo lo sabe él.
    if (result case Success()) {
      await _load();
    }
    return result;
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity < 1) {
      await removeItem(cartItemId);
      return;
    }

    final previousItems = state.items;
    state = CartState(
      items: [
        for (final item in previousItems)
          if (item.id == cartItemId) item.copyWith(quantity: quantity) else item,
      ],
      isLoading: false,
      error: null,
    );

    final result = await ref.read(updateCartItemQuantityUseCaseProvider).call(cartItemId, quantity);
    if (result case ResultError()) {
      state = CartState(items: previousItems, isLoading: false, error: null);
    }
  }

  Future<void> removeItem(String cartItemId) async {
    final previousItems = state.items;
    state = CartState(
      items: previousItems.where((item) => item.id != cartItemId).toList(),
      isLoading: false,
      error: null,
    );

    final result = await ref.read(removeFromCartUseCaseProvider).call(cartItemId);
    if (result case ResultError()) {
      state = CartState(items: previousItems, isLoading: false, error: null);
    }
  }

  /// Vacía el carrito tras confirmar un pedido en checkout (Fase 15).
  Future<Result<void>> clearCart() async {
    final previousItems = state.items;
    state = CartState(items: const [], isLoading: false, error: null);

    final result = await ref.read(clearCartUseCaseProvider).call();
    if (result case ResultError()) {
      state = CartState(items: previousItems, isLoading: false, error: null);
    }
    return result;
  }
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(CartController.new);
