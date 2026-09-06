import 'package:dio/dio.dart';
import 'package:fashion_store/core/network/api_endpoints.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/reservations/data/datasources/reservation_data_source.dart';
import 'package:fashion_store/features/reservations/data/models/reservation_model.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';

/// Implementación real: consulta los endpoints de reservas de FastAPI.
/// El servidor resuelve nombre/imagen a partir de variant_id, así que
/// solo se envían los identificadores necesarios.
class ReservationApiDataSource implements ReservationDataSource {
  final Dio _dio;

  const ReservationApiDataSource(this._dio);

  @override
  Future<List<ReservationModel>> getReservations() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.reservations);
    return response.data!
        .map((json) => ReservationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReservationModel> createReservation({
    required List<ReservationItem> items,
    required Branch branch,
    required DateTime scheduledFor,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.reservations,
      data: {
        'items': items
            .map(
              (item) => {
                'variant_id': item.variant.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'branch_id': branch.id,
        'scheduled_for': scheduledFor.toIso8601String(),
      },
    );
    return ReservationModel.fromJson(response.data!);
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    await _dio.patch<void>(
      ApiEndpoints.reservation(reservationId),
      data: {'status': 'cancelled'},
    );
  }
}
