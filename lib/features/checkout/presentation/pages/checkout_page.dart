import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import 'package:fashion_store/app/router/route_paths.dart';
import 'package:fashion_store/core/config/app_config.dart';
import 'package:fashion_store/core/theme/app_colors.dart';
import 'package:fashion_store/core/theme/app_spacing.dart';
import 'package:fashion_store/core/utils/result.dart';
import 'package:fashion_store/core/utils/validators.dart';
import 'package:fashion_store/core/widgets/app_button.dart';
import 'package:fashion_store/core/widgets/app_text_field.dart';
import 'package:fashion_store/core/widgets/empty_state.dart';
import 'package:fashion_store/core/widgets/loading_indicator.dart';
import 'package:fashion_store/features/catalog/domain/entities/branch.dart';
import 'package:fashion_store/features/cart/domain/entities/cart_item.dart';
import 'package:fashion_store/features/cart/presentation/controllers/cart_controller.dart';
import 'package:fashion_store/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:fashion_store/features/orders/domain/entities/order.dart';

/// Flujo de compra: resumen del carrito, método de entrega y creación
/// del pedido (Fase 15), seguido del pago con Stripe (Fase 16).
/// Requiere sesión iniciada (protegido por el router).
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String? _branchError;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<CartItem> items, double total) async {
    final checkoutState = ref.read(checkoutControllerProvider);
    final isFormValid = _formKey.currentState!.validate();

    setState(() {
      _branchError = checkoutState.deliveryMethod == DeliveryMethod.pickup && checkoutState.selectedBranch == null
          ? 'Selecciona una sucursal para recoger tu pedido.'
          : null;
    });
    if (!isFormValid || _branchError != null) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(checkoutControllerProvider.notifier).submitOrder(
          items: items,
          total: total,
          deliveryAddress: _addressController.text.trim(),
        );
    if (result is ResultError<Order>) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: checkoutState.submittedOrder != null
          ? _OrderConfirmation(order: checkoutState.submittedOrder!)
          : cartState.isLoading
              ? const LoadingIndicator()
              : cartState.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Tu carrito está vacío',
                      message: 'Agrega prendas al carrito antes de continuar con la compra.',
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          Text('Resumen del pedido', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          ...cartState.items.map((item) => _SummaryTile(item: item)),
                          const Divider(height: AppSpacing.xl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: Theme.of(context).textTheme.titleMedium),
                              Text(
                                'Bs ${cartState.subtotal.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text('Método de entrega', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              ChoiceChip(
                                label: const Text('Envío a domicilio'),
                                selected: checkoutState.deliveryMethod == DeliveryMethod.delivery,
                                onSelected: (_) => ref
                                    .read(checkoutControllerProvider.notifier)
                                    .selectDeliveryMethod(DeliveryMethod.delivery),
                              ),
                              ChoiceChip(
                                label: const Text('Recojo en sucursal'),
                                selected: checkoutState.deliveryMethod == DeliveryMethod.pickup,
                                onSelected: (_) => ref
                                    .read(checkoutControllerProvider.notifier)
                                    .selectDeliveryMethod(DeliveryMethod.pickup),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (checkoutState.deliveryMethod == DeliveryMethod.delivery)
                            AppTextField(
                              label: 'Dirección de entrega',
                              controller: _addressController,
                              validator: (value) => Validators.requiredField(
                                value,
                                message: 'Ingresa una dirección de entrega.',
                              ),
                            )
                          else
                            _BranchSelector(
                              state: checkoutState,
                              errorText: _branchError,
                              onSelected: (branch) {
                                setState(() => _branchError = null);
                                ref.read(checkoutControllerProvider.notifier).selectBranch(branch);
                              },
                            ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: 'Confirmar pedido',
                            isLoading: checkoutState.isSubmitting,
                            onPressed: () => _submit(cartState.items, cartState.subtotal),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final CartItem item;

  const _SummaryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  'Talla ${item.variant.size.label} · ${item.variant.color.name} · x${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text('Bs ${item.subtotal.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BranchSelector extends StatelessWidget {
  final CheckoutState state;
  final String? errorText;
  final ValueChanged<Branch> onSelected;

  const _BranchSelector({required this.state, required this.errorText, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingBranches) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return RadioGroup<String>(
      groupValue: state.selectedBranch?.id,
      onChanged: (branchId) {
        final branch = state.branches.firstWhere((branch) => branch.id == branchId);
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// Confirmación tras crear el pedido. Mientras esté "pendiente de pago"
/// muestra el paso de pago (Fase 16); una vez pagado, solo el resumen
/// final y la salida.
class _OrderConfirmation extends StatelessWidget {
  final Order order;

  const _OrderConfirmation({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPaid = order.status == OrderStatus.paid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.hourglass_top_outlined,
            size: 56,
            color: isPaid ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isPaid ? 'Pago exitoso' : 'Pedido creado',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pedido #${order.id}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            order.deliveryMethod == DeliveryMethod.delivery
                ? 'Envío a: ${order.deliveryAddress}'
                : 'Recojo en: ${order.pickupBranch?.name}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total: Bs ${order.total.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isPaid)
            AppButton(label: 'Volver al inicio', onPressed: () => context.go(RoutePaths.home))
          else
            _PaymentSection(order: order),
        ],
      ),
    );
  }
}

/// Paso de pago (Fase 16). En modo mock no se toca el SDK de Stripe en
/// absoluto (no hay tarjeta real ni backend que la cobre, ver sección
/// 13): se simula el pago con un botón directo. Con datos reales, se
/// recolecta la tarjeta con CardField (nunca en un TextField propio,
/// para no manejar el número de tarjeta fuera de Stripe) y se tokeniza
/// en el cliente; el backend es quien crea y confirma el cobro.
class _PaymentSection extends ConsumerStatefulWidget {
  final Order order;

  const _PaymentSection({required this.order});

  @override
  ConsumerState<_PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends ConsumerState<_PaymentSection> {
  bool _cardComplete = false;

  Future<void> _pay() async {
    final messenger = ScaffoldMessenger.of(context);
    String? paymentMethodId;

    if (!AppConfig.useMockData) {
      try {
        final paymentMethod = await Stripe.instance.createPaymentMethod(
          params: const PaymentMethodParams.card(paymentMethodData: PaymentMethodData()),
        );
        paymentMethodId = paymentMethod.id;
      } on StripeException catch (e) {
        messenger
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.error.localizedMessage ?? 'No se pudo procesar la tarjeta.')));
        return;
      }
    }

    final result = await ref.read(checkoutControllerProvider.notifier).payOrder(paymentMethodId: paymentMethodId);
    if (result is ResultError<Order>) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutControllerProvider);
    final canPay = AppConfig.useMockData || _cardComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (AppConfig.useMockData)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.skeleton,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Modo de prueba: el pago se simula sin conectarse a Stripe.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text('Datos de la tarjeta', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          CardField(
            onCardChanged: (details) => setState(() => _cardComplete = details?.complete ?? false),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Pagar Bs ${widget.order.total.toStringAsFixed(0)}',
          isLoading: checkoutState.isPaying,
          onPressed: canPay ? _pay : null,
        ),
      ],
    );
  }
}
