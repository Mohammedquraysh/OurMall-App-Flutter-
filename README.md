# OurMall Flutter App

**Company:** OurMall.eu  
**Framework:** Flutter (Dart)  
**Architecture:** Clean Architecture + Riverpod (MVVM equivalent)

---

## Architecture

```
lib/
├── main.dart
├── data/
│   ├── local/           SQLite via sqflite (cart, orders, promo)
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
```

---

## How to Run

### Prerequisites
- Flutter SDK 3.22+ (`flutter --version`)
- Dart SDK 3.3+
- Android Studio or VS Code with Flutter plugin
- Android emulator or physical device (API 21+) or iOS Simulator

### Steps

```bash
# 1. Navigate into the project
cd OurMallFlutter

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

> No API keys or backend setup needed — fully self-contained mock API.

---

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

## Animations

| Location | Animation |
|---|---|
| Screen transitions | Slide + scale via GoRouter CustomTransitionPage |
| Product card entry | Staggered fadeIn + slideY |
| Cart badge count | Scale-in spring on count change |
| Countdown chip | Fade pulse when < 10 min |
| Stock pulsing dot | Scale loop for in-stock indicator |
| Quantity selector | AnimatedSwitcher slide up/down |
| Cart/order totals | TweenAnimationBuilder count-up |
| Empty state icon | Elastic scale-in |
| Order success | Elastic bounce check circle |
| Status stepper | AnimatedContainer + fill line |
| Shimmer loaders | Shimmer sweep on placeholders |
| Offer expiry warnings | FadeIn + slideY on appearance |

---

## Mock Promo Codes

| Code | Discount |
|---|---|
| `OURMALL10` | 10% off |
| `SAVE20` | 20% off |
| `WELCOME5` | 5% off |

---

## Notes

- Images are served by **Picsum Photos** (`https://picsum.photos/seed/{name}/400/400`) — seeded URLs return consistent photos per product. Replace with real CDN URLs in production.
- All data persists locally across sessions via **sqflite**.
- The mock API simulates 400–900ms latency, 5% random failure rate, and live stock fluctuations.
