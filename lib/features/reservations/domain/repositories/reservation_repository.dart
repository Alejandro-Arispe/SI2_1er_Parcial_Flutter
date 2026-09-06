import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';

/// Contrato de reservas por sucursal (ver sección 10 del documento del
/// proyecto y Fase 11, de donde viene la disponibilidad por sucursal
/// que hace posible elegir dónde reservar).
abstract class ReservationRepository {
  Future<Result<List<Reservation>>> getReservations();

  /// Crea una reserva de varias prendas en una sola sucursal, para un
  /// horario aproximado (sección 10: no es una venta, es una intención
  /// de probarse/retirar las prendas en persona).
  Future<Result<Reservation>> createReservation({
    required List<ReservationItem> items,
    required Branch branch,
    required DateTime scheduledFor,
  });

  Future<Result<void>> cancelReservation(String reservationId);
}
