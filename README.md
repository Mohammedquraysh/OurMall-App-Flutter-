# OurMall-App-Flutter-

**Company:** OurMall.eu  
**Framework:** Flutter (Dart)  
**Architecture:** Clean Architecture + Riverpod (MVVM equivalent)


## Architecture

The project is organized into multiple layers for better scalability and maintainability.

lib/main.dart – Entry point of the application.

Data Layer

Local: Uses SQLite (via sqflite) for storing cart, orders, and promo data.

Remote: Contains API-related logic, including a mock product API that simulates a real backend, and DTOs (Data Transfer Objects).

Repository: Handles data operations and mapping between data and domain models.

Domain Layer

Model: Contains pure Dart models such as Product, Cart, and Order.

Repository: Defines abstract interfaces for data operations.

Use Case: Contains business logic, with one use case per action.

Presentation Layer

Theme: Supports light and dark themes using Material 3.

Navigation: Uses GoRouter with animated transitions.

Providers: Manages dependency injection and state using Riverpod.

Widgets: Contains reusable UI components.

Screens:

Products: Product list and product detail screens.

Cart: Cart screen.

Checkout: Checkout screen.

Order: Order list and order detail screens.

Utils

Contains helper functions such as formatting price and countdown.

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

