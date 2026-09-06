import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/domain/usecases/cancel_reservation_usecase.dart';
import 'package:fashion_store/features/reservations/domain/usecases/get_reservations_usecase.dart';

class ReservationsState {
  final List<Reservation> reservations;
  final bool isLoading;
  final Failure? error;

  const ReservationsState({
    required this.reservations,
    required this.isLoading,
    required this.error,
  });

  factory ReservationsState.initial() =>
      const ReservationsState(reservations: [], isLoading: true, error: null);
}

/// Controller del historial de reservas (Fase 14): consultarlas y
/// cancelarlas. Crear una reserva es un flujo aparte (varias prendas,
/// sucursal y horario únicos, ver sección 10) que vive en
/// ReservationCheckoutController, sobre el borrador de
/// ReservationDraftController.
class ReservationsController extends Notifier<ReservationsState> {
  @override
  ReservationsState build() {
    _load(); // no debe tocar state antes del primer await (ver FavoritesController)
    return ReservationsState.initial();
  }

  Future<void> _load() async {
    final result = await ref.read(getReservationsUseCaseProvider).call();
    state = switch (result) {
      Success(:final data) => ReservationsState(
        reservations: data,
        isLoading: false,
        error: null,
      ),
      ResultError(:final failure) => ReservationsState(
        reservations: state.reservations,
        isLoading: false,
        error: failure,
      ),
    };
  }

  Future<void> refresh() => _load();

  Future<void> cancelReservation(String reservationId) async {
    final previous = state.reservations;
    state = ReservationsState(
      reservations: [
        for (final reservation in previous)
          if (reservation.id == reservationId)
            Reservation(
              id: reservation.id,
              items: reservation.items,
              branch: reservation.branch,
              scheduledFor: reservation.scheduledFor,
              status: ReservationStatus.cancelled,
              createdAt: reservation.createdAt,
            )
          else
            reservation,
      ],
      isLoading: false,
      error: null,
    );

    final result = await ref
        .read(cancelReservationUseCaseProvider)
        .call(reservationId);
    if (result case ResultError()) {
      state = ReservationsState(
        reservations: previous,
        isLoading: false,
        error: null,
      );
    }
  }
}

final reservationsControllerProvider =
    NotifierProvider<ReservationsController, ReservationsState>(
      ReservationsController.new,
    );
