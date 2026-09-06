import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/widgets/empty_state.dart';
import 'package:fashion_store/core/widgets/error_state.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';
import 'package:fashion_store/features/orders/presentation/controllers/orders_controller.dart';

/// Historial de compras del cliente (Fase 17). Solo lectura: crear y
/// pagar un pedido ocurre en checkout (Fases 15/16). Requiere sesión
/// iniciada (protegido por el router).
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis compras')),
      body: state.isLoading
          ? const LoadingIndicator()
          : state.error != null && state.orders.isEmpty
              ? ErrorStateView(
                  message: state.error!.message,
                  onRetry: () => ref.read(ordersControllerProvider.notifier).refresh(),
                )
              : state.orders.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin compras todavía',
                      message: 'Cuando completes una compra en checkout, aparecerá aquí.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(ordersControllerProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: state.orders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) => _OrderTile(order: state.orders[index]),
                      ),
                    ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
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
                child: Text('Pedido #${order.id}', style: Theme.of(context).textTheme.titleMedium),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Realizado el ${_formatDate(order.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...order.items.map(
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
            order.deliveryMethod == DeliveryMethod.delivery
                ? 'Envío a: ${order.deliveryAddress}'
                : 'Recojo en: ${order.pickupBranch?.name}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'Bs ${order.total.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      OrderStatus.pendingPayment => ('Pendiente de pago', AppColors.warning),
      OrderStatus.paid => ('Pagado', AppColors.success),
      OrderStatus.cancelled => ('Cancelado', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
