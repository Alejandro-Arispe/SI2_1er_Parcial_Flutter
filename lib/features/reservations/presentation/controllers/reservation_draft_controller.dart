import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/features/catalog/domain/entities/product_variant.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';

class ReservationDraftState {
  final List<ReservationItem> items;

  const ReservationDraftState({required this.items});

  factory ReservationDraftState.initial() =>
      const ReservationDraftState(items: []);

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Borrador de reserva (Fase 14, ver sección 10 del documento): a
/// diferencia del carrito, una reserva no se va guardando ítem por ítem
/// contra el backend a medida que se agrega. El cliente arma primero la
/// lista de prendas (varias prendas, cada una con su talla y color) y
/// recién al confirmar, en ReservationCheckoutController, se envía todo
/// junto con la sucursal y el horario aproximado elegidos. Por eso este
/// borrador es puramente local: no hay nada que sincronizar hasta
/// confirmar.
class ReservationDraftController extends Notifier<ReservationDraftState> {
  @override
  ReservationDraftState build() => ReservationDraftState.initial();

  void addItem({
    required ProductVariant variant,
    required String productId,
    required String productName,
    required String imageUrl,
    int quantity = 1,
  }) {
    final index = state.items.indexWhere(
      (item) => item.variant.id == variant.id,
    );
    if (index != -1) {
      state = ReservationDraftState(
        items: [
          for (var i = 0; i < state.items.length; i++)
            i == index
                ? state.items[i].copyWith(
                    quantity: state.items[i].quantity + quantity,
                  )
                : state.items[i],
        ],
      );
      return;
    }

    state = ReservationDraftState(
      items: [
        ...state.items,
        ReservationItem(
          productId: productId,
          productName: productName,
          imageUrl: imageUrl,
          variant: variant,
          quantity: quantity,
        ),
      ],
    );
  }

  void updateQuantity(String variantId, int quantity) {
    if (quantity < 1) {
      removeItem(variantId);
      return;
    }
    state = ReservationDraftState(
      items: [
        for (final item in state.items)
          if (item.variant.id == variantId)
            item.copyWith(quantity: quantity)
          else
            item,
      ],
    );
  }

  void removeItem(String variantId) {
    state = ReservationDraftState(
      items: state.items.where((item) => item.variant.id != variantId).toList(),
    );
  }

  void clear() {
    state = ReservationDraftState.initial();
  }
}

final reservationDraftControllerProvider =
    NotifierProvider<ReservationDraftController, ReservationDraftState>(
      ReservationDraftController.new,
    );
