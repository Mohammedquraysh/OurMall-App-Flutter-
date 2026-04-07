// lib/presentation/screen/order/order_list_screen.dart
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

final ordersStreamProvider = StreamProvider<List<Order>>(
    (ref) => ref.read(getOrdersUseCaseProvider)());

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return Scaffold(
      appBar: OurMallAppBar(title: 'My Orders', onBack: () => context.pop()),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Orders Yet',
              subtitle: 'Your orders will appear here once you place them',
              action: OurMallButton(
                text: 'Shop Now',
                icon: Icons.storefront,
                onPressed: () => context.pop(),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => OrderCard(
              order: orders[i],
              onTap: () => context.push('/orders/${orders[i].id}'),
            ).animate()
                .fadeIn(delay: Duration(milliseconds: i * 60))
                .slideY(begin: 0.2, duration: 300.ms),
          );
        },
      ),
    );
  }
}

// ── Order Card ─────────────────────────────────────────────────────────────

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final preview = order.allItems.take(2).toList();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.id, style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
                Text(fmt.format(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])),
              _OrderStatusChip(order.status),
            ]),
            const Divider(height: 16),
            ...preview.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ProductImage(item.imageUrl, width: 40, height: 40)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                  Text('Qty: ${item.quantity}  •  ${item.lineTotal.formatPrice}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                OrderItemStatusBadge(item.status),
              ]),
            )),
            if (order.allItems.length > 2)
              Text('+${order.allItems.length - 2} more items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const Divider(height: 16),
            Row(children: [
              Icon(Icons.store_outlined, size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('${order.vendorOrders.length} vendor${order.vendorOrders.length > 1 ? "s" : ""}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text(order.grandTotal.formatPrice,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  const _OrderStatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      OrderStatus.pending             => ('Pending',           AppColors.amber),
      OrderStatus.confirmed           => ('Confirmed',         AppColors.blue),
      OrderStatus.partiallyCancelled  => ('Part. Cancelled',   AppColors.orange),
      OrderStatus.cancelled           => ('Cancelled',         AppColors.red),
      OrderStatus.completed           => ('Completed',         AppColors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
