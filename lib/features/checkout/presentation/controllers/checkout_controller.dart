import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_branches_usecase.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/cart/presentation/controllers/cart_controller.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';
import 'package:fashion_store/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:fashion_store/features/orders/domain/usecases/pay_order_usecase.dart';

class CheckoutState {
  final List<Branch> branches;
  final bool isLoadingBranches;
  final DeliveryMethod deliveryMethod;
  final Branch? selectedBranch;
  final bool isSubmitting;
  final Order? submittedOrder;
  final bool isPaying;
  final Failure? error;
  final Failure? paymentError;

  const CheckoutState({
    required this.branches,
    required this.isLoadingBranches,
    required this.deliveryMethod,
    required this.selectedBranch,
    required this.isSubmitting,
    required this.submittedOrder,
    required this.isPaying,
    required this.error,
    required this.paymentError,
  });

  factory CheckoutState.initial() => const CheckoutState(
        branches: [],
        isLoadingBranches: true,
        deliveryMethod: DeliveryMethod.delivery,
        selectedBranch: null,
        isSubmitting: false,
        submittedOrder: null,
        isPaying: false,
        error: null,
        paymentError: null,
      );

  CheckoutState copyWith({
    List<Branch>? branches,
    bool? isLoadingBranches,
    DeliveryMethod? deliveryMethod,
    Branch? selectedBranch,
    bool clearSelectedBranch = false,
    bool? isSubmitting,
    Order? submittedOrder,
    bool? isPaying,
    Failure? error,
    bool clearError = false,
    Failure? paymentError,
    bool clearPaymentError = false,
  }) {
    return CheckoutState(
      branches: branches ?? this.branches,
      isLoadingBranches: isLoadingBranches ?? this.isLoadingBranches,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      selectedBranch: clearSelectedBranch ? null : (selectedBranch ?? this.selectedBranch),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedOrder: submittedOrder ?? this.submittedOrder,
      isPaying: isPaying ?? this.isPaying,
      error: clearError ? null : (error ?? this.error),
      paymentError: clearPaymentError ? null : (paymentError ?? this.paymentError),
    );
  }
}

/// Controller de checkout (Fases 15 y 16): resumen del carrito, método
/// de entrega, creación del pedido (estado `pendingPayment`) y su pago
/// con Stripe (estado `paid`). La recolección de la tarjeta ocurre en
/// la UI (CardField de flutter_stripe, ver checkout_page.dart): este
/// controller solo recibe el payment_method_id ya tokenizado.
class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    _loadBranches(); // no debe tocar state antes del primer await (ver FavoritesController)
    return CheckoutState.initial();
  }

  Future<void> _loadBranches() async {
    final result = await ref.read(getBranchesUseCaseProvider).call();
    state = switch (result) {
      Success(:final data) => state.copyWith(branches: data, isLoadingBranches: false),
      ResultError(:final failure) => state.copyWith(isLoadingBranches: false, error: failure),
    };
  }

  void selectDeliveryMethod(DeliveryMethod method) {
    state = state.copyWith(deliveryMethod: method, clearSelectedBranch: method == DeliveryMethod.delivery);
  }

  void selectBranch(Branch branch) {
    state = state.copyWith(selectedBranch: branch);
  }

  Future<Result<Order>> submitOrder({
    required List<CartItem> items,
    required double total,
    String? deliveryAddress,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await ref.read(createOrderUseCaseProvider).call(
          items: items,
          deliveryMethod: state.deliveryMethod,
          deliveryAddress: state.deliveryMethod == DeliveryMethod.delivery ? deliveryAddress : null,
          pickupBranch: state.deliveryMethod == DeliveryMethod.pickup ? state.selectedBranch : null,
          total: total,
        );

    switch (result) {
      case Success(:final data):
        // El pedido ya se creó: los ítems dejan de pertenecer al carrito.
        await ref.read(cartControllerProvider.notifier).clearCart();
        state = state.copyWith(isSubmitting: false, submittedOrder: data);
      case ResultError(:final failure):
        state = state.copyWith(isSubmitting: false, error: failure);
    }
    return result;
  }

  /// Confirma el pago del pedido ya creado (Fase 16). [paymentMethodId]
  /// llega desde Stripe.instance.createPaymentMethod en la UI; es null
  /// en modo mock, donde el pago se simula sin tarjeta real.
  Future<Result<Order>> payOrder({String? paymentMethodId}) async {
    final order = state.submittedOrder;
    if (order == null) {
      throw StateError('No hay un pedido creado para pagar.');
    }

    state = state.copyWith(isPaying: true, clearPaymentError: true);

    final result = await ref.read(payOrderUseCaseProvider).call(
          orderId: order.id,
          paymentMethodId: paymentMethodId,
        );

    switch (result) {
      case Success(:final data):
        state = state.copyWith(isPaying: false, submittedOrder: data);
      case ResultError(:final failure):
        state = state.copyWith(isPaying: false, paymentError: failure);
    }
    return result;
  }
}

final checkoutControllerProvider = NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);
