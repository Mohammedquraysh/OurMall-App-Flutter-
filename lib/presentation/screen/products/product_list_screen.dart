// lib/presentation/screen/products/product_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/model/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../../util/extensions.dart';
import 'dart:math';

//State

class ProductListState {
  final List<Product> products;
  final bool isLoading, isLoadingMore, hasNextPage;
  final String? error;
  final ProductFilter filter;
  final int currentPage, cartItemCount;
  final String? addedToCart;

  const ProductListState({
    this.products = const [], this.isLoading = false,
    this.isLoadingMore = false, this.hasNextPage = false,
    this.error, this.filter = const ProductFilter(),
    this.currentPage = 0, this.cartItemCount = 0, this.addedToCart,
  });

  ProductListState copyWith({
    List<Product>? products, bool? isLoading, bool? isLoadingMore,
    bool? hasNextPage, String? error, ProductFilter? filter,
    int? currentPage, int? cartItemCount, String? addedToCart,
    bool clearError = false, bool clearAdded = false,
  }) => ProductListState(
    products: products ?? this.products,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasNextPage: hasNextPage ?? this.hasNextPage,
    error: clearError ? null : error ?? this.error,
    filter: filter ?? this.filter,
    currentPage: currentPage ?? this.currentPage,
    cartItemCount: cartItemCount ?? this.cartItemCount,
    addedToCart: clearAdded ? null : addedToCart ?? this.addedToCart,
  );
}

//Notifier
class ProductListNotifier extends StateNotifier<ProductListState> {
  final Ref _ref;
  Timer? _searchDebounce;
  static const _pageSize = 10;

  ProductListNotifier(this._ref) : super(const ProductListState()) {
    _ref.listen(cartStreamProvider, (_, next) {
      next.whenData((cart) => state = state.copyWith(cartItemCount: cart.totalItems));
    });
    loadProducts(reset: true);
  }

  Future<void> loadProducts({bool reset = false}) async {
    if (!reset && !state.hasNextPage) return;
    if (state.isLoadingMore && !reset) return;
    final page = reset ? 0 : state.currentPage + 1;
    state = state.copyWith(
      isLoading: reset, isLoadingMore: !reset, clearError: true, currentPage: page);
    try {
      final products = await _ref.read(getProductsUseCaseProvider)(
        state.filter, page: page, pageSize: _pageSize).first;
      state = state.copyWith(
        products: reset ? products : [...state.products, ...products],
        isLoading: false, isLoadingMore: false,
        currentPage: page, hasNextPage: products.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e.toString());
    }
  }

