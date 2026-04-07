// lib/domain/usecase/order/order_usecases.dart
import '../../model/models.dart';
import '../../repository/repositories.dart';

class CreateOrderUseCase {
  final OrderRepository _repo;
  CreateOrderUseCase(this._repo);
  Future<Order> call(Cart cart) => _repo.createOrder(cart);
}

class GetOrdersUseCase {
  final OrderRepository _repo;
  GetOrdersUseCase(this._repo);
  Stream<List<Order>> call() => _repo.getOrders();
}

class GetOrderByIdUseCase {
  final OrderRepository _repo;
  GetOrderByIdUseCase(this._repo);
  Stream<Order?> call(String id) => _repo.getOrderById(id);
}

class CancelOrderUseCase {
  final OrderRepository _repo;
  CancelOrderUseCase(this._repo);
  Future<Order> call(String orderId) => _repo.cancelOrder(orderId);
}

class CancelOrderItemUseCase {
  final OrderRepository _repo;
  CancelOrderItemUseCase(this._repo);
  Future<Order> call(String orderId, String itemId) =>
      _repo.cancelOrderItem(orderId, itemId);
}
