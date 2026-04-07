// lib/domain/usecase/product/product_usecases.dart
import '../../model/models.dart';
import '../../repository/repositories.dart';

class GetProductsUseCase {
  final ProductRepository _repo;
  GetProductsUseCase(this._repo);
  Stream<List<Product>> call(ProductFilter filter, {int page = 0, int pageSize = 10}) =>
      _repo.getProducts(filter, page, pageSize);
}

class GetProductByIdUseCase {
  final ProductRepository _repo;
  GetProductByIdUseCase(this._repo);
  Future<Product> call(String id) => _repo.getProductById(id);
}

class GetCategoriesUseCase {
  final ProductRepository _repo;
  GetCategoriesUseCase(this._repo);
  Future<List<String>> call() => _repo.getCategories();
}
