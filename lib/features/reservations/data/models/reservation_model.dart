import 'package:fashion_store/features/catalog/data/models/branch_model.dart';
import 'package:fashion_store/features/reservations/data/models/reservation_item_model.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';

class ReservationModel extends Reservation {
  const ReservationModel({
    required super.id,
    required super.items,
    required super.branch,
    required super.scheduledFor,
    required super.status,
    required super.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map(
            (json) =>
                ReservationItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList(),
      branch: BranchModel.fromJson(json['branch'] as Map<String, dynamic>),
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      status: ReservationStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
