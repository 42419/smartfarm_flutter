import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class CartItem {
  final String productId;
  final String name;
  final String spec;
  final double price;
  final String unit;
  final IconData icon;
  final Color color;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.spec,
    required this.price,
    required this.unit,
    required this.icon,
    required this.color,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;
}

class CartService {
  CartService._();

  static final CartService instance = CartService._();

  final List<CartItem> _items = [];
  final ValueNotifier<int> _countNotifier = ValueNotifier(0);

  List<CartItem> get items => List.unmodifiable(_items);
  ValueListenable<int> get countListenable => _countNotifier;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  void addItem(CartItem newItem) {
    final existing = _tryFind(newItem.productId);
    if (existing != null) {
      existing.quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
    _notify();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _notify();
  }

  void increaseQuantity(String productId) {
    final item = _tryFind(productId);
    if (item != null) {
      item.quantity++;
      _notify();
    }
  }

  void decreaseQuantity(String productId) {
    final item = _tryFind(productId);
    if (item != null) {
      item.quantity--;
      if (item.quantity <= 0) {
        _items.remove(item);
      }
      _notify();
    }
  }

  void clear() {
    _items.clear();
    _notify();
  }

  CartItem? _tryFind(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  void _notify() {
    _countNotifier.value = totalCount;
  }
}
