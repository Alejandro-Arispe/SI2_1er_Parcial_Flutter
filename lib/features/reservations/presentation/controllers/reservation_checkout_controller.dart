import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/error/failures.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/catalog/domain/usecases/get_branches_usecase.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';
import 'package:fashion_store/features/reservations/domain/usecases/create_reservation_usecase.dart';
import 'package:fashion_store/features/reservations/presentation/controllers/reservation_draft_controller.dart';
import 'package:fashion_store/features/reservations/presentation/controllers/reservations_controller.dart';

class ReservationCheckoutState {
  final List<Branch> branches;
  final bool isLoadingBranches;
  final Branch? selectedBranch;
  final DateTime? scheduledFor;
  final bool isSubmitting;
  final Reservation? createdReservation;
  final Failure? error;

  const ReservationCheckoutState({
    required this.branches,
    required this.isLoadingBranches,
    required this.selectedBranch,
    required this.scheduledFor,
    required this.isSubmitting,
    required this.createdReservation,
    required this.error,
  });

  factory ReservationCheckoutState.initial() => const ReservationCheckoutState(
    branches: [],
    isLoadingBranches: true,
    selectedBranch: null,
    scheduledFor: null,
    isSubmitting: false,
    createdReservation: null,
    error: null,
  );

  ReservationCheckoutState copyWith({
    List<Branch>? branches,
    bool? isLoadingBranches,
    Branch? selectedBranch,
    DateTime? scheduledFor,
    bool? isSubmitting,
    Reservation? createdReservation,
    Failure? error,
    bool clearError = false,
  }) {
    return ReservationCheckoutState(
      branches: branches ?? this.branches,
      isLoadingBranches: isLoadingBranches ?? this.isLoadingBranches,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdReservation: createdReservation ?? this.createdReservation,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Confirma la reserva armada en ReservationDraftController: elige una
/// sucursal y un horario aproximado únicos para todas las prendas del
/// borrador (ver sección 10 del documento) y crea la reserva.
class ReservationCheckoutController extends Notifier<ReservationCheckoutState> {
  @override
  ReservationCheckoutState build() {
    _loadBranches(); // no debe tocar state antes del primer await (ver FavoritesController)
    return ReservationCheckoutState.initial();
  }

  Future<void> _loadBranches() async {
    final result = await ref.read(getBranchesUseCaseProvider).call();
    state = switch (result) {
      Success(:final data) => state.copyWith(
        branches: data,
        isLoadingBranches: false,
      ),
      ResultError(:final failure) => state.copyWith(
        isLoadingBranches: false,
        error: failure,
      ),
    };
  }

  void selectBranch(Branch branch) {
    state = state.copyWith(selectedBranch: branch);
  }

  void selectScheduledFor(DateTime scheduledFor) {
    state = state.copyWith(scheduledFor: scheduledFor);
  }

  Future<Result<Reservation>> confirm(List<ReservationItem> items) async {
    final branch = state.selectedBranch;
    final scheduledFor = state.scheduledFor;
    if (branch == null || scheduledFor == null) {
      throw StateError('Falta elegir sucursal u horario antes de confirmar.');
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await ref
        .read(createReservationUseCaseProvider)
        .call(items: items, branch: branch, scheduledFor: scheduledFor);

    switch (result) {
      case Success(:final data):
        ref.read(reservationDraftControllerProvider.notifier).clear();
        await ref.read(reservationsControllerProvider.notifier).refresh();
        state = state.copyWith(isSubmitting: false, createdReservation: data);
      case ResultError(:final failure):
        state = state.copyWith(isSubmitting: false, error: failure);
    }
    return result;
  }
}

final reservationCheckoutControllerProvider =
    NotifierProvider<ReservationCheckoutController, ReservationCheckoutState>(
      ReservationCheckoutController.new,
    );
