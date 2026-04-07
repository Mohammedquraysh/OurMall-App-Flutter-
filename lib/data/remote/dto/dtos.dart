// lib/data/remote/dto/dtos.dart

class ProductDto {
  final String id, name, imageUrl, vendorId, vendorName, category;
  final double originalPrice, discountPercent;
  final DateTime? offerExpiresAt;
  final int stockQuantity;

  const ProductDto({
    required this.id, required this.name, required this.imageUrl,
    required this.originalPrice, required this.discountPercent,
    this.offerExpiresAt, required this.vendorId, required this.vendorName,
    required this.category, required this.stockQuantity,
  });

  ProductDto copyWith({int? stockQuantity}) => ProductDto(
    id: id, name: name, imageUrl: imageUrl, originalPrice: originalPrice,
    discountPercent: discountPercent, offerExpiresAt: offerExpiresAt,
    vendorId: vendorId, vendorName: vendorName, category: category,
    stockQuantity: stockQuantity ?? this.stockQuantity,
  );
}

class VendorDto {
  final String id, name;
  const VendorDto(this.id, this.name);
}

class PagedResponse<T> {
  final List<T> items;
  final int totalCount, page, pageSize;
  final bool hasNextPage;
  const PagedResponse({
    required this.items, required this.totalCount,
    required this.page, required this.pageSize, required this.hasNextPage,
  });
}

class PromoCodeDto {
  final String code, description;
  final double discountPercent;
  const PromoCodeDto(this.code, this.discountPercent, this.description);
}