  void onSearchChanged(String q) {
    state = state.copyWith(filter: state.filter.copyWith(searchQuery: q));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => loadProducts(reset: true));
  }

  void onCategorySelected(String? cat) {
    state = state.copyWith(filter: state.filter.copyWith(category: cat));
    loadProducts(reset: true);
  }

  void onStockFilterChanged(StockStatus? s) {
    state = state.copyWith(filter: state.filter.copyWith(stockStatus: s));
    loadProducts(reset: true);
  }

  Future<void> addToCart(Product product) async {
    try {
      await _ref.read(addToCartUseCaseProvider)(product);
      state = state.copyWith(addedToCart: product.name);
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(clearAdded: true);
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() { _searchDebounce?.cancel(); super.dispose(); }
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>(
        (ref) => ProductListNotifier(ref));

//Screen
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});
  @override ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final cats = ref.watch(categoriesProvider).value ?? [];

    // Snackbars
    ref.listen(productListProvider, (prev, next) {
      if (next.addedToCart != null && next.addedToCart != prev?.addedToCart) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${next.addedToCart} added to cart ✓')));
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          action: SnackBarAction(label: 'Retry', onPressed: () =>
              ref.read(productListProvider.notifier).loadProducts(reset: true)),
        ));
      }
    });

    return Scaffold(
      appBar: OurMallAppBar(
        title: 'OurMall',
        cartCount: state.cartItemCount,
        onCart: () => context.push('/cart'),
        onOrders: () => context.push('/orders'),
      ),
      body: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: ref.read(productListProvider.notifier).onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search products…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.filter.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(productListProvider.notifier).onSearchChanged('');
                      })
                  : null,
            ),
          ),
        ),
        // Filter chips
        SizedBox(height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: 'All',
                selected: state.filter.category == null && state.filter.stockStatus == null,
                onSelected: (_) {
                  ref.read(productListProvider.notifier).onCategorySelected(null);
                  ref.read(productListProvider.notifier).onStockFilterChanged(null);
                },
              ),
              ...cats.map((c) => _FilterChip(
                label: c,
                selected: state.filter.category == c,
                onSelected: (_) => ref.read(productListProvider.notifier)
                    .onCategorySelected(state.filter.category == c ? null : c),
              )),
              const VerticalDivider(indent: 8, endIndent: 8),
              ...StockStatus.values.map((s) => _FilterChip(
                label: s == StockStatus.inStock ? 'In Stock'
                    : s == StockStatus.lowStock ? 'Low Stock' : 'Out of Stock',
                selected: state.filter.stockStatus == s,
                onSelected: (_) => ref.read(productListProvider.notifier)
                    .onStockFilterChanged(state.filter.stockStatus == s ? null : s),
              )),
            ],
          ),
        ),
        const Divider(height: 1),
        // List
        Expanded(child: _buildBody(state)),
      ]),
    );
  }

  Widget _buildBody(ProductListState state) {
    if (state.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const ProductCardShimmer(),
      );
    }
    if (state.products.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No Products Found',
        subtitle: 'Try adjusting your search or filters',
        action: OutlinedButton(
          onPressed: () => ref.read(productListProvider.notifier).onCategorySelected(null),
          child: const Text('Clear Filters'),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        if (i == state.products.length) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
        }
        return ProductCard(
          product: state.products[i],
          onTap: () => context.push('/products/${state.products[i].id}'),
          onAddToCart: () => ref.read(productListProvider.notifier).addToCart(state.products[i]),
        ).animate().fadeIn(delay: Duration(milliseconds: min(i * 60, 400)))
            .slideY(begin: 0.3, duration: 300.ms);
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: selected ? const Icon(Icons.check, size: 14) : null,
    ),
  );
}

//Product Card
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap, onAddToCart;
  const ProductCard({super.key, required this.product, required this.onTap, required this.onAddToCart});
  @override State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final p = widget.product;
    final effective = p.effectivePrice(now);
    final offerActive = p.isOfferActive(now);
    final outOfStock = p.stockStatus == StockStatus.outOfStock;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: 150.ms,
        curve: Curves.easeOut,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // Image
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ProductImage(p.imageUrl, width: 90, height: 90),
                ),
                if (offerActive && p.discountPercent > 0)
                  Positioned(top: 4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange, borderRadius: BorderRadius.circular(4)),
                      child: Text('-${p.discountPercent.toInt()}%',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    )),
                if (outOfStock)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(width: 90, height: 90,
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text('Sold Out',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  ),
              ]),
              const SizedBox(width: 12),
              // Content
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VendorLabel(p.vendorName),
                  const SizedBox(height: 4),
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  PriceRow(
                    effectivePrice: effective, originalPrice: p.originalPrice,
                    discountPercent: p.discountPercent, isOfferActive: offerActive),
                  const SizedBox(height: 4),
                  Row(children: [
                    StockBadge(p.stockStatus),
                    const Spacer(),
                    if (offerActive && p.offerExpiresAt != null)
                      CountdownChip(p.offerExpiresAt!),
                  ]),
                ],
              )),
              const SizedBox(width: 8),
              // Add to cart FAB
              if (!outOfStock)
                GestureDetector(
                  onTap: widget.onAddToCart,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                  ).animate(onPlay: (c) => c.reset())
                      .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.elasticOut),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
