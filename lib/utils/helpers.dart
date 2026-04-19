import 'dart:convert';

import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'constants.dart';

class Helpers {
  static String timeAgo(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return timeago.format(date);
  }

  static String formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String makeExcerpt(String html, {int length = 150}) {
    final plain = html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return plain.length > length ? '${plain.substring(0, length)}...' : plain;
  }

  static Map<String, String>? getCategoryInfo(String value) {
    return AppConstants.categories.firstWhere(
      (c) => c['value'] == value,
      orElse: () => AppConstants.categories.last,
    );
  }

  static String? getArticleTypeLabel(String category, String? type) {
    if (type == null || type.isEmpty) return null;
    final types = AppConstants.articleTypes[category] ?? [];
    final found = types.where((t) => t['value'] == type).toList();
    return found.isNotEmpty ? found.first['label'] : null;
  }

  static Map<String, dynamic>? getPreferredTranslation(List<dynamic>? translations) {
    if (translations == null || translations.isEmpty) return null;
    for (final lang in AppConstants.languagePriority) {
      final found = translations.where((t) => t['language'] == lang).toList();
      if (found.isNotEmpty) return Map<String, dynamic>.from(found.first);
    }
    return Map<String, dynamic>.from(translations.first);
  }

  static String stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

 static Map<String, dynamic> parseSongHtml(String html) {
  final meta = <String, String>{};
  final metaMatch = RegExp(r'<!--meta:(.*?)-->').firstMatch(html);
  if (metaMatch != null) {
    try {
      final raw = metaMatch.group(1) ?? '';
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((k, v) => meta[k] = v?.toString() ?? '');
    } catch (_) {}
  }

  final sections = <Map<String, dynamic>>[];
  final divRe = RegExp(r'<div[^>]*class="song-section"[^>]*>([\s\S]*?)<\/div>');
  for (final m in divRe.allMatches(html)) {
    final tag = m.group(0) ?? '';
    final inner = m.group(1) ?? '';
    final type = RegExp(r'data-type="([^"]*)"').firstMatch(tag)?.group(1) ?? 'verse';
    final label = RegExp(r'data-label="([^"]*)"').firstMatch(tag)?.group(1) ?? 'Verse';
    final bodyHtml = inner.replaceAll(RegExp(r'<h4[^>]*>[\s\S]*?<\/h4>'), '');
    final lines = <String>[];
    final pRe = RegExp(r'<p>([\s\S]*?)<\/p>');
    for (final pm in pRe.allMatches(bodyHtml)) {
      var text = pm.group(1) ?? '';
      text = text
          .replaceAll('&nbsp;', '\u00a0')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
      lines.add(text == '\u00a0' ? '' : text);
    }
    sections.add({'type': type, 'label': label, 'lines': lines});
  }
  return {'sections': sections, 'meta': meta};
}

  // Parse poem HTML to plain text
  static String parsePoemHtml(String html) {
    if (html.isEmpty || html == '<p></p>') return '';
    return html
      .replaceAll(RegExp(r'<br\s*\/?>'), '\n')
      .replaceAll(RegExp(r'<\/p>\s*<p>'), '\n\n')
      .replaceAll('<p>', '')
      .replaceAll('</p>', '')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
  }
}
