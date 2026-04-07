// lib/data/remote/api/mock_product_api.dart
import 'dart:math';
import '../dto/dtos.dart';

class MockProductApi {
  final _random = Random();
  final Map<String, int> _stockMap = {};

  static final _vendors = [
    VendorDto('v1', 'TechZone Electronics'),
    VendorDto('v2', 'Fashion Forward'),
    VendorDto('v3', 'Home & Living'),
    VendorDto('v4', 'Sports Galaxy'),
    VendorDto('v5', 'Beauty Luxe'),
  ];

  late final List<ProductDto> _allProducts = _buildProducts();

  List<ProductDto> _buildProducts() {
    final now = DateTime.now();
    final products = [
      _p('p001', 'Samsung 4K QLED TV 55"',      'https://picsum.photos/seed/tv55/400/400',      450000, 15, now.add(const Duration(hours: 2)),  'v1', 'Electronics', 12),
      _p('p002', 'Apple AirPods Pro (2nd Gen)',  'https://picsum.photos/seed/airpods/400/400',   185000, 10, now.add(const Duration(hours: 6)),  'v1', 'Electronics', 25),
      _p('p003', 'Sony WH-1000XM5 Headphones',  'https://picsum.photos/seed/sony/400/400',      120000, 20, now.add(const Duration(hours: 1)),  'v1', 'Electronics', 3),
      _p('p004', 'iPad Air 5th Generation',      'https://picsum.photos/seed/ipad/400/400',      350000, 0,  null,                               'v1', 'Electronics', 8),
      _p('p005', 'Samsung Galaxy S24 Ultra',     'https://picsum.photos/seed/s24/400/400',       680000, 5,  now.add(const Duration(hours: 12)), 'v1', 'Electronics', 15),
      _p('p006', 'Dell XPS 15 Laptop',           'https://picsum.photos/seed/dell/400/400',      920000, 8,  now.add(const Duration(hours: 3)),  'v1', 'Electronics', 0),
      _p('p007', 'Nike Air Max 270',             'https://picsum.photos/seed/nike/400/400',       45000, 25, now.add(const Duration(hours: 4)),  'v2', 'Fashion',     20),
      _p('p008', "Levi's 501 Original Jeans",    'https://picsum.photos/seed/levis/400/400',      18500, 0,  null,                               'v2', 'Fashion',     35),
      _p('p009', 'Ray-Ban Aviator Sunglasses',   'https://picsum.photos/seed/rayban/400/400',     32000, 12, now.add(const Duration(hours: 8)),  'v2', 'Fashion',     2),
      _p('p010', 'Zara Trench Coat',             'https://picsum.photos/seed/zara/400/400',       28000, 30, now.add(const Duration(hours: 1)),  'v2', 'Fashion',     7),
      _p('p011', 'Nespresso Vertuo Coffee Machine','https://picsum.photos/seed/nespresso/400/400', 65000, 18, now.add(const Duration(hours: 5)), 'v3', 'Home',        10),
      _p('p012', 'Dyson V15 Vacuum Cleaner',     'https://picsum.photos/seed/dyson/400/400',     145000, 0,  null,                               'v3', 'Home',        4),
      _p('p013', 'KitchenAid Stand Mixer',       'https://picsum.photos/seed/kitchenaid/400/400', 89000, 22, now.add(const Duration(hours: 3)),  'v3', 'Home',        6),
      _p('p014', 'IKEA KALLAX Shelf Unit',       'https://picsum.photos/seed/kallax/400/400',     25000, 0,  null,                               'v3', 'Home',        0),
      _p('p015', 'Garmin Forerunner 265',        'https://picsum.photos/seed/garmin/400/400',    210000, 15, now.add(const Duration(hours: 7)),  'v4', 'Sports',      9),
      _p('p016', 'Wilson Pro Staff Tennis Racket','https://picsum.photos/seed/wilson/400/400',    38000, 0,  null,                               'v4', 'Sports',      14),
      _p('p017', 'Adidas Ultraboost 23 Shoes',   'https://picsum.photos/seed/adidas/400/400',     55000, 20, now.add(const Duration(hours: 2)),  'v4', 'Sports',      18),
      _p('p018', 'La Mer Moisturizing Cream',    'https://picsum.photos/seed/lamer/400/400',      78000, 10, now.add(const Duration(hours: 9)),  'v5', 'Beauty',      5),
      _p('p019', 'Charlotte Tilbury Palette',    'https://picsum.photos/seed/ct/400/400',         22000, 0,  null,                               'v5', 'Beauty',      22),
      _p('p020', 'Dyson Airwrap Multi-Styler',   'https://picsum.photos/seed/airwrap/400/400',   165000, 12, now.add(const Duration(hours: 6)),  'v5', 'Beauty',      3),
    ];
    for (final p in products) { _stockMap[p.id] = p.stockQuantity; }
    return products;
  }

