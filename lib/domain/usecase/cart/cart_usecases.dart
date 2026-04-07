// lib/domain/usecase/cart/cart_usecases.dart
import '../../model/models.dart';
import '../../repository/repositories.dart';

class ObserveCartUseCase {
  final CartRepository _repo;
  ObserveCartUseCase(this._repo);
  Stream<Cart> call() => _repo.observeCart();
}

class AddToCartUseCase {
  final CartRepository _repo;
  AddToCartUseCase(this._repo);
  Future<void> call(Product product, {int quantity = 1}) =>
      _repo.addToCart(product, quantity);
}

class UpdateCartQuantityUseCase {
  final CartRepository _repo;
  UpdateCartQuantityUseCase(this._repo);
  Future<void> call(String productId, int quantity) =>
      _repo.updateQuantity(productId, quantity);
}

class RemoveFromCartUseCase {
  final CartRepository _repo;
  RemoveFromCartUseCase(this._repo);
  Future<void> call(String productId) => _repo.removeFromCart(productId);
}

class ApplyPromoCodeUseCase {
  final CartRepository _repo;
  ApplyPromoCodeUseCase(this._repo);
  Future<double> call(String code) => _repo.applyPromoCode(code);
}

class ValidateCartUseCase {
  final CartRepository _repo;
  ValidateCartUseCase(this._repo);
  Future<List<CartValidationIssue>> call() => _repo.validateAndRefreshCart();
}

class ClearCartUseCase {
  final CartRepository _repo;
  ClearCartUseCase(this._repo);
  Future<void> call() => _repo.clearCart();
}
