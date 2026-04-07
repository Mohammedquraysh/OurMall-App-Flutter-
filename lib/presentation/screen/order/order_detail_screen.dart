// lib/presentation/screen/order/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/model/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../../util/extensions.dart';
import 'order_list_screen.dart';

//Notifier
class OrderDetailState {
  final Order? order;
  final bool isLoading, isCancelling;
  final String? error, cancelSuccess;

  const OrderDetailState({
    this.order, this.isLoading = true,
    this.isCancelling = false, this.error, this.cancelSuccess,
  });

  OrderDetailState copyWith({
    Order? order, bool? isLoading, bool? isCancelling,
    String? error, String? cancelSuccess,
    bool clearError = false, bool clearSuccess = false,
  }) => OrderDetailState(
    order: order ?? this.order,
    isLoading: isLoading ?? this.isLoading,
    isCancelling: isCancelling ?? this.isCancelling,
    error: clearError ? null : error ?? this.error,
    cancelSuccess: clearSuccess ? null : cancelSuccess ?? this.cancelSuccess,
  );
}

class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  final Ref _ref;
  final String orderId;

  OrderDetailNotifier(this._ref, this.orderId) : super(const OrderDetailState()) {
    _ref.read(getOrderByIdUseCaseProvider)(orderId).listen((order) {
      if (mounted) state = state.copyWith(order: order, isLoading: false);
    });
  }

  Future<void> cancelFullOrder() async {
    state = state.copyWith(isCancelling: true, clearError: true);
    try {
      final updated = await _ref.read(cancelOrderUseCaseProvider)(orderId);
      state = state.copyWith(
        isCancelling: false, order: updated,
        cancelSuccess: 'Order cancelled. Refund: ${updated.totalRefunded.formatPrice}',
      );
    } catch (e) {
      state = state.copyWith(isCancelling: false, error: e.toString());
    }
  }

  Future<void> cancelItem(String itemId) async {
    state = state.copyWith(isCancelling: true, clearError: true);
    try {
      final updated = await _ref.read(cancelOrderItemUseCaseProvider)(orderId, itemId);
      final item = updated.allItems.where((i) => i.id == itemId).firstOrNull;
      state = state.copyWith(
        isCancelling: false, order: updated,
        cancelSuccess: 'Item cancelled. Refund: ${item?.refundAmount.formatPrice ?? "N/A"}',
      );
    } catch (e) {
      state = state.copyWith(isCancelling: false, error: e.toString());
    }
  }

  void clearSuccess() => state = state.copyWith(clearSuccess: true);
  void clearError() => state = state.copyWith(clearError: true);
}

final orderDetailProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetailState, String>(
        (ref, id) => OrderDetailNotifier(ref, id));

//Screen
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderDetailProvider(orderId));

    ref.listen(orderDetailProvider(orderId), (prev, next) {
      if (next.cancelSuccess != null && next.cancelSuccess != prev?.cancelSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.cancelSuccess!)));
        ref.read(orderDetailProvider(orderId).notifier).clearSuccess();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)));
        ref.read(orderDetailProvider(orderId).notifier).clearError();
      }
    });

    final canCancelAny = state.order?.allItems.any((i) => i.canBeCancelled) ?? false;

    return Scaffold(
      appBar: OurMallAppBar(
        title: state.order?.id ?? 'Order Details',
        onBack: () => context.pop(),
        actions: [
          if (canCancelAny)
            TextButton(
              onPressed: state.isCancelling ? null : () => _showCancelDialog(context, ref),
              child: const Text('Cancel Order',
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.order == null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Order Not Found',
                  subtitle: 'This order could not be loaded',
                  action: OutlinedButton(
                      onPressed: () => context.pop(), child: const Text('Go Back')),
                )
              : _OrderDetailBody(
                  order: state.order!,
                  isCancelling: state.isCancelling,
                  onCancelItem: (itemId) => _showCancelItemDialog(context, ref, itemId),
                ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => AlertDialog(
      icon: const Icon(Icons.cancel_outlined, color: AppColors.red, size: 32),
      title: const Text('Cancel Order?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text(
        'All cancellable items will be cancelled and refunded. This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Order')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: () {
            Navigator.pop(context);
            ref.read(orderDetailProvider(orderId).notifier).cancelFullOrder();
          },
          child: const Text('Cancel Order'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  void _showCancelItemDialog(BuildContext context, WidgetRef ref, String itemId) {
    showDialog(context: context, builder: (_) => AlertDialog(
      icon: const Icon(Icons.remove_shopping_cart, color: AppColors.amber, size: 32),
      title: const Text('Cancel Item?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text(
        'This item will be cancelled and refunded. Other items won\'t be affected.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Item')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
          onPressed: () {
            Navigator.pop(context);
            ref.read(orderDetailProvider(orderId).notifier).cancelItem(itemId);
          },
          child: const Text('Cancel Item'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }
}

//Body
class _OrderDetailBody extends StatelessWidget {
  final Order order;
  final bool isCancelling;
  final void Function(String) onCancelItem;
  const _OrderDetailBody({required this.order, required this.isCancelling, required this.onCancelItem});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Order Date', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(fmt.format(order.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ])),
                _OrderStatusBadge(order.status),
              ]),
              if (order.totalRefunded > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.replay, color: AppColors.green, size: 16),
                    const SizedBox(width: 8),
                    Text('Total Refunded: ${order.totalRefunded.formatPrice}',
                      style: const TextStyle(color: AppColors.green,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ],
            ]),
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 12),

        // Status stepper
        _StatusStepper(order: order)
            .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),

        // Vendor sub-orders
        ...order.vendorOrders.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _VendorOrderCard(
            vendorOrder: e.value,
            isCancelling: isCancelling,
            onCancelItem: onCancelItem,
          ).animate().fadeIn(delay: Duration(milliseconds: 150 + e.key * 80))
              .slideY(begin: 0.2),
        )),

        // Financial summary
        _FinancialSummary(order: order)
            .animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        const SizedBox(height: 24),
      ],
    );
  }
}

