// lib/data/repository/repository_impl.dart
import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../local/cart_local_storage.dart';
import '../remote/api/mock_product_api.dart';
import 'mappers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/repositories.dart';

// ── Product Repository ─────────────────────────────────────────────────────

class ProductRepositoryImpl implements ProductRepository {
  final MockProductApi _api;
  ProductRepositoryImpl(this._api);

  @override
  Stream<List<Product>> getProducts(ProductFilter filter, int page, int pageSize) async* {
    final response = await _api.getProducts(
      query: filter.searchQuery,
      category: filter.category,
      minPrice: filter.minPrice,
      maxPrice: filter.maxPrice,
      stockFilter: filter.stockStatus?.name.toUpperCase().replaceAll('STOCK', '_STOCK')
          .replaceFirst('IN_', 'IN_STOCK')
          .replaceFirst('LOW_', 'LOW_STOCK')
          .replaceFirst('OUT_OF_', 'OUT_OF_STOCK'),
      page: page,
      pageSize: pageSize,
    );
    yield response.items.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Product> getProductById(String id) async {
    final dto = await _api.getProductById(id);
    return dto.toDomain();
  }

  @override
  Future<List<String>> getCategories() => _api.getCategories();
}

//Cart Repository

class CartRepositoryImpl implements CartRepository {
  final CartLocalStorage _storage;
  final MockProductApi _api;
  final _cartController = StreamController<Cart>.broadcast();

  CartRepositoryImpl(this._storage, this._api) {
    _emitCart();
  }

  Future<void> _emitCart() async {
    final cart = await _buildCart();
    if (!_cartController.isClosed) _cartController.add(cart);
  }

  Future<Cart> _buildCart() async {
    final rows = await _storage.getCartItems();
    final promo = await _storage.getPromo();
    final items = rows.map(_rowToCartItem).toList();
    final vendorGroups = <String, List<CartItem>>{};
    for (final item in items) {
      vendorGroups.putIfAbsent(item.product.vendorId, () => []).add(item);
    }
    final vendorCarts = vendorGroups.entries.map((e) => VendorCart(
      vendorId: e.key,
      vendorName: e.value.first.product.vendorName,
      items: e.value,
    )).toList();
    return Cart(
      vendorCarts: vendorCarts,
      cartLevelDiscountPercent: promo?['discountPercent'] as double? ?? 0,
      promoCode: promo?['code'] as String?,
    );
  }

  CartItem _rowToCartItem(Map<String, dynamic> row) {
    final expiresMs = row['offerExpiresAtMs'] as int?;
    final product = Product(
      id: row['productId'] as String,
      name: row['productName'] as String,
      imageUrl: row['imageUrl'] as String,
      originalPrice: row['originalPrice'] as double,
      discountPercent: row['discountPercent'] as double,
      offerExpiresAt: expiresMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expiresMs)
          : null,
      vendorId: row['vendorId'] as String,
      vendorName: row['vendorName'] as String,
      category: row['category'] as String,
      stockQuantity: row['stockQuantity'] as int,
      stockStatus: _stockStatus(row['stockQuantity'] as int),
    );
    return CartItem(
      product: product,
      quantity: row['quantity'] as int,
      snapshotPrice: row['snapshotPrice'] as double,
      appliedProductDiscount: row['appliedProductDiscount'] as double,
    );
  }

  StockStatus _stockStatus(int qty) => qty == 0
      ? StockStatus.outOfStock
      : qty <= 5
          ? StockStatus.lowStock
          : StockStatus.inStock;

  @override
  Stream<Cart> observeCart() async* {
    yield await _buildCart();
    yield* _cartController.stream;
  }

  @override
  Future<void> addToCart(Product product, int quantity) async {
    final existing = await _storage.getCartItem(product.id);
    if (existing != null) {
      await _storage.updateQuantity(product.id, (existing['quantity'] as int) + quantity);
    } else {
      final now = DateTime.now();
      final effectivePrice = product.effectivePrice(now);
      final discount = product.isOfferActive(now) ? product.originalPrice - effectivePrice : 0.0;
      await _storage.upsertCartItem({
        'productId': product.id, 'productName': product.name,
        'imageUrl': product.imageUrl, 'originalPrice': product.originalPrice,
        'discountPercent': product.discountPercent,
        'offerExpiresAtMs': product.offerExpiresAt?.millisecondsSinceEpoch,
        'vendorId': product.vendorId, 'vendorName': product.vendorName,
        'category': product.category, 'stockQuantity': product.stockQuantity,
        'quantity': quantity, 'snapshotPrice': effectivePrice,
        'appliedProductDiscount': discount,
        'addedAt': now.millisecondsSinceEpoch,
      });
    }
    await _emitCart();
  }

