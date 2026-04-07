// lib/presentation/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screen/products/product_list_screen.dart';
import '../screen/products/product_detail_screen.dart';
import '../screen/cart/cart_screen.dart';
import '../screen/checkout/checkout_screen.dart';
import '../screen/order/order_list_screen.dart';
import '../screen/order/order_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/products',
  routes: [
    GoRoute(
      path: '/products',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        child: const ProductListScreen(),
        transitionsBuilder: _slideRight,
      ),
    ),
    GoRoute(
      path: '/products/:id',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        child: ProductDetailScreen(productId: state.pathParameters['id']!),
        transitionsBuilder: _scaleTransition,
      ),
    ),
    GoRoute(
      path: '/cart',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        child: const CartScreen(),
        transitionsBuilder: _slideRight,
      ),
    ),
    GoRoute(
      path: '/checkout',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        child: const CheckoutScreen(),
        transitionsBuilder: _slideRight,
      ),
    ),
    GoRoute(
      path: '/orders',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        child: const OrderListScreen(),
        transitionsBuilder: _slideRight,
      ),
    ),
    GoRoute(
      path: '/orders/:id',
      pageBuilder: (ctx, state) => CustomTransitionPage(
        child: OrderDetailScreen(orderId: state.pathParameters['id']!),
        transitionsBuilder: _scaleTransition,
      ),
    ),
  ],
);

Widget _slideRight(ctx, anim, secondAnim, child) => SlideTransition(
  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
      .animate(CurvedAnimation(parent: anim, curve: Curves.fastOutSlowIn)),
  child: child,
);

Widget _scaleTransition(ctx, anim, secondAnim, child) => ScaleTransition(
  scale: Tween<double>(begin: 0.92, end: 1)
      .animate(CurvedAnimation(parent: anim, curve: Curves.fastOutSlowIn)),
  child: FadeTransition(opacity: anim, child: child),
);
