import '../entities/cart_entry.dart';
import '../entities/menu_item.dart';
import 'package:flutter/foundation.dart';

class CartService extends ChangeNotifier {
  final Map<String, CartEntry> _items = {};

  List<CartEntry> get items => _items.values.toList();
  int get totalCount =>
      _items.values.fold<int>(0, (sum, entry) => sum + entry.quantity);
  double get total =>
      _items.values.fold<double>(0, (sum, entry) => sum + entry.item.price * entry.quantity);

  void addItem(MenuItem item) {
    final existing = _items[item.id];
    final nextQty = (existing?.quantity ?? 0) + 1;
    _items[item.id] = CartEntry(item: item, quantity: nextQty);
    notifyListeners();
  }

  void decrement(MenuItem item) {
    final existing = _items[item.id];
    if (existing == null) return;
    final nextQty = existing.quantity - 1;
    if (nextQty <= 0) {
      _items.remove(item.id);
    } else {
      _items[item.id] = CartEntry(item: item, quantity: nextQty);
    }
    notifyListeners();
  }

  void removeItem(MenuItem item) {
    final removed = _items.remove(item.id);
    if (removed != null) {
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
