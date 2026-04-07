// lib/presentation/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/cart_local_storage.dart';
import '../../data/remote/api/mock_product_api.dart';
import '../../data/repository/repository_impl.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/repositories.dart';
import '../../domain/usecase/cart/cart_usecases.dart';
import '../../domain/usecase/order/order_usecases.dart';
import '../../domain/usecase/product/product_usecases.dart';

//Infrastructure
final mockApiProvider = Provider<MockProductApi>((_) => MockProductApi());

final localStorageProvider = Provider<CartLocalStorage>((_) => CartLocalStorage());

//Repositories
final productRepositoryProvider = Provider<ProductRepository>((ref) =>
    ProductRepositoryImpl(ref.read(mockApiProvider)));

final cartRepositoryProvider = Provider<CartRepository>((ref) =>
    CartRepositoryImpl(ref.read(localStorageProvider), ref.read(mockApiProvider)));

final orderRepositoryProvider = Provider<OrderRepository>((ref) =>
    OrderRepositoryImpl(ref.read(localStorageProvider)));

// Use Cases
final getProductsUseCaseProvider = Provider((ref) =>
    GetProductsUseCase(ref.read(productRepositoryProvider)));
final getProductByIdUseCaseProvider = Provider((ref) =>
    GetProductByIdUseCase(ref.read(productRepositoryProvider)));
final getCategoriesUseCaseProvider = Provider((ref) =>
    GetCategoriesUseCase(ref.read(productRepositoryProvider)));

final observeCartUseCaseProvider = Provider((ref) =>
    ObserveCartUseCase(ref.read(cartRepositoryProvider)));
final addToCartUseCaseProvider = Provider((ref) =>
    AddToCartUseCase(ref.read(cartRepositoryProvider)));
final updateCartQuantityUseCaseProvider = Provider((ref) =>
    UpdateCartQuantityUseCase(ref.read(cartRepositoryProvider)));
final removeFromCartUseCaseProvider = Provider((ref) =>
    RemoveFromCartUseCase(ref.read(cartRepositoryProvider)));
final applyPromoUseCaseProvider = Provider((ref) =>
    ApplyPromoCodeUseCase(ref.read(cartRepositoryProvider)));
final validateCartUseCaseProvider = Provider((ref) =>
    ValidateCartUseCase(ref.read(cartRepositoryProvider)));
final clearCartUseCaseProvider = Provider((ref) =>
    ClearCartUseCase(ref.read(cartRepositoryProvider)));

final createOrderUseCaseProvider = Provider((ref) =>
    CreateOrderUseCase(ref.read(orderRepositoryProvider)));
final getOrdersUseCaseProvider = Provider((ref) =>
    GetOrdersUseCase(ref.read(orderRepositoryProvider)));
final getOrderByIdUseCaseProvider = Provider((ref) =>
    GetOrderByIdUseCase(ref.read(orderRepositoryProvider)));
final cancelOrderUseCaseProvider = Provider((ref) =>
    CancelOrderUseCase(ref.read(orderRepositoryProvider)));
final cancelOrderItemUseCaseProvider = Provider((ref) =>
    CancelOrderItemUseCase(ref.read(orderRepositoryProvider)));

//Cart stream
final cartStreamProvider = StreamProvider<Cart>((ref) =>
    ref.read(observeCartUseCaseProvider)());

// Categories
final categoriesProvider = FutureProvider<List<String>>((ref) =>
    ref.read(getCategoriesUseCaseProvider)());
