// lib/domain/model/models.dart

enum StockStatus { inStock, lowStock, outOfStock }

enum OrderItemStatus { pending, confirmed, shipped, delivered, cancelled }

enum OrderStatus {
  pending,
  confirmed,
  partiallyCancelled,
  cancelled,
  completed
}

// ── Product ───────────────────────────────────────────────────────────────

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double originalPrice;
  final double discountPercent;
  final DateTime? offerExpiresAt;
  final String vendorId;
  final String vendorName;
  final String category;
  final int stockQuantity;
  final StockStatus stockStatus;

  const Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.originalPrice,
    required this.discountPercent,
    this.offerExpiresAt,
    required this.vendorId,
    required this.vendorName,
    required this.category,
    required this.stockQuantity,
    required this.stockStatus,
  });

  bool isOfferActive([DateTime? now]) {
    final t = now ?? DateTime.now();
    return offerExpiresAt != null &&
        t.isBefore(offerExpiresAt!) &&
        discountPercent > 0;
  }

  double effectivePrice([DateTime? now]) {
    if (isOfferActive(now)) {
      return originalPrice * (1.0 - discountPercent / 100.0);
    }
    return originalPrice;
  }

  int secondsUntilExpiry([DateTime? now]) {
    if (offerExpiresAt == null) return 0;
    final t = now ?? DateTime.now();
    return offerExpiresAt!.difference(t).inSeconds.clamp(0, double.maxFinite.toInt());
  }

  Product copyWith({int? stockQuantity, StockStatus? stockStatus}) => Product(
        id: id,
        name: name,
        imageUrl: imageUrl,
        originalPrice: originalPrice,
        discountPercent: discountPercent,
        offerExpiresAt: offerExpiresAt,
        vendorId: vendorId,
        vendorName: vendorName,
        category: category,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        stockStatus: stockStatus ?? this.stockStatus,
      );
}

// ── Cart ──────────────────────────────────────────────────────────────────

class CartItem {
  final Product product;
  final int quantity;
  final double snapshotPrice;
  final double appliedProductDiscount;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.snapshotPrice,
    required this.appliedProductDiscount,
  });

  double get lineTotal => snapshotPrice * quantity;
  double get discountedLineTotal => (snapshotPrice - appliedProductDiscount) * quantity;

  CartItem copyWith({int? quantity, double? snapshotPrice, double? appliedProductDiscount}) =>
      CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
        snapshotPrice: snapshotPrice ?? this.snapshotPrice,
        appliedProductDiscount: appliedProductDiscount ?? this.appliedProductDiscount,
      );
}

class VendorCart {
  final String vendorId;
  final String vendorName;
  final List<CartItem> items;

  const VendorCart({
    required this.vendorId,
    required this.vendorName,
    required this.items,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.discountedLineTotal);
  double get totalDiscount => items.fold(0, (sum, i) => sum + i.appliedProductDiscount * i.quantity);
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}

class Cart {
  final List<VendorCart> vendorCarts;
  final double cartLevelDiscountPercent;
  final String? promoCode;

  const Cart({
    this.vendorCarts = const [],
    this.cartLevelDiscountPercent = 0,
    this.promoCode,
  });

  double get subtotalBeforeCartDiscount =>
      vendorCarts.fold(0, (sum, vc) => sum + vc.subtotal);
  double get cartLevelDiscountAmount =>
      subtotalBeforeCartDiscount * (cartLevelDiscountPercent / 100.0);
  double get grandTotal => subtotalBeforeCartDiscount - cartLevelDiscountAmount;
  int get totalItems => vendorCarts.fold(0, (sum, vc) => sum + vc.itemCount);
  bool get isEmpty => totalItems == 0;
}

//Order

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final String vendorId;
  final String vendorName;
  final int quantity;
  final double unitPrice;
  final double discountAmount;
  final OrderItemStatus status;
  final double refundAmount;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.vendorId,
    required this.vendorName,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.status,
    this.refundAmount = 0,
  });

  double get lineTotal => (unitPrice - discountAmount) * quantity;
  bool get canBeCancelled =>
      status == OrderItemStatus.pending || status == OrderItemStatus.confirmed;

  OrderItem copyWith({OrderItemStatus? status, double? refundAmount}) => OrderItem(
        id: id,
        productId: productId,
        productName: productName,
        imageUrl: imageUrl,
        vendorId: vendorId,
        vendorName: vendorName,
        quantity: quantity,
        unitPrice: unitPrice,
        discountAmount: discountAmount,
        status: status ?? this.status,
        refundAmount: refundAmount ?? this.refundAmount,
      );
}

class VendorOrder {
  final String vendorId;
  final String vendorName;
  final List<OrderItem> items;
  final double subtotal;

  const VendorOrder({
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.subtotal,
  });

  List<OrderItem> get activeItems =>
      items.where((i) => i.status != OrderItemStatus.cancelled).toList();
  double get activeSubtotal =>
      activeItems.fold(0, (sum, i) => sum + i.lineTotal);

  VendorOrder copyWith({List<OrderItem>? items}) => VendorOrder(
        vendorId: vendorId,
        vendorName: vendorName,
        items: items ?? this.items,
        subtotal: subtotal,
      );
}

class Order {
  final String id;
  final DateTime createdAt;
  final List<VendorOrder> vendorOrders;
  final double cartLevelDiscountAmount;
  final String? promoCode;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.createdAt,
    required this.vendorOrders,
    required this.cartLevelDiscountAmount,
    this.promoCode,
    required this.status,
  });

  List<OrderItem> get allItems =>
      vendorOrders.expand((vo) => vo.items).toList();
  List<VendorOrder> get activeVendorOrders =>
      vendorOrders.where((vo) => vo.activeItems.isNotEmpty).toList();
  double get grandTotal =>
      vendorOrders.fold(0, (sum, vo) => sum + vo.activeSubtotal) -
      cartLevelDiscountAmount;
  double get totalRefunded =>
      allItems.where((i) => i.status == OrderItemStatus.cancelled)
          .fold(0, (sum, i) => sum + i.refundAmount);

  Order copyWith({List<VendorOrder>? vendorOrders, OrderStatus? status}) => Order(
        id: id,
        createdAt: createdAt,
        vendorOrders: vendorOrders ?? this.vendorOrders,
        cartLevelDiscountAmount: cartLevelDiscountAmount,
        promoCode: promoCode,
        status: status ?? this.status,
      );
}

// Filter

class ProductFilter {
  final String searchQuery;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final StockStatus? stockStatus;

  const ProductFilter({
    this.searchQuery = '',
    this.category,
    this.minPrice,
    this.maxPrice,
    this.stockStatus,
  });

  ProductFilter copyWith({
    String? searchQuery,
    Object? category = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? stockStatus = _sentinel,
  }) =>
      ProductFilter(
        searchQuery: searchQuery ?? this.searchQuery,
        category: category == _sentinel ? this.category : category as String?,
        minPrice: minPrice == _sentinel ? this.minPrice : minPrice as double?,
        maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
        stockStatus: stockStatus == _sentinel
            ? this.stockStatus
            : stockStatus as StockStatus?,
      );
}

const _sentinel = Object();

//Cart Validation

enum CartIssueType { priceChanged, outOfStock, offerExpired, insufficientStock }

class CartValidationIssue {
  final String productId;
  final String productName;
  final CartIssueType issueType;
  final String detail;

  const CartValidationIssue({
    required this.productId,
    required this.productName,
    required this.issueType,
    required this.detail,
  });
}
