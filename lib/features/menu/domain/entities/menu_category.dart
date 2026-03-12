import 'menu_item.dart';

class MenuCategory {
  final String id;
  final String title;
  final List<MenuItem> items;

  const MenuCategory({
    required this.id,
    required this.title,
    required this.items,
  });

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? const [];
    return MenuCategory(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(MenuItem.fromMap)
          .toList(),
    );
  }
}
