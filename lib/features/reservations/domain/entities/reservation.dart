import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';

/// Estado de una reserva. No incluye estados que dependan de que el
/// personal de la sucursal confirme o entregue la prenda (por ejemplo
/// "lista para recoger") porque ese flujo todavía no está definido por
/// el backend (ver sección 27: no asumir procesos que no se confirmaron).
enum ReservationStatus { active, cancelled }

/// Reserva de varias prendas en una sola sucursal, para un horario
/// aproximado (ver sección 10 del documento del proyecto):
///
/// selecciona varias prendas -> talla y color -> sucursal ->
/// horario aproximado -> confirma reserva
///
/// No reserva stock en el catálogo: eso es responsabilidad del backend,
/// la app solo registra la intención. La reserva NO es una venta: el
/// cliente puede reservar varias prendas y comprar solo algunas al
/// llegar a la sucursal.
class Reservation {
  final String id;
  final List<ReservationItem> items;
  final Branch branch;
  final DateTime scheduledFor;
  final ReservationStatus status;
  final DateTime createdAt;

  const Reservation({
    required this.id,
    required this.items,
    required this.branch,
    required this.scheduledFor,
    required this.status,
    required this.createdAt,
  });
}
