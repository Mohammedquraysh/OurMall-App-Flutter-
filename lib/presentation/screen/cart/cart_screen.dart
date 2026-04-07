// lib/presentation/screen/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/model/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../../util/extensions.dart';

class CartNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CartNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> updateQty(String id, int qty) async {
    await _ref.read(updateCartQuantityUseCaseProvider)(id, qty);
  }

  Future<void> remove(String id) async {
    await _ref.read(removeFromCartUseCaseProvider)(id);
  }

  Future<String?> applyPromo(String code) async {
    try {
      final pct = await _ref.read(applyPromoUseCaseProvider)(code);
      return '${pct.toInt()}% off applied!';
    } catch (e) { return null; }
  }

  Future<List<CartValidationIssue>?> validateCart() async {
    try { return await _ref.read(validateCartUseCaseProvider)(); }
    catch (_) { return null; }
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<void>>(
        (ref) => CartNotifier(ref));

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoCtrl = TextEditingController();
  String? _promoError;
  bool _isApplyingPromo = false;
  bool _isValidating = false;

  @override
  void dispose() { _promoCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartStreamProvider);

    return Scaffold(
      appBar: OurMallAppBar(title: 'My Cart', onBack: () => context.pop()),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (cart) {
          if (cart.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_checkout,
              title: 'Your Cart is Empty',
              subtitle: 'Add products from the store to get started',
              action: OurMallButton(
                text: 'Browse Products',
                icon: Icons.storefront,
                onPressed: () => context.pop(),
              ),
            );
          }
          return Column(children: [
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _PromoSection(
                  ctrl: _promoCtrl,
                  error: _promoError,
                  isLoading: _isApplyingPromo,
                  appliedCode: cart.promoCode,
                  onApply: _applyPromo,
                ),
                const SizedBox(height: 12),
                ...cart.vendorCarts.map((vc) => _VendorCartCard(
                  vendorCart: vc,
                  onQtyChanged: (id, q) => ref.read(cartNotifierProvider.notifier).updateQty(id, q),
                  onRemove: (id) => ref.read(cartNotifierProvider.notifier).remove(id),
                ).animate().fadeIn().slideY(begin: 0.2)),
                const SizedBox(height: 12),
                _OrderSummaryCard(cart: cart),
              ],
            )),
            _CartBottomBar(cart: cart, isValidating: _isValidating, onCheckout: _proceed),
          ]);
        },
      ),
    );
  }

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _isApplyingPromo = true; _promoError = null; });
    final msg = await ref.read(cartNotifierProvider.notifier).applyPromo(code);
    setState(() => _isApplyingPromo = false);
    if (msg != null) {
      _promoCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      setState(() => _promoError = 'Invalid promo code');
    }
  }

  Future<void> _proceed() async {
    setState(() => _isValidating = true);
    final issues = await ref.read(cartNotifierProvider.notifier).validateCart();
    setState(() => _isValidating = false);
    if (!mounted) return;
    if (issues == null) return;
    if (issues.isEmpty) { context.push('/checkout'); return; }
    final blockers = issues.where((i) => i.issueType == CartIssueType.outOfStock).toList();
    await showDialog(
      context: context,
      builder: (_) => _ValidationDialog(
        issues: issues,
        onProceed: blockers.isEmpty ? () { Navigator.pop(context); context.push('/checkout'); } : null,
        onReview: () => Navigator.pop(context),
      ),
    );
  }
}

class _VendorCartCard extends StatelessWidget {
  final VendorCart vendorCart;
  final void Function(String, int) onQtyChanged;
  final void Function(String) onRemove;
  const _VendorCartCard({required this.vendorCart, required this.onQtyChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.store_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(vendorCart.vendorName, style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const Spacer(),
          Text('${vendorCart.itemCount} item${vendorCart.itemCount > 1 ? "s" : ""}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
        const Divider(height: 16),
        ...vendorCart.items.asMap().entries.map((e) => Column(children: [
          _CartItemRow(item: e.value,
            onQtyChanged: (q) => onQtyChanged(e.value.product.id, q),
            onRemove: () => onRemove(e.value.product.id)),
          if (e.key < vendorCart.items.length - 1) const Divider(height: 12),
        ])),
        const Divider(height: 16),
        Row(children: [
          Text('Vendor Subtotal', style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(vendorCart.subtotal.formatPrice, style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      ]),
    ),
  );
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final void Function(int) onQtyChanged;
  final VoidCallback onRemove;
  const _CartItemRow({required this.item, required this.onQtyChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final p = item.product;
    final offerActive = p.isOfferActive(now);
    final offerExpiredInCart = item.appliedProductDiscount > 0 &&
        p.offerExpiresAt != null && !offerActive;
    final outOfStock = p.stockStatus == StockStatus.outOfStock;

    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_outline, color: Colors.white),
          const SizedBox(width: 8),
          const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      onDismissed: (_) => onRemove(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: ProductImage(p.imageUrl, width: 72, height: 72)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              Text(item.snapshotPrice.formatPrice,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              if (item.appliedProductDiscount > 0 && offerActive) ...[
                const SizedBox(width: 6),
                Text(p.originalPrice.formatPrice,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough)),
              ],
            ]),
            const SizedBox(height: 8),
            QuantitySelector(
              quantity: item.quantity,
              onDecrease: () => onQtyChanged(item.quantity - 1),
              onIncrease: () => onQtyChanged(item.quantity + 1),
              maxQuantity: p.stockQuantity,
            ),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(item.discountedLineTotal.formatPrice,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            if (item.quantity > 1)
              Text('×${item.quantity}', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ]),
        // Warnings
        if (offerExpiredInCart) _WarningBanner(
          icon: Icons.warning_amber_outlined, color: AppColors.amber,
          text: 'Offer expired — price updated to ${p.originalPrice.formatPrice}'),
        if (outOfStock) _WarningBanner(
          icon: Icons.error_outline, color: AppColors.red,
          text: 'This item is out of stock'),
        if (p.stockStatus == StockStatus.lowStock) _WarningBanner(
          icon: Icons.inventory_2_outlined, color: AppColors.amber,
          text: 'Only ${p.stockQuantity} left!'),
        if (offerActive && p.offerExpiresAt != null) ...[
          const SizedBox(height: 6),
          CountdownChip(p.offerExpiresAt!),
        ],
      ]),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _WarningBanner({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: TextStyle(fontSize: 11, color: color))),
    ]),
  ).animate().fadeIn().slideY(begin: -0.2);
}

