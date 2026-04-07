// lib/presentation/widgets/shared_widgets.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/model/models.dart';
import '../theme/app_theme.dart';
import '../../util/extensions.dart';

// ── Shimmer Placeholder ────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width, height;
  final double radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.card : Colors.grey[300]!,
      highlightColor: isDark ? AppColors.border : Colors.grey[100]!,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : Colors.grey[300],
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ShimmerBox(width: 90, height: 90, radius: 12),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 60, height: 12),
            const SizedBox(height: 8),
            ShimmerBox(width: double.infinity, height: 16),
            const SizedBox(height: 6),
            ShimmerBox(width: 120, height: 20),
            const SizedBox(height: 6),
            ShimmerBox(width: 80, height: 12),
          ],
        )),
      ]),
    ),
  );
}

// ── Stock Badge ────────────────────────────────────────────────────────────

class StockBadge extends StatelessWidget {
  final StockStatus status;
  const StockBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      StockStatus.inStock    => ('In Stock',     AppColors.green),
      StockStatus.lowStock   => ('Low Stock',    AppColors.amber),
      StockStatus.outOfStock => ('Out of Stock', AppColors.red),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (status == StockStatus.inStock)
        _PulsingDot(color: color)
      else
        Container(width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _scale = Tween(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(width: 7, height: 7,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
  );
}

// ── Countdown Chip ─────────────────────────────────────────────────────────

class CountdownChip extends StatefulWidget {
  final DateTime expiresAt;
  const CountdownChip(this.expiresAt, {super.key});
  @override State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 99999);
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _secondsLeft = widget.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 99999);
        });
        if (_secondsLeft <= 0) _timer?.cancel();
      });
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft <= 0) return const SizedBox.shrink();
    final isUrgent = _secondsLeft <= 600;
    final color = isUrgent ? AppColors.red : AppColors.orange;
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_outlined, size: 12, color: color),
        const SizedBox(width: 4),
        Text('Ends in ${_secondsLeft.formatCountdown}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
    if (isUrgent) {
      chip = chip.animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 600.ms).fadeOut(duration: 600.ms);
    }
    return chip;
  }
}

// ── Price Row ──────────────────────────────────────────────────────────────

class PriceRow extends StatelessWidget {
  final double effectivePrice, originalPrice, discountPercent;
  final bool isOfferActive;
  const PriceRow({super.key,
    required this.effectivePrice, required this.originalPrice,
    required this.discountPercent, required this.isOfferActive});

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 6,
    children: [
      Text(effectivePrice.formatPrice,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      if (isOfferActive && discountPercent > 0) ...[
        Text(originalPrice.formatPrice,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            decoration: TextDecoration.lineThrough)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.orange, borderRadius: BorderRadius.circular(4)),
          child: Text('-${discountPercent.toInt()}%',
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ],
  );
}

// ── Vendor Chip ────────────────────────────────────────────────────────────

class VendorLabel extends StatelessWidget {
  final String vendorName;
  const VendorLabel(this.vendorName, {super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.store_outlined, size: 12, color: Theme.of(context).colorScheme.primary),
    const SizedBox(width: 4),
    Flexible(child: Text(vendorName, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.primary))),
  ]);
}

// ── Product Image ──────────────────────────────────────────────────────────

class ProductImage extends StatelessWidget {
  final String url;
  final double? width, height;
  final BoxFit fit;
  const ProductImage(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: url, width: width, height: height, fit: fit,
    placeholder: (_, __) => ShimmerBox(
      width: width ?? 90, height: height ?? 90,
      radius: 8,
    ),
    errorWidget: (_, __, ___) => Container(
      width: width, height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

// ── Quantity Selector ──────────────────────────────────────────────────────

class QuantitySelector extends StatelessWidget {
  final int quantity, maxQuantity;
  final VoidCallback onDecrease, onIncrease;
  const QuantitySelector({super.key,
    required this.quantity, required this.onDecrease, required this.onIncrease,
    this.maxQuantity = 99});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 32, height: 32,
        child: IconButton(
          onPressed: onDecrease, padding: EdgeInsets.zero,
          icon: Icon(
            quantity <= 1 ? Icons.delete_outline : Icons.remove,
            size: 16,
            color: quantity <= 1
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      AnimatedSwitcher(
        duration: 150.ms,
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: SizedBox(
          key: ValueKey(quantity),
          width: 28,
          child: Text('$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        ),
      ),
      SizedBox(
        width: 32, height: 32,
        child: IconButton(
          onPressed: quantity < maxQuantity ? onIncrease : null,
          padding: EdgeInsets.zero,
          icon: Icon(Icons.add, size: 16,
            color: quantity < maxQuantity
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    ]),
  );
}

// ── OurMall App Bar ────────────────────────────────────────────────────────

class OurMallAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack, onCart, onOrders;
  final int cartCount;
  final List<Widget> actions;
  const OurMallAppBar({super.key, required this.title,
    this.onBack, this.onCart, this.onOrders, this.cartCount = 0, this.actions = const []});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title),
    leading: onBack != null
        ? IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: onBack)
        : null,
    actions: [
      ...actions,
      if (onOrders != null)
        IconButton(icon: const Icon(Icons.receipt_outlined), onPressed: onOrders),
      if (onCart != null)
        Stack(children: [
          IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: onCart),
          if (cartCount > 0)
            Positioned(
              right: 6, top: 6,
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.orange, shape: BoxShape.circle),
                child: Text('$cartCount',
                  style: const TextStyle(fontSize: 9, color: Colors.white,
                    fontWeight: FontWeight.bold)),
              ).animate().scale(
                begin: const Offset(0, 0), end: const Offset(1, 1),
                curve: Curves.elasticOut, duration: 400.ms),
            ),
        ]),
    ],
  );
}

// ── Empty State ────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.icon,
    required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
        ).animate().scale(
          begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 600.ms),
        const SizedBox(height: 20),
        Text(title, style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold))
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant))
            .animate().fadeIn(delay: 300.ms),
        if (action != null) ...[const SizedBox(height: 24), action!.animate().fadeIn(delay: 400.ms)],
      ]),
    ),
  );
}

// ── Our Mall Button ────────────────────────────────────────────────────────

class OurMallButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  const OurMallButton({super.key, required this.text, this.onPressed,
    this.isLoading = false, this.icon, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52, width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: AnimatedSwitcher(
        duration: 200.ms,
        child: isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
      ),
    ),
  );
}

// ── Order Item Status Chip ─────────────────────────────────────────────────

class OrderItemStatusBadge extends StatelessWidget {
  final OrderItemStatus status;
  const OrderItemStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      OrderItemStatus.pending   => ('Pending',   AppColors.amber),
      OrderItemStatus.confirmed => ('Confirmed', AppColors.blue),
      OrderItemStatus.shipped   => ('Shipped',   AppColors.orange),
      OrderItemStatus.delivered => ('Delivered', AppColors.green),
      OrderItemStatus.cancelled => ('Cancelled', AppColors.red),
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
