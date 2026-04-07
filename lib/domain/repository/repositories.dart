// lib/domain/repository/repositories.dart
import '../model/models.dart';

abstract class ProductRepository {
  Stream<List<Product>> getProducts(ProductFilter filter, int page, int pageSize);
  Future<Product> getProductById(String id);
  Future<List<String>> getCategories();
}

abstract class CartRepository {
  Stream<Cart> observeCart();
  Future<void> addToCart(Product product, int quantity);
  Future<void> updateQuantity(String productId, int quantity);
  Future<void> removeFromCart(String productId);
  Future<double> applyPromoCode(String code);
  Future<void> removePromoCode();
  Future<void> clearCart();
  Future<List<CartValidationIssue>> validateAndRefreshCart();
}

abstract class OrderRepository {
  Future<Order> createOrder(Cart cart);
  Stream<List<Order>> getOrders();
  Stream<Order?> getOrderById(String id);
  Future<Order> cancelOrder(String orderId);
  Future<Order> cancelOrderItem(String orderId, String itemId);
}
