import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/error/error_mapper.dart';
import 'package:fashion_store/core/error/exceptions.dart';
import 'package:fashion_store/core/network/dio_client.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/reservations/data/datasources/reservation_api_data_source.dart';
import 'package:fashion_store/features/reservations/data/datasources/reservation_data_source.dart';
import 'package:fashion_store/features/reservations/data/datasources/reservation_mock_data_source.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';
import 'package:fashion_store/features/reservations/domain/repositories/reservation_repository.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationDataSource _dataSource;

  const ReservationRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Reservation>>> getReservations() async {
    try {
      return Success(await _dataSource.getReservations());
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<Reservation>> createReservation({
    required List<ReservationItem> items,
    required Branch branch,
    required DateTime scheduledFor,
  }) async {
    try {
      final reservation = await _dataSource.createReservation(
        items: items,
        branch: branch,
        scheduledFor: scheduledFor,
      );
      return Success(reservation);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }

  @override
  Future<Result<void>> cancelReservation(String reservationId) async {
    try {
      await _dataSource.cancelReservation(reservationId);
      return const Success(null);
    } on AppException catch (e) {
      return ResultError(ErrorMapper.map(e));
    }
  }
}

final reservationDataSourceProvider = Provider<ReservationDataSource>((ref) {
  return AppConfig.useMockData
      ? ReservationMockDataSource()
      : ReservationApiDataSource(ref.watch(dioClientProvider));
});

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepositoryImpl(ref.watch(reservationDataSourceProvider));
});
