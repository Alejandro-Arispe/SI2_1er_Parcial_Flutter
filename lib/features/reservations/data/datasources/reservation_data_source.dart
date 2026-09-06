import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/reservations/data/models/reservation_model.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';

/// Contrato común para las fuentes de datos de reservas. Dos
/// implementaciones intercambiables: ReservationApiDataSource (real,
/// contra FastAPI) y ReservationMockDataSource (temporal, datos de
/// desarrollo).
abstract class ReservationDataSource {
  Future<List<ReservationModel>> getReservations();

  Future<ReservationModel> createReservation({
    required List<ReservationItem> items,
    required Branch branch,
    required DateTime scheduledFor,
  });

  Future<void> cancelReservation(String reservationId);
}
