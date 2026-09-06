import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/reservations/data/datasources/reservation_data_source.dart';
import 'package:fashion_store/features/reservations/data/models/reservation_model.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';

/// Datasource temporal de desarrollo: guarda las reservas en memoria
/// (ver sección 42 del documento del proyecto), igual que
/// CartMockDataSource y FavoriteMockDataSource.
class ReservationMockDataSource implements ReservationDataSource {
  static final List<ReservationModel> _reservations = [];
  static int _nextId = 1;

  @override
  Future<List<ReservationModel>> getReservations() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Las más recientes primero, para que la clienta vea de inmediato
    // la reserva que acaba de hacer.
    return _reservations.reversed.toList();
  }

  @override
  Future<ReservationModel> createReservation({
    required List<ReservationItem> items,
    required Branch branch,
    required DateTime scheduledFor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final reservation = ReservationModel(
      id: 'reservation-${_nextId++}',
      items: items,
      branch: branch,
      scheduledFor: scheduledFor,
      status: ReservationStatus.active,
      createdAt: DateTime.now(),
    );
    _reservations.add(reservation);
    return reservation;
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _reservations.indexWhere((r) => r.id == reservationId);
    if (index == -1) return;
    _reservations[index] = ReservationModel(
      id: _reservations[index].id,
      items: _reservations[index].items,
      branch: _reservations[index].branch,
      scheduledFor: _reservations[index].scheduledFor,
      status: ReservationStatus.cancelled,
      createdAt: _reservations[index].createdAt,
    );
  }
}
