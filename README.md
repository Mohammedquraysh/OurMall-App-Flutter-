# OurMall-App-Flutter-

**Company:** OurMall.eu  
**Framework:** Flutter (Dart)  
**Architecture:** Clean Architecture + Riverpod (MVVM equivalent)


## Architecture
lib/
├── main.dart
├── data/
│   ├── local/   SQLite via sqflite (cart, orders, promo)
│   ├── remote/
│   │   ├── api/         MockProductApi — simulates real backend
│   │   └── dto/         Data Transfer Objects
│   └── repository/      Repository implementations + mappers
├── domain/
│   ├── model/           Pure Dart models (Product, Cart, Order…)
│   ├── repository/      Abstract interfaces
│   └── usecase/         One use case per action
├── presentation/
│   ├── theme/           Light + dark Material3 theme
│   ├── navigation/      GoRouter with animated transitions
│   ├── providers/       Riverpod DI + state providers
│   ├── widgets/         Shared reusable widgets
│   └── screen/
│       ├── products/    ProductListScreen + ProductDetailScreen
│       ├── cart/        CartScreen
│       ├── checkout/    CheckoutScreen
│       └── order/       OrderListScreen + OrderDetailScreen
└── util/                Extension functions (formatPrice, formatCountdown)


## Features

### Task 1 — Product Listing + Dynamic Pricing
- Product cards: image, name, price, vendor, discount badge, stock status
- Live countdown timer per offer (ticks every second, auto-updates price on expiry)
- Search with 400ms debounce
- Filter by category and stock status
- Infinite scroll / lazy pagination
- API failure handling with retry snackbar
- Shimmer loading placeholders on all product cards

### Task 2 — Cart + Multi-Vendor Logic
- Multi-vendor cart grouped by vendor
- Duplicate item merging (re-adding increments quantity)
- Product-level discounts snapshotted at add time
- Cart-level discounts via promo codes (`OURMALL10`, `SAVE20`, `WELCOME5`)
- Offer expiry detection inside cart with warning banner
- Stock validation inside cart (out-of-stock + low-stock warnings)
- Swipe-to-dismiss cart items
- Animated quantity selector (slide up/down)
- Animated grand total (TweenAnimationBuilder count-up)
- Auto price refresh every 30s while cart is open

### Task 3 — Checkout + Order + Cancellation
- Pre-checkout validation: stock, price freshness, offer validity
- Animated placing order screen → bouncing success checkmark
- Order creation with vendor-wise grouping
- Full order cancellation + single item cancellation
- Refund scoped to cancelled item line total
- Animated order status stepper
- Totals recalculate and animate after cancellation

---