class _PromoSection extends StatelessWidget {
  final TextEditingController ctrl;
  final String? error, appliedCode;
  final bool isLoading;
  final VoidCallback onApply;
  const _PromoSection({required this.ctrl, this.error, this.appliedCode,
    required this.isLoading, required this.onApply});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.local_offer_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('Promo Code', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        if (appliedCode != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppColors.green, size: 16),
              const SizedBox(width: 8),
              Text('"$appliedCode" applied!',
                style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ).animate().fadeIn().slideY(begin: -0.2),
        ],
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Enter code (e.g. OURMALL10)',
              errorText: error,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          )),
          const SizedBox(width: 8),
          SizedBox(height: 48, child: ElevatedButton(
            onPressed: isLoading ? null : onApply,
            child: isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Apply'),
          )),
        ]),
      ]),
    ),
  );
}

class _OrderSummaryCard extends StatelessWidget {
  final Cart cart;
  const _OrderSummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text('Order Summary', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 16),
        ...cart.vendorCarts.map((vc) => _SummaryRow(
          '${vc.vendorName} (${vc.itemCount} items)', vc.subtotal.formatPrice)),
        if (cart.vendorCarts.any((vc) => vc.totalDiscount > 0))
          _SummaryRow('Product Discounts',
            '-${cart.vendorCarts.fold(0.0, (s, vc) => s + vc.totalDiscount).formatPrice}',
            valueColor: AppColors.green),
        if (cart.cartLevelDiscountPercent > 0)
          _SummaryRow('Promo (${cart.promoCode})',
            '-${cart.cartLevelDiscountAmount.formatPrice}',
            valueColor: AppColors.green),
        const Divider(height: 16),
        Row(children: [
          Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(end: cart.grandTotal),
            duration: 600.ms,
            builder: (_, value, __) => Text(value.formatPrice,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
          ),
        ]),
      ]),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _SummaryRow(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant))),
      Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600, color: valueColor)),
    ]),
  );
}

class _CartBottomBar extends StatelessWidget {
  final Cart cart;
  final bool isValidating;
  final VoidCallback onCheckout;
  const _CartBottomBar({required this.cart, required this.isValidating, required this.onCheckout});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
    ),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Total', style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
        TweenAnimationBuilder<double>(
          tween: Tween(end: cart.grandTotal),
          duration: 600.ms,
          builder: (_, v, __) => Text(v.formatPrice,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
        ),
      ]),
      const SizedBox(width: 16),
      Expanded(child: OurMallButton(
        text: 'Checkout (${cart.totalItems})',
        isLoading: isValidating,
        icon: Icons.arrow_forward,
        onPressed: onCheckout,
      )),
    ]),
  );
}

class _ValidationDialog extends StatelessWidget {
  final List<CartValidationIssue> issues;
  final VoidCallback? onProceed;
  final VoidCallback onReview;
  const _ValidationDialog({required this.issues, this.onProceed, required this.onReview});

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 32),
    title: const Text('Cart Updated', style: TextStyle(fontWeight: FontWeight.bold)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Some items in your cart have changed:'),
      const SizedBox(height: 12),
      ...issues.map((i) {
        final color = i.issueType == CartIssueType.outOfStock ||
            i.issueType == CartIssueType.insufficientStock
            ? AppColors.red : AppColors.amber;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(i.issueType == CartIssueType.outOfStock
                ? Icons.remove_shopping_cart : Icons.price_change,
              size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(child: Text(i.detail, style: TextStyle(fontSize: 12, color: color))),
          ]),
        );
      }),
    ]),
    actions: [
      TextButton(onPressed: onReview, child: const Text('Review Cart')),
      if (onProceed != null)
        ElevatedButton(onPressed: onProceed, child: const Text('Proceed Anyway')),
    ],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
