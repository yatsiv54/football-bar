import 'menu_item.dart';

class CartEntry {
  final MenuItem item;
  final int quantity;

  const CartEntry({required this.item, required this.quantity});

  CartEntry copyWith({MenuItem? item, int? quantity}) {
    return CartEntry(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}
