
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CartLocalStorage {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'ourmall.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cart_items (
            productId TEXT PRIMARY KEY,
            productName TEXT, imageUrl TEXT, originalPrice REAL,
            discountPercent REAL, offerExpiresAtMs INTEGER,
            vendorId TEXT, vendorName TEXT, category TEXT,
            stockQuantity INTEGER, quantity INTEGER,
            snapshotPrice REAL, appliedProductDiscount REAL,
            addedAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            createdAtMs INTEGER,
            statusStr TEXT,
            vendorOrdersJson TEXT,
            cartLevelDiscountAmount REAL,
            promoCode TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE promo (
            id INTEGER PRIMARY KEY,
            code TEXT,
            discountPercent REAL,
            description TEXT
          )
        ''');
      },
    );
  }

  //Cart

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final d = await db;
    return d.query('cart_items', orderBy: 'addedAt ASC');
  }

  Future<Map<String, dynamic>?> getCartItem(String productId) async {
    final d = await db;
    final rows = await d.query('cart_items', where: 'productId = ?', whereArgs: [productId]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertCartItem(Map<String, dynamic> item) async {
    final d = await db;
    await d.insert('cart_items', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateQuantity(String productId, int qty) async {
    final d = await db;
    await d.update('cart_items', {'quantity': qty}, where: 'productId = ?', whereArgs: [productId]);
  }

  Future<void> updatePriceAndStock(String productId, double price,
      double discount, int stock, int? expiresAtMs) async {
    final d = await db;
    await d.update(
      'cart_items',
      {'snapshotPrice': price, 'appliedProductDiscount': discount,
       'stockQuantity': stock, 'offerExpiresAtMs': expiresAtMs},
      where: 'productId = ?', whereArgs: [productId],
    );
  }

  Future<void> deleteCartItem(String productId) async {
    final d = await db;
    await d.delete('cart_items', where: 'productId = ?', whereArgs: [productId]);
  }

  Future<void> clearCart() async {
    final d = await db;
    await d.delete('cart_items');
  }

  //Promo

  Future<Map<String, dynamic>?> getPromo() async {
    final d = await db;
    final rows = await d.query('promo', where: 'id = 0');
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> setPromo(String code, double pct, String desc) async {
    final d = await db;
    await d.insert('promo', {'id': 0, 'code': code, 'discountPercent': pct, 'description': desc},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearPromo() async {
    final d = await db;
    await d.delete('promo', where: 'id = 0');
  }

  //Orders

  Future<void> upsertOrder(Map<String, dynamic> order) async {
    final d = await db;
    await d.insert('orders', order, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final d = await db;
    return d.query('orders', orderBy: 'createdAtMs DESC');
  }

  Future<Map<String, dynamic>?> getOrder(String id) async {
    final d = await db;
    final rows = await d.query('orders', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }
}
