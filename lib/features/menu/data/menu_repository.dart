import 'dart:convert';

import '../domain/entities/menu_category.dart';
import 'package:flutter/services.dart';

abstract class MenuRepository {
  Future<List<MenuCategory>> fetchMenu();
}

class AssetsMenuRepository implements MenuRepository {
  AssetsMenuRepository({
    this.assetPath = 'assets/data/menu_items.json',
    AssetBundle? bundle,
  }) : _bundle = bundle;

  final String assetPath;
  final AssetBundle? _bundle;

  @override
  Future<List<MenuCategory>> fetchMenu() async {
    final bundle = _bundle ?? rootBundle;
    final raw = await bundle.loadString(assetPath);
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) return const [];

    final categories = decoded['categories'] as List<dynamic>? ?? const [];
    return categories
        .whereType<Map<String, dynamic>>()
        .map(MenuCategory.fromMap)
        .toList();
  }
}
