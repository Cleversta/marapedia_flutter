import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Stores everything as JSON strings — no TypeAdapters / codegen needed.
class CacheService {
  static const _kHome     = 'home_cache';
  static const _kDetail   = 'detail_cache';
  static const _kCategory = 'category_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_kHome);
    await Hive.openBox<String>(_kDetail);
    await Hive.openBox<String>(_kCategory);
  }

  // ── Home ──────────────────────────────────────────────────────────────────

  static Future<void> saveHome(Map<String, dynamic> data) =>
      Hive.box<String>(_kHome).put('home', jsonEncode(data));

  static Map<String, dynamic>? loadHome() {
    final raw = Hive.box<String>(_kHome).get('home');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  // ── Article detail (keyed by slug) ───────────────────────────────────────

  static Future<void> saveDetail(String slug, Map<String, dynamic> data) =>
      Hive.box<String>(_kDetail).put(slug, jsonEncode(data));

  static Map<String, dynamic>? loadDetail(String slug) {
    final raw = Hive.box<String>(_kDetail).get(slug);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  // ── Category list (keyed by category name) ───────────────────────────────

  static Future<void> saveCategory(
      String cat, List<Map<String, dynamic>> list) =>
      Hive.box<String>(_kCategory).put(cat, jsonEncode(list));

  static List<Map<String, dynamic>>? loadCategory(String cat) {
    final raw = Hive.box<String>(_kCategory).get(cat);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ── Clear all caches (optional utility) ──────────────────────────────────

  static Future<void> clearAll() async {
    await Hive.box<String>(_kHome).clear();
    await Hive.box<String>(_kDetail).clear();
    await Hive.box<String>(_kCategory).clear();
  }
}