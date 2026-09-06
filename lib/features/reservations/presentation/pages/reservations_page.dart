import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/empty_state.dart';
import 'package:fashion_store/core/widgets/error_state.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/presentation/controllers/reservations_controller.dart';

/// Reservas de varias prendas por sucursal y horario aproximado (Fase
/// 14, ver sección 10 del documento). Requiere sesión iniciada
/// (protegido por el router). Crear una reserva ocurre en
/// ReservationCartPage; esta pantalla solo lista y cancela.
class ReservationsPage extends ConsumerWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservationsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: state.isLoading
          ? const LoadingIndicator()
          : state.error != null && state.reservations.isEmpty
          ? ErrorStateView(
              message: state.error!.message,
              onRetry: () =>
                  ref.read(reservationsControllerProvider.notifier).refresh(),
            )
          : state.reservations.isEmpty
          ? const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Sin reservas todavía',
              message: 'Reserva prendas en una sucursal desde su detalle para probártelas o recogerlas.',
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(reservationsControllerProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.reservations.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) =>
                    _ReservationTile(reservation: state.reservations[index]),
              ),
            ),
    );
  }
}

class _ReservationTile extends ConsumerWidget {
  final Reservation reservation;

  const _ReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = reservation.status == ReservationStatus.active;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reserva #${reservation.id}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusBadge(isActive: isActive),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reservado el ${_formatDate(reservation.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...reservation.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${item.productName} · Talla ${item.variant.size.label} · ${item.variant.color.name} · x${item.quantity}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${reservation.branch.name} · ${reservation.branch.city}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Horario aproximado: ${_formatDateTime(reservation.scheduledFor)}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          if (isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => ref
                    .read(reservationsControllerProvider.notifier)
                    .cancelReservation(reservation.id),
                child: const Text('Cancelar reserva'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.disabled.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        isActive ? 'Activa' : 'Cancelada',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime dateTime) {
  final date = _formatDate(dateTime);
  final time =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  return '$date · $time';
}
