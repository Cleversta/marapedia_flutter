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
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../utils/helpers.dart';

String? extractYouTubeId(String url) {
  final patterns = [
    RegExp(r'youtube\.com/watch\?(?:.*&)?v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(url);
    if (m != null) return m.group(1);
  }
  return null;
}

class SongViewer extends StatefulWidget {
  final String content;
  final String title;
  final String? sourceUrl;
  final String? youtubeUrl; // ← NEW: passed directly from DB

  const SongViewer({
    super.key,
    required this.content,
    required this.title,
    this.sourceUrl,
    this.youtubeUrl, // ← NEW
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

  YoutubePlayerController? _ytController;
  String? _videoId;
  String? _resolvedYoutubeUrl; // the final URL we use (prop > meta)

  @override
  void initState() {
    super.initState();
    _initYtPlayer();
  }

  void _initYtPlayer() {
    // 1. Try the direct prop first (from DB column)
    // 2. Fallback to the HTML meta comment
    final parsed = Helpers.parseSongHtml(widget.content);
    final meta = parsed['meta'] as Map<String, String>;
    final urlFromMeta = meta['youtubeUrl'] ?? '';

    _resolvedYoutubeUrl = (widget.youtubeUrl != null && widget.youtubeUrl!.isNotEmpty)
        ? widget.youtubeUrl!
        : urlFromMeta;

    _videoId = _resolvedYoutubeUrl!.isNotEmpty
        ? extractYouTubeId(_resolvedYoutubeUrl!)
        : null;

    if (_videoId != null && _videoId!.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
          forceHD: false,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(SongViewer old) {
    super.didUpdateWidget(old);
    if (widget.content != old.content ||
        widget.youtubeUrl != old.youtubeUrl) {
      _ytController?.dispose();
      _ytController = null;
      _videoId = null;
      _resolvedYoutubeUrl = null;
      _initYtPlayer();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

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
    } else if (androidVersion >= 29) {
      status = PermissionStatus.granted; // Android 10–12: no runtime permission needed
    } else {
      status = await Permission.storage.request(); // Android 9 and below
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
                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
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
        child: Icon(icon,
            size: 15,
            color: enabled ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
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

    if (_ytController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _ytController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFFEF4444),
          progressColors: const ProgressBarColors(
            playedColor: Color(0xFFEF4444),
            handleColor: Color(0xFFEF4444),
          ),
        ),
        builder: (context, player) {
          return _buildContent(context, sections, meta, player);
        },
      );
    }

    return _buildContent(context, sections, meta, null);
  }

  Widget _buildContent(
    BuildContext context,
    List<Map<String, dynamic>> sections,
    Map<String, String> meta,
    Widget? player,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── YouTube player ─────────────────────────────────────────────────
        if (player != null) ...[
          _buildYouTubePlayer(player),
          const SizedBox(height: 16),
        ],

        // ── Toolbar row ────────────────────────────────────────────────────
        Row(
          children: [
            _buildFontSizeControl(),
            const Spacer(),
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
                              fontWeight: FontWeight.w500),
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
                      color: const Color(0xFF1C1917)),
                ),
                const SizedBox(height: 4),

                if (meta['songNumber'] != null && meta['songNumber']!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '#${meta['songNumber']}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                    ),
                  ),

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
                    final numMatch = RegExp(r'verse\s*(\d+)', caseSensitive: false)
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
                        fontSize: 10, color: Color(0xFFD1D5DB), letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubePlayer(Widget player) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5)),
        color: Colors.black,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: Colors.black87,
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    size: 15, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                const Text(
                  'Watch on YouTube',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 0.3),
                ),
                const Spacer(),
                if (_resolvedYoutubeUrl != null && _resolvedYoutubeUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(_resolvedYoutubeUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Open app',
                            style: TextStyle(fontSize: 11, color: Colors.white38)),
                        SizedBox(width: 3),
                        Icon(Icons.open_in_new, size: 12, color: Colors.white38),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          player,
        ],
      ),
    );
  }
}