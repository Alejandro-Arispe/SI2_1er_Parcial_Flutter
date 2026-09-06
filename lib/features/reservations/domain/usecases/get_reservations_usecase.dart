import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/domain/repositories/reservation_repository.dart';

class GetReservationsUseCase {
  final ReservationRepository _repository;

  const GetReservationsUseCase(this._repository);

  Future<Result<List<Reservation>>> call() => _repository.getReservations();
}

final getReservationsUseCaseProvider = Provider<GetReservationsUseCase>((ref) {
  return GetReservationsUseCase(ref.watch(reservationRepositoryProvider));
});