  @override
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await _storage.deleteCartItem(productId);
    } else {
      await _storage.updateQuantity(productId, quantity);
    }
    await _emitCart();
  }

  @override
  Future<void> removeFromCart(String productId) async {
    await _storage.deleteCartItem(productId);
    await _emitCart();
  }

  @override
  Future<double> applyPromoCode(String code) async {
    final dto = await _api.validatePromoCode(code);
    await _storage.setPromo(dto.code, dto.discountPercent, dto.description);
    await _emitCart();
    return dto.discountPercent;
  }

  @override
  Future<void> removePromoCode() async {
    await _storage.clearPromo();
    await _emitCart();
  }

  @override
  Future<void> clearCart() async {
    await _storage.clearCart();
    await _storage.clearPromo();
    await _emitCart();
  }

  @override
  Future<List<CartValidationIssue>> validateAndRefreshCart() async {
    final rows = await _storage.getCartItems();
    if (rows.isEmpty) return [];
    final ids = rows.map((r) => r['productId'] as String).toList();
    final freshDtos = await _api.validateCartItems(ids);
    final issues = <CartValidationIssue>[];
    final now = DateTime.now();

    for (final dto in freshDtos) {
      final fresh = dto.toDomain();
      final row = rows.firstWhere((r) => r['productId'] == fresh.id);
      final cartQty = row['quantity'] as int;
      final cartSnapshot = row['snapshotPrice'] as double;
      final expiresMs = row['offerExpiresAtMs'] as int?;

      if (fresh.stockQuantity == 0) {
        issues.add(CartValidationIssue(
          productId: fresh.id, productName: fresh.name,
          issueType: CartIssueType.outOfStock,
          detail: '${fresh.name} is no longer available',
        ));
      } else if (cartQty > fresh.stockQuantity) {
        issues.add(CartValidationIssue(
          productId: fresh.id, productName: fresh.name,
          issueType: CartIssueType.insufficientStock,
          detail: 'Only ${fresh.stockQuantity} left for ${fresh.name}',
        ));
        await _storage.updateQuantity(fresh.id, fresh.stockQuantity);
      }

      final wasOfferActive = expiresMs != null &&
          DateTime.fromMillisecondsSinceEpoch(expiresMs).isAfter(now);
      final isOfferActive = fresh.isOfferActive(now);

      if (wasOfferActive && !isOfferActive) {
        issues.add(CartValidationIssue(
          productId: fresh.id, productName: fresh.name,
          issueType: CartIssueType.offerExpired,
          detail: 'Offer for ${fresh.name} has expired. Price updated to ₦${fresh.originalPrice.toStringAsFixed(0)}',
        ));
      }

      final newPrice = fresh.effectivePrice(now);
      if (newPrice != cartSnapshot && !(wasOfferActive && !isOfferActive)) {
        issues.add(CartValidationIssue(
          productId: fresh.id, productName: fresh.name,
          issueType: CartIssueType.priceChanged,
          detail: 'Price changed from ₦${cartSnapshot.toStringAsFixed(0)} to ₦${newPrice.toStringAsFixed(0)}',
        ));
      }

      final discount = isOfferActive ? fresh.originalPrice - newPrice : 0.0;
      await _storage.updatePriceAndStock(
        fresh.id, newPrice, discount, fresh.stockQuantity,
        fresh.offerExpiresAt?.millisecondsSinceEpoch,
      );
    }
    await _emitCart();
    return issues;
  }
}

//Order Repository

class OrderRepositoryImpl implements OrderRepository {
  final CartLocalStorage _storage;
  final _uuid = const Uuid();
  final _ordersController = StreamController<List<Order>>.broadcast();

  OrderRepositoryImpl(this._storage);

