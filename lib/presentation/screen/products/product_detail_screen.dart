// lib/presentation/screen/products/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/model/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../../util/extensions.dart';

final _productDetailProvider = FutureProvider.family<Product, String>(
    (ref, id) => ref.read(getProductByIdUseCaseProvider)(id));

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override ConsumerState<ProductDetailScreen> createState() => _State();
}

class _State extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAdding = false;
  bool _added = false;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    ref.listenManual(cartStreamProvider, (_, next) {
      next.whenData((cart) => setState(() => _cartCount = cart.totalItems));
    });
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(_productDetailProvider(widget.productId));

    return Scaffold(
      appBar: OurMallAppBar(
        title: 'Product Detail',
        onBack: () => context.pop(),
        cartCount: _cartCount,
        onCart: () => context.push('/cart'),
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to Load',
          subtitle: e.toString(),
          action: OutlinedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
        ),
        data: (product) {
          final now = DateTime.now();
          final effective = product.effectivePrice(now);
          final offerActive = product.isOfferActive(now);
          final outOfStock = product.stockStatus == StockStatus.outOfStock;
          final savings = product.originalPrice - effective;

          return Stack(children: [
            SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Hero image
                Stack(children: [
                  SizedBox(
                    height: 300, width: double.infinity,
                    child: ProductImage(product.imageUrl, height: 300, fit: BoxFit.cover),
                  ).animate().fadeIn(duration: 400.ms),
                  // Gradient
                  Positioned(bottom: 0, left: 0, right: 0,
                    child: Container(height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: [Theme.of(context).scaffoldBackgroundColor, Colors.transparent],
                        )))),
                  if (offerActive)
                    Positioned(top: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.orange, borderRadius: BorderRadius.circular(8)),
                        child: Text('-${product.discountPercent.toInt()}% OFF',
                          style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 14)),
                      )),
                ]),
                // Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    VendorLabel(product.vendorName),
                    const SizedBox(height: 8),
                    Text(product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold))
                        .animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: PriceRow(
                        effectivePrice: effective, originalPrice: product.originalPrice,
                        discountPercent: product.discountPercent, isOfferActive: offerActive)),
                      StockBadge(product.stockStatus),
                    ]).animate().fadeIn(delay: 200.ms),
                    if (offerActive && product.offerExpiresAt != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Flash Sale', style: TextStyle(
                              fontWeight: FontWeight.bold, color: AppColors.orange)),
                            Text('Offer expires soon!',
                              style: TextStyle(fontSize: 12, color: AppColors.subtext)),
                          ]),
                          const Spacer(),
                          CountdownChip(product.offerExpiresAt!),
                        ]),
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    _DetailRow('Category', product.category),
                    _DetailRow('Vendor', product.vendorName),
                    _DetailRow('Stock', '${product.stockQuantity} units'),
                    if (offerActive && savings > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.green.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.local_offer, color: AppColors.green, size: 20),
                          const SizedBox(width: 8),
                          Text('You save ${savings.formatPrice} with this offer!',
                            style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ]),
                ),
              ]),
            ),
            // Bottom bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                ),
                child: Row(children: [
                  QuantitySelector(
                    quantity: _quantity,
                    onDecrease: () => setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
                    onIncrease: () => setState(() =>
                        _quantity = (_quantity + 1).clamp(1, product.stockQuantity)),
                    maxQuantity: product.stockQuantity,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: OurMallButton(
                    text: outOfStock ? 'Out of Stock'
                        : _added ? 'Added to Cart ✓'
                        : 'Add to Cart',
                    isLoading: _isAdding,
                    icon: !_added && !outOfStock ? Icons.shopping_cart : null,
                    onPressed: outOfStock ? null : _addToCart,
                    color: _added ? AppColors.green : null,
                  )),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _addToCart() async {
    final product = ref.read(_productDetailProvider(widget.productId)).value;
    if (product == null) return;
    setState(() => _isAdding = true);
    try {
      await ref.read(addToCartUseCaseProvider)(product, quantity: _quantity);
      setState(() { _isAdding = false; _added = true; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _added = false);
    } catch (_) { setState(() => _isAdding = false); }
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const Spacer(),
      Text(value, style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w600)),
    ]),
  );
}
