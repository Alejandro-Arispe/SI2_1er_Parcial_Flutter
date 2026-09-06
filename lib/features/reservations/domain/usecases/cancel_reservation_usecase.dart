import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:fashion_store/features/reservations/domain/repositories/reservation_repository.dart';

class CancelReservationUseCase {
  final ReservationRepository _repository;

  const CancelReservationUseCase(this._repository);

  Future<Result<void>> call(String reservationId) =>
      _repository.cancelReservation(reservationId);
}

final cancelReservationUseCaseProvider = Provider<CancelReservationUseCase>((
  ref,
) {
  return CancelReservationUseCase(ref.watch(reservationRepositoryProvider));
});
