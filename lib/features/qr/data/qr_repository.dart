import 'dart:convert';

import '../domain/saved_qr.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrRepository {
  static const _key = 'saved_qr_entries';

  Future<List<SavedQr>> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final parsed = <SavedQr>[];
    try {
      final list = json.decode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          try {
            parsed.add(SavedQr.fromMap(item));
          } catch (_) {
          
          }
        }
      }
    } catch (_) {
      return [];
    }
    parsed.sort((a, b) => b.created.compareTo(a.created));
    return parsed;
  }

  Future<void> save(SavedQr entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchAll();
    final updated = [entry, ...existing];
    final encoded =
        json.encode(updated.map((e) => e.toMap()).toList(growable: false));
    await prefs.setString(_key, encoded);
  }
}
