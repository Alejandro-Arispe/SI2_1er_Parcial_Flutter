import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/features/reservations/presentation/controllers/reservation_draft_controller.dart';

/// Ícono de reserva con contador de prendas, reutilizable en las
/// pantallas donde se puede agregar productos al borrador de reserva
/// (Home, Catálogo, detalle de producto), igual que CartIconButton.
class ReservationIconButton extends ConsumerWidget {
  const ReservationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalItems = ref.watch(
      reservationDraftControllerProvider.select((state) => state.totalItems),
    );

    return IconButton(
      tooltip: 'Reservar prendas',
      onPressed: () => context.push(RoutePaths.reservationDraft),
      icon: Badge(
        label: Text('$totalItems'),
        isLabelVisible: totalItems > 0,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.event_available_outlined),
      ),
    );
  }
}
