import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:marapedia_flutter/utils/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/helpers.dart';

class SongViewer extends StatefulWidget {
  final String content;
  final String title;
  final String? sourceUrl;
  const SongViewer({
    super.key,
    required this.content,
    required this.title,
    this.sourceUrl,
  });

  @override
  State<SongViewer> createState() => _SongViewerState();
}

class _SongViewerState extends State<SongViewer> {
  final GlobalKey _captureKey = GlobalKey();
  bool _saving = false;
  double _fontSize = 15;
  static const double _min = 11;
  static const double _max = 22;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _saveAsImage() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      PermissionStatus status;
      if (androidVersion >= 33) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: widget.title.replaceAll(' ', '_').toLowerCase(),
        quality: 100,
      );

      if (mounted) {
        final success = result['isSuccess'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Saved to gallery!' : 'Failed to save image'),
            backgroundColor: success ? Colors.green[700] : Colors.red[400],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Widget _buildFontSizeControl() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sizeBtn(
          icon: Icons.text_decrease,
          onTap: _fontSize > _min
              ? () => setState(() => _fontSize = (_fontSize - 1).clamp(_min, _max))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '${_fontSize.toInt()}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        _sizeBtn(
          icon: Icons.text_increase,
          onTap: _fontSize < _max
              ? () => setState(() => _fontSize = (_fontSize + 1).clamp(_min, _max))
              : null,
        ),
      ],
    );
  }

  Widget _sizeBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = Helpers.parseSongHtml(widget.content);
    final sections = parsed['sections'] as List<Map<String, dynamic>>;
    final meta = parsed['meta'] as Map<String, String>;

    if (sections.isEmpty) {
      return const Center(
        child: Text(
          'No lyrics available.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toolbar row ────────────────────────────────────────────────────
        Row(
          children: [
            _buildFontSizeControl(),
            const Spacer(),
            // Source URL badge
            if (widget.sourceUrl != null && widget.sourceUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _launchUrl(widget.sourceUrl!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, size: 13, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          widget.sourceUrl!
                              .replaceAll(RegExp(r'^https?://'), '')
                              .replaceAll(RegExp(r'/$'), ''),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new, size: 11, color: Color(0xFF93C5FD)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Save as image button
            TextButton.icon(
              onPressed: _saving ? null : _saveAsImage,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 16),
              label: Text(_saving ? 'Saving...' : 'Save as Image'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.greenPrimary,
                backgroundColor: const Color(0xFFD1FAE5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Lyrics body ────────────────────────────────────────────────────
        RepaintBoundary(
          key: _captureKey,
          child: Container(
            color: const Color(0xFFFFFEF9),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 4),

                if (meta['key'] != null ||
                    meta['reference'] != null ||
                    meta['timeSignature'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (meta['key'] != null && meta['key']!.isNotEmpty)
                          Text('Doh is ${meta['key']}',
                              style: GoogleFonts.lora(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600])),
                        if (meta['reference'] != null && meta['reference']!.isNotEmpty)
                          Text(meta['reference']!,
                              style: GoogleFonts.lora(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600])),
                        if (meta['timeSignature'] != null && meta['timeSignature']!.isNotEmpty)
                          Text(meta['timeSignature']!,
                              style: GoogleFonts.lora(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600])),
                      ],
                    ),
                  ),

                if (meta['writer'] != null || meta['singer'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        if (meta['writer'] != null && meta['writer']!.isNotEmpty)
                          Text('Words: ${meta['writer']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        if (meta['writer'] != null && meta['singer'] != null)
                          const SizedBox(width: 16),
                        if (meta['singer'] != null && meta['singer']!.isNotEmpty)
                          Text('Music: ${meta['singer']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),

                ...sections.asMap().entries.map((entry) {
                  final section = entry.value;
                  final type = section['type'] as String;
                  final label = section['label'] as String;
                  final lines = (section['lines'] as List).cast<String>();
                  final trimmed = [...lines];
                  while (trimmed.isNotEmpty && trimmed.last.isEmpty) {
                    trimmed.removeLast();
                  }

                  if (type == 'verse') {
                    final numMatch =
                        RegExp(r'verse\s*(\d+)', caseSensitive: false)
                            .firstMatch(label);
                    final num = numMatch?.group(1) ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text('$num.',
                                style: GoogleFonts.lora(
                                    fontSize: _fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1a1a1a))),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: trimmed
                                  .map((line) => line.isEmpty
                                      ? const SizedBox(height: 8)
                                      : Text(line,
                                          style: GoogleFonts.lora(
                                              fontSize: _fontSize,
                                              height: 1.75,
                                              color: const Color(0xFF1a1a1a))))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (type == 'chorus' || type == 'bridge') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20, left: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: trimmed
                            .map((line) => line.isEmpty
                                ? const SizedBox(height: 8)
                                : Text(line,
                                    style: GoogleFonts.lora(
                                        fontSize: _fontSize,
                                        height: 1.75,
                                        color: const Color(0xFF1a1a1a))))
                            .toList(),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ...trimmed.map((line) => line.isEmpty
                            ? const SizedBox(height: 8)
                            : Text(line,
                                style: GoogleFonts.lora(
                                    fontSize: _fontSize,
                                    height: 1.75,
                                    color: const Color(0xFF1a1a1a)))),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'marapedia.org',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFD1D5DB),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}