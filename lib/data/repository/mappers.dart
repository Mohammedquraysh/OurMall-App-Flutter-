// lib/data/repository/mappers.dart
import '../remote/dto/dtos.dart';
import '../../domain/model/models.dart';

extension ProductDtoMapper on ProductDto {
  Product toDomain() => Product(
        id: id, name: name, imageUrl: imageUrl,
        originalPrice: originalPrice, discountPercent: discountPercent,
        offerExpiresAt: offerExpiresAt, vendorId: vendorId,
        vendorName: vendorName, category: category,
        stockQuantity: stockQuantity,
        stockStatus: stockQuantity == 0
            ? StockStatus.outOfStock
            : stockQuantity <= 5
                ? StockStatus.lowStock
                : StockStatus.inStock,
      );
}