  Order _rowToOrder(Map<String, dynamic> row) {
    final vendorOrders = (jsonDecode(row['vendorOrdersJson'] as String) as List)
        .map((v) => VendorOrder(
              vendorId: v['vendorId'] as String,
              vendorName: v['vendorName'] as String,
              subtotal: (v['subtotal'] as num).toDouble(),
              items: (v['items'] as List).map((i) => OrderItem(
                    id: i['id'] as String,
                    productId: i['productId'] as String,
                    productName: i['productName'] as String,
                    imageUrl: i['imageUrl'] as String,
                    vendorId: i['vendorId'] as String,
                    vendorName: i['vendorName'] as String,
                    quantity: i['quantity'] as int,
                    unitPrice: (i['unitPrice'] as num).toDouble(),
                    discountAmount: (i['discountAmount'] as num).toDouble(),
                    status: OrderItemStatus.values.byName(i['status'] as String),
                    refundAmount: (i['refundAmount'] as num?)?.toDouble() ?? 0,
                  )).toList(),
            ))
        .toList();
    return Order(
      id: row['id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAtMs'] as int),
      vendorOrders: vendorOrders,
      cartLevelDiscountAmount: (row['cartLevelDiscountAmount'] as num).toDouble(),
      promoCode: row['promoCode'] as String?,
      status: OrderStatus.values.byName(row['statusStr'] as String),
    );
  }

  Map<String, dynamic> _orderToRow(Order order) => {
        'id': order.id,
        'createdAtMs': order.createdAt.millisecondsSinceEpoch,
        'statusStr': order.status.name,
        'vendorOrdersJson': jsonEncode(order.vendorOrders.map((vo) => {
          'vendorId': vo.vendorId,
          'vendorName': vo.vendorName,
          'subtotal': vo.subtotal,
          'items': vo.items.map((i) => {
            'id': i.id, 'productId': i.productId,
            'productName': i.productName, 'imageUrl': i.imageUrl,
            'vendorId': i.vendorId, 'vendorName': i.vendorName,
            'quantity': i.quantity, 'unitPrice': i.unitPrice,
            'discountAmount': i.discountAmount, 'status': i.status.name,
            'refundAmount': i.refundAmount,
          }).toList(),
        }).toList()),
        'cartLevelDiscountAmount': order.cartLevelDiscountAmount,
        'promoCode': order.promoCode,
      };

  Future<void> _emit() async {
    final rows = await _storage.getOrders();
    final orders = rows.map(_rowToOrder).toList();
    if (!_ordersController.isClosed) _ordersController.add(orders);
  }

  @override
  Future<Order> createOrder(Cart cart) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final orderId = 'ORD-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final vendorOrders = cart.vendorCarts.map((vc) {
      final items = vc.items.asMap().entries.map((e) => OrderItem(
            id: '$orderId-${vc.vendorId}-${e.key}',
            productId: e.value.product.id,
            productName: e.value.product.name,
            imageUrl: e.value.product.imageUrl,
            vendorId: vc.vendorId,
            vendorName: vc.vendorName,
            quantity: e.value.quantity,
            unitPrice: e.value.snapshotPrice,
            discountAmount: e.value.appliedProductDiscount,
            status: OrderItemStatus.pending,
          )).toList();
      return VendorOrder(
        vendorId: vc.vendorId, vendorName: vc.vendorName,
        items: items, subtotal: vc.subtotal,
      );
    }).toList();

    final order = Order(
      id: orderId, createdAt: DateTime.now(),
      vendorOrders: vendorOrders,
      cartLevelDiscountAmount: cart.cartLevelDiscountAmount,
      promoCode: cart.promoCode,
      status: OrderStatus.pending,
    );
    await _storage.upsertOrder(_orderToRow(order));
    await _emit();
    return order;
  }

  @override
  Stream<List<Order>> getOrders() async* {
    final rows = await _storage.getOrders();
    yield rows.map(_rowToOrder).toList();
    yield* _ordersController.stream;
  }

  @override
  Stream<Order?> getOrderById(String id) async* {
    final row = await _storage.getOrder(id);
    yield row != null ? _rowToOrder(row) : null;
    yield* _ordersController.stream.map((orders) {
      try { return orders.firstWhere((o) => o.id == id); }
      catch (_) { return null; }
    });
  }

  @override
  Future<Order> cancelOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final row = await _storage.getOrder(orderId);
    if (row == null) throw Exception('Order not found');
    var order = _rowToOrder(row);
    final updatedVOs = order.vendorOrders.map((vo) => vo.copyWith(
      items: vo.items.map((item) => item.canBeCancelled
          ? item.copyWith(status: OrderItemStatus.cancelled, refundAmount: item.lineTotal)
          : item).toList(),
    )).toList();
    final allCancelled = updatedVOs.expand((vo) => vo.items)
        .every((i) => i.status == OrderItemStatus.cancelled);
    order = order.copyWith(
      vendorOrders: updatedVOs,
      status: allCancelled ? OrderStatus.cancelled : OrderStatus.partiallyCancelled,
    );
    await _storage.upsertOrder(_orderToRow(order));
    await _emit();
    return order;
  }

  @override
  Future<Order> cancelOrderItem(String orderId, String itemId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final row = await _storage.getOrder(orderId);
    if (row == null) throw Exception('Order not found');
    var order = _rowToOrder(row);
    final target = order.allItems.firstWhere((i) => i.id == itemId,
        orElse: () => throw Exception('Item not found'));
    if (!target.canBeCancelled) throw Exception('Item cannot be cancelled');
    final updatedVOs = order.vendorOrders.map((vo) => vo.copyWith(
      items: vo.items.map((item) => item.id == itemId
          ? item.copyWith(status: OrderItemStatus.cancelled, refundAmount: item.lineTotal)
          : item).toList(),
    )).toList();
    final allItems = updatedVOs.expand((vo) => vo.items).toList();
    final newStatus = allItems.every((i) => i.status == OrderItemStatus.cancelled)
        ? OrderStatus.cancelled
        : allItems.any((i) => i.status == OrderItemStatus.cancelled)
            ? OrderStatus.partiallyCancelled
            : order.status;
    order = order.copyWith(vendorOrders: updatedVOs, status: newStatus);
    await _storage.upsertOrder(_orderToRow(order));
    await _emit();
    return order;
  }
}
