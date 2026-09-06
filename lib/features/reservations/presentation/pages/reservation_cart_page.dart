import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/core/widgets/app_button.dart';
import 'package:fashion_store/core/widgets/empty_state.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation.dart';
import 'package:fashion_store/features/reservations/domain/entities/reservation_item.dart';
import 'package:fashion_store/features/reservations/presentation/controllers/reservation_checkout_controller.dart';
import 'package:fashion_store/features/reservations/presentation/controllers/reservation_draft_controller.dart';

/// Borrador de reserva: varias prendas, cada una con su talla y color,
/// confirmadas juntas con una sola sucursal y un horario aproximado
/// (ver sección 10 del documento del proyecto). Requiere sesión
/// iniciada (protegido por el router).
class ReservationCartPage extends ConsumerStatefulWidget {
  const ReservationCartPage({super.key});

  @override
  ConsumerState<ReservationCartPage> createState() =>
      _ReservationCartPageState();
}

class _ReservationCartPageState extends ConsumerState<ReservationCartPage> {
  String? _branchError;
  String? _scheduleError;

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;

    final scheduledFor = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => _scheduleError = null);
    ref
        .read(reservationCheckoutControllerProvider.notifier)
        .selectScheduledFor(scheduledFor);
  }

  Future<void> _confirm(List<ReservationItem> items) async {
    final checkoutState = ref.read(reservationCheckoutControllerProvider);
    setState(() {
      _branchError = checkoutState.selectedBranch == null
          ? 'Selecciona una sucursal para la reserva.'
          : null;
      _scheduleError = checkoutState.scheduledFor == null
          ? 'Elige un horario aproximado.'
          : null;
    });
    if (_branchError != null || _scheduleError != null) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(reservationCheckoutControllerProvider.notifier)
        .confirm(items);
    if (result is ResultError<Reservation>) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftState = ref.watch(reservationDraftControllerProvider);
    final checkoutState = ref.watch(reservationCheckoutControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar prendas')),
      body: checkoutState.createdReservation != null
          ? _ReservationConfirmation(
              reservation: checkoutState.createdReservation!,
            )
          : draftState.items.isEmpty
          ? const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Sin prendas para reservar',
              message: 'Agrega prendas a la reserva desde el detalle de un producto.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Prendas a reservar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...draftState.items.map((item) => _DraftItemTile(item: item)),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Sucursal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _BranchSelector(
                  state: checkoutState,
                  errorText: _branchError,
                  onSelected: (branch) {
                    setState(() => _branchError = null);
                    ref
                        .read(reservationCheckoutControllerProvider.notifier)
                        .selectBranch(branch);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Horario aproximado',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _pickSchedule,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    checkoutState.scheduledFor == null
                        ? 'Elegir horario'
                        : _formatDateTime(checkoutState.scheduledFor!),
                  ),
                ),
                if (_scheduleError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      _scheduleError!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Confirmar reserva',
                  isLoading: checkoutState.isSubmitting,
                  onPressed: () => _confirm(draftState.items),
                ),
              ],
            ),
    );
  }
}

class _DraftItemTile extends ConsumerWidget {
  final ReservationItem item;

  const _DraftItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Talla ${item.variant.size.label} · ${item.variant.color.name}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () => ref
                .read(reservationDraftControllerProvider.notifier)
                .updateQuantity(item.variant.id, item.quantity - 1),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () => ref
                .read(reservationDraftControllerProvider.notifier)
                .updateQuantity(item.variant.id, item.quantity + 1),
          ),
          IconButton(
            tooltip: 'Quitar',
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: () => ref
                .read(reservationDraftControllerProvider.notifier)
                .removeItem(item.variant.id),
          ),
        ],
      ),
    );
  }
}

class _BranchSelector extends StatelessWidget {
  final ReservationCheckoutState state;
  final String? errorText;
  final ValueChanged<Branch> onSelected;

  const _BranchSelector({
    required this.state,
    required this.errorText,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingBranches) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return RadioGroup<String>(
      groupValue: state.selectedBranch?.id,
      onChanged: (branchId) {
        final branch = state.branches.firstWhere(
          (branch) => branch.id == branchId,
        );
        onSelected(branch);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...state.branches.map((branch) {
            return RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: Text(branch.name),
              subtitle: Text(branch.city),
              value: branch.id,
            );
          }),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                errorText!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReservationConfirmation extends StatelessWidget {
  final Reservation reservation;

  const _ReservationConfirmation({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 56,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Reserva confirmada',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Reserva #${reservation.id} · ${reservation.items.length} '
            '${reservation.items.length == 1 ? 'prenda' : 'prendas'}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${reservation.branch.name} · ${_formatDateTime(reservation.scheduledFor)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Ver mis reservas',
            onPressed: () => context.push(RoutePaths.reservations),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final date =
      '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  final time =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  return '$date · $time';
}
