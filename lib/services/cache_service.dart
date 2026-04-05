import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Stores everything as JSON strings — no TypeAdapters / codegen needed.
class CacheService {
  static const _kHome      = 'home_cache';
  static const _kDetail    = 'detail_cache';
  static const _kCategory  = 'category_cache';
  static const _kAlbumAll  = 'album_all_cache';
  static const _kAlbumOne  = 'album_one_cache';
  static const _kAlbumMine = 'album_mine_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_kHome);
    await Hive.openBox<String>(_kDetail);
    await Hive.openBox<String>(_kCategory);
    await Hive.openBox<String>(_kAlbumAll);
    await Hive.openBox<String>(_kAlbumOne);
    await Hive.openBox<String>(_kAlbumMine);
  }

  // ── Home ──────────────────────────────────────────────────────────────────

  static Future<void> saveHome(Map<String, dynamic> data) =>
      Hive.box<String>(_kHome).put('home', jsonEncode(data));

  static Map<String, dynamic>? loadHome() {
    final raw = Hive.box<String>(_kHome).get('home');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  // ── Article detail (keyed by slug) ────────────────────────────────────────

  static Future<void> saveDetail(String slug, Map<String, dynamic> data) =>
      Hive.box<String>(_kDetail).put(slug, jsonEncode(data));

  static Map<String, dynamic>? loadDetail(String slug) {
    final raw = Hive.box<String>(_kDetail).get(slug);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  // ── Category list (keyed by category name) ────────────────────────────────

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

  // ── All albums (public photo feed) ────────────────────────────────────────

  static Future<void> saveAllAlbums(List<Map<String, dynamic>> list) =>
      Hive.box<String>(_kAlbumAll).put('all', jsonEncode(list));

  static List<Map<String, dynamic>>? loadAllAlbums() {
    final raw = Hive.box<String>(_kAlbumAll).get('all');
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ── Single album (keyed by album id) ──────────────────────────────────────

  static Future<void> saveAlbum(String id, Map<String, dynamic> data) =>
      Hive.box<String>(_kAlbumOne).put(id, jsonEncode(data));

  static Map<String, dynamic>? loadAlbum(String id) {
    final raw = Hive.box<String>(_kAlbumOne).get(id);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  // ── My albums (keyed by userId) ───────────────────────────────────────────

  static Future<void> saveMyAlbums(
          String userId, List<Map<String, dynamic>> list) =>
      Hive.box<String>(_kAlbumMine).put(userId, jsonEncode(list));

  static List<Map<String, dynamic>>? loadMyAlbums(String userId) {
    final raw = Hive.box<String>(_kAlbumMine).get(userId);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ── Clear all caches ──────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await Hive.box<String>(_kHome).clear();
    await Hive.box<String>(_kDetail).clear();
    await Hive.box<String>(_kCategory).clear();
    await Hive.box<String>(_kAlbumAll).clear();
    await Hive.box<String>(_kAlbumOne).clear();
    await Hive.box<String>(_kAlbumMine).clear();
  }
}