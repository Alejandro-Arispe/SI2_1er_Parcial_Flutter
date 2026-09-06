import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';
import 'package:fashion_store/features/reservations/domain/repositories/reservation_repository.dart';

class CreateReservationUseCase {
  final ReservationRepository _repository;

  const CreateReservationUseCase(this._repository);

  Future<Result<Reservation>> call({
    required List<ReservationItem> items,
    required Branch branch,
    required DateTime scheduledFor,
  }) {
    return _repository.createReservation(
      items: items,
      branch: branch,
      scheduledFor: scheduledFor,
    );
  }
}

final createReservationUseCaseProvider = Provider<CreateReservationUseCase>((
  ref,
) {
  return CreateReservationUseCase(ref.watch(reservationRepositoryProvider));
});