  ProductDto _p(String id, String name, String imageUrl, double price,
      double discount, DateTime? expires, String vendorId, String category, int stock) {
    final vendor = _vendors.firstWhere((v) => v.id == vendorId);
    return ProductDto(
      id: id, name: name, imageUrl: imageUrl, originalPrice: price,
      discountPercent: discount, offerExpiresAt: expires,
      vendorId: vendorId, vendorName: vendor.name,
      category: category, stockQuantity: stock,
    );
  }

  Future<PagedResponse<ProductDto>> getProducts({
    String query = '', String? category, double? minPrice,
    double? maxPrice, String? stockFilter, int page = 0, int pageSize = 10,
  }) async {
    await _simulateNetwork();
    _maybeThrowError();
    _randomlyUpdateStock();

    var filtered = _allProducts.where((p) {
      if (query.isNotEmpty && !p.name.toLowerCase().contains(query.toLowerCase())) return false;
      if (category != null && p.category.toLowerCase() != category.toLowerCase()) return false;
      if (minPrice != null && p.originalPrice < minPrice) return false;
      if (maxPrice != null && p.originalPrice > maxPrice) return false;
      final stock = _stockMap[p.id] ?? 0;
      if (stockFilter == 'IN_STOCK' && stock <= 5) return false;
      if (stockFilter == 'LOW_STOCK' && (stock == 0 || stock > 5)) return false;
      if (stockFilter == 'OUT_OF_STOCK' && stock > 0) return false;
      return true;
    }).map((p) => p.copyWith(stockQuantity: _stockMap[p.id] ?? 0)).toList();

    final total = filtered.length;
    final start = page * pageSize;
    final paged = filtered.skip(start).take(pageSize).toList();
    return PagedResponse(
      items: paged, totalCount: total, page: page,
      pageSize: pageSize, hasNextPage: start + pageSize < total,
    );
  }

  Future<ProductDto> getProductById(String id) async {
    await _simulateNetwork();
    _maybeThrowError();
    final p = _allProducts.firstWhere((p) => p.id == id);
    return p.copyWith(stockQuantity: _stockMap[id] ?? 0);
  }

  Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ['Electronics', 'Fashion', 'Home', 'Sports', 'Beauty'];
  }

  Future<List<ProductDto>> validateCartItems(List<String> ids) async {
    await _simulateNetwork();
    return ids.map((id) {
      final p = _allProducts.firstWhere((p) => p.id == id,
          orElse: () => throw Exception('Product $id not found'));
      return p.copyWith(stockQuantity: _stockMap[id] ?? 0);
    }).toList();
  }

  Future<PromoCodeDto> validatePromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    switch (code.toUpperCase()) {
      case 'OURMALL10': return PromoCodeDto(code, 10, '10% off your order');
      case 'SAVE20':    return PromoCodeDto(code, 20, '20% off your order');
      case 'WELCOME5':  return PromoCodeDto(code, 5,  'Welcome discount 5%');
      default: throw Exception('Invalid promo code');
    }
  }

  Future<void> _simulateNetwork() async =>
      Future.delayed(Duration(milliseconds: 400 + _random.nextInt(500)));

  void _maybeThrowError() {
    if (_random.nextDouble() < 0.05) throw Exception('Network error: Please check your connection');
  }

  void _randomlyUpdateStock() {
    if (_random.nextDouble() < 0.1) {
      final p = _allProducts[_random.nextInt(_allProducts.length)];
      final current = _stockMap[p.id] ?? 0;
      _stockMap[p.id] = (current + _random.nextInt(5) - 2).clamp(0, 99);
    }
  }
}
