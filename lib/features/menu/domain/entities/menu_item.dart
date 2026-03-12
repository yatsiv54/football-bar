class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imagePath: map['imagePath'] as String? ?? '',
    );
  }
}