//Status Stepper
class _StatusStepper extends StatelessWidget {
  final Order order;
  const _StatusStepper({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderItemStatus.pending,
      OrderItemStatus.confirmed,
      OrderItemStatus.shipped,
      OrderItemStatus.delivered,
    ];
    final activeItems = order.activeVendorOrders.expand((v) => v.activeItems).toList();
    int maxStep = 0;
    for (final item in activeItems) {
      final idx = steps.indexOf(item.status);
      if (idx > maxStep) maxStep = idx;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fulfilment Status', style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            for (int i = 0; i < steps.length; i++) ...[
              _StepNode(index: i, isActive: i <= maxStep, isCurrent: i == maxStep),
              if (i < steps.length - 1)
                Expanded(child: _StepLine(filled: i < maxStep)),
            ],
          ]),
          const SizedBox(height: 8),
          Row(children: steps.asMap().entries.map((e) => Expanded(
            child: Text(
              e.value.name[0].toUpperCase() + e.value.name.substring(1),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: e.key <= maxStep ? FontWeight.bold : FontWeight.normal,
                color: e.key <= maxStep
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )).toList()),
        ]),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final int index;
  final bool isActive, isCurrent;
  const _StepNode({required this.index, required this.isActive, required this.isCurrent});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: 400.ms,
    width: isCurrent ? 32 : 28,
    height: isCurrent ? 32 : 28,
    decoration: BoxDecoration(
      color: isActive
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline.withOpacity(0.4),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: isActive && !isCurrent
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text('${index + 1}',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: isActive ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant)),
    ),
  );
}

class _StepLine extends StatelessWidget {
  final bool filled;
  const _StepLine({required this.filled});

  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(height: 3, decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
      borderRadius: BorderRadius.circular(2))),
    AnimatedContainer(
      duration: 600.ms,
      curve: Curves.fastOutSlowIn,
      height: 3,
      width: filled ? double.infinity : 0,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(2)),
    ),
  ]);
}

//Vendor Order Card
class _VendorOrderCard extends StatelessWidget {
  final VendorOrder vendorOrder;
  final bool isCancelling;
  final void Function(String) onCancelItem;
  const _VendorOrderCard({
    required this.vendorOrder, required this.isCancelling, required this.onCancelItem});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.store_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(vendorOrder.vendorName, style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
        ]),
        const Divider(height: 16),
        ...vendorOrder.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OrderItemRow(
            item: item, isCancelling: isCancelling, onCancel: () => onCancelItem(item.id)),
        )),
      ]),
    ),
  );
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;
  final bool isCancelling;
  final VoidCallback onCancel;
  const _OrderItemRow({required this.item, required this.isCancelling, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final cancelled = item.status == OrderItemStatus.cancelled;
    return Opacity(
      opacity: cancelled ? 0.5 : 1.0,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ProductImage(item.imageUrl, width: 64, height: 64)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Qty: ${item.quantity}  •  ${item.lineTotal.formatPrice}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (item.refundAmount > 0)
            Text('Refunded: ${item.refundAmount.formatPrice}',
              style: const TextStyle(fontSize: 12, color: AppColors.green,
                fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(children: [
            OrderItemStatusBadge(item.status),
            const Spacer(),
            if (item.canBeCancelled)
              TextButton(
                onPressed: isCancelling ? null : onCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Cancel',
                  style: TextStyle(color: AppColors.red, fontSize: 12)),
              ),
          ]),
        ])),
      ]),
    );
  }
}

//Financial Summary
class _FinancialSummary extends StatelessWidget {
  final Order order;
  const _FinancialSummary({required this.order});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Financial Summary', style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 16),
        ...order.vendorOrders.map((vo) => _Row(
          vo.vendorName, vo.activeSubtotal.formatPrice, context: context)),
        if ((order.cartLevelDiscountAmount) > 0)
          _Row('Promo (${order.promoCode})',
            '-${order.cartLevelDiscountAmount.formatPrice}',
            color: AppColors.green, context: context),
        const Divider(height: 16),
        Row(children: [
          Text('Order Total', style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(end: order.grandTotal),
            duration: 600.ms,
            builder: (_, v, __) => Text(v.formatPrice,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary)),
          ),
        ]),
        if (order.totalRefunded > 0) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Text('Total Refunded', style: TextStyle(
              color: AppColors.green, fontWeight: FontWeight.w600)),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(end: order.totalRefunded),
              duration: 600.ms,
              builder: (_, v, __) => Text(v.formatPrice,
                style: const TextStyle(color: AppColors.green,
                  fontWeight: FontWeight.w800)),
            ),
          ]).animate().fadeIn().slideY(begin: -0.2),
        ],
      ]),
    ),
  );

  Widget _Row(String label, String value,
      {Color? color, required BuildContext context}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500, color: color)),
        ]),
      );
}

class _OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _OrderStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      OrderStatus.pending            => ('Pending',         AppColors.amber),
      OrderStatus.confirmed          => ('Confirmed',       AppColors.blue),
      OrderStatus.partiallyCancelled => ('Part. Cancelled', AppColors.orange),
      OrderStatus.cancelled          => ('Cancelled',       AppColors.red),
      OrderStatus.completed          => ('Completed',       AppColors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
