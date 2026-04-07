// lib/presentation/screen/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/model/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../../util/extensions.dart';

enum CheckoutStep { review, placing, success }

class CheckoutState {
  final Cart cart;
  final CheckoutStep step;
  final String? error;
  final String? orderId;

  const CheckoutState({
    this.cart = const Cart(),
    this.step = CheckoutStep.review,
    this.error,
    this.orderId,
  });

  CheckoutState copyWith({
    Cart? cart, CheckoutStep? step,
    String? error, String? orderId, bool clearError = false,
  }) => CheckoutState(
    cart: cart ?? this.cart,
    step: step ?? this.step,
    error: clearError ? null : error ?? this.error,
    orderId: orderId ?? this.orderId,
  );
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;
  CheckoutNotifier(this._ref) : super(const CheckoutState()) {
    _ref.listen(cartStreamProvider, (_, next) {
      next.whenData((cart) => state = state.copyWith(cart: cart));
    });
  }

  Future<void> placeOrder() async {
    // Step 1 — validate
    state = state.copyWith(step: CheckoutStep.placing, clearError: true);
    try {
      final issues = await _ref.read(validateCartUseCaseProvider)();
      final blockers = issues.where(
        (i) => i.issueType == CartIssueType.outOfStock).toList();
      if (blockers.isNotEmpty) {
        state = state.copyWith(
          step: CheckoutStep.review,
          error: blockers.map((i) => i.detail).join('\n'),
        );
        return;
      }

      // Step 2 — create order
      final cart = state.cart;
      final order = await _ref.read(createOrderUseCaseProvider)(cart);
      await _ref.read(clearCartUseCaseProvider)();
      state = state.copyWith(step: CheckoutStep.success, orderId: order.id);
    } catch (e) {
      state = state.copyWith(step: CheckoutStep.review, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final checkoutProvider =
    StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(
        (ref) => CheckoutNotifier(ref));

// ── Screen ─────────────────────────────────────────────────────────────────

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutProvider);

    // Navigate to order detail after success
    ref.listen(checkoutProvider, (prev, next) async {
      if (next.step == CheckoutStep.success && next.orderId != null) {
        await Future.delayed(const Duration(milliseconds: 2200));
        if (mounted) {
          context.go('/orders/${next.orderId}');
        }
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)));
        ref.read(checkoutProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: state.step != CheckoutStep.success
          ? OurMallAppBar(title: 'Checkout', onBack: () => context.pop())
          : null,
      body: AnimatedSwitcher(
        duration: 400.ms,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(anim),
            child: child),
        ),
        child: switch (state.step) {
          CheckoutStep.review  => _ReviewContent(state: state),
          CheckoutStep.placing => const _PlacingContent(),
          CheckoutStep.success => _SuccessContent(orderId: state.orderId ?? ''),
        },
      ),
      bottomNavigationBar: state.step == CheckoutStep.review
          ? _CheckoutBottomBar(
              cart: state.cart,
              onPlace: () => ref.read(checkoutProvider.notifier).placeOrder(),
            )
          : null,
    );
  }
}

//Review

class _ReviewContent extends StatelessWidget {
  final CheckoutState state;
  const _ReviewContent({required this.state});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Review Order', style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ...state.cart.vendorCarts.map((vc) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.store_outlined, size: 18,
                color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(vc.vendorName, style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            ]),
            const Divider(height: 16),
            ...vc.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProductImage(item.product.imageUrl, width: 52, height: 52),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.product.name, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                  Text('Qty: ${item.quantity}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                Text(item.discountedLineTotal.formatPrice,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            )),
            const Divider(height: 8),
            Row(children: [
              Text('Subtotal', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text(vc.subtotal.formatPrice,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
      ).animate().fadeIn().slideY(begin: 0.2)),
      // Totals
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (state.cart.cartLevelDiscountPercent > 0)
              _Row('Promo Discount',
                '-${state.cart.cartLevelDiscountAmount.formatPrice}',
                valueColor: AppColors.green),
            _Row('Grand Total', state.cart.grandTotal.formatPrice,
              bold: true,
              valueColor: Theme.of(context).colorScheme.primary),
          ]),
        ),
      ),
      const SizedBox(height: 80),
    ],
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.bold = false, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
      const Spacer(),
      Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: valueColor)),
    ]),
  );
}

//Placing
class _PlacingContent extends StatefulWidget {
  const _PlacingContent();
  @override State<_PlacingContent> createState() => _PlacingState();
}

class _PlacingState extends State<_PlacingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1200.ms)..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      RotationTransition(
        turns: _ctrl,
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shopping_bag_outlined, size: 48,
            color: Theme.of(context).colorScheme.primary),
        ),
      ),
      const SizedBox(height: 24),
      Text('Placing your order…',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Please wait a moment',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
      SizedBox(width: 200, child: LinearProgressIndicator(
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.primary,
      )),
    ]),
  );
}

//Success
class _SuccessContent extends StatelessWidget {
  final String orderId;
  const _SuccessContent({required this.orderId});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline,
            size: 72, color: AppColors.green),
        )
            .animate()
            .scale(
              begin: const Offset(0, 0),
              curve: Curves.elasticOut,
              duration: 800.ms)
            .fadeIn(),
        const SizedBox(height: 24),
        Text('Order Placed!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800, color: AppColors.green))
            .animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
        const SizedBox(height: 8),
        Text(orderId,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant))
            .animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        Text('Taking you to your order details…',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant))
            .animate().fadeIn(delay: 500.ms),
      ]),
    ),
  );
}

//Bottom Bar
class _CheckoutBottomBar extends StatelessWidget {
  final Cart cart;
  final VoidCallback onPlace;
  const _CheckoutBottomBar({required this.cart, required this.onPlace});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
    ),
    child: OurMallButton(
      text: 'Place Order  •  ${cart.grandTotal.formatPrice}',
      icon: Icons.lock_outline,
      onPressed: cart.isEmpty ? null : onPlace,
    ),
  );
}
