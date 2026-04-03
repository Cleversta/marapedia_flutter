import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/helpers.dart';

class PoemViewer extends StatefulWidget {
  final String content;
  final String? sourceUrl;
  const PoemViewer({super.key, required this.content, this.sourceUrl});

  @override
  State<PoemViewer> createState() => _PoemViewerState();
}

class _PoemViewerState extends State<PoemViewer> {
  double _fontSize = 17;
  static const double _min = 13;
  static const double _max = 24;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final text = Helpers.parsePoemHtml(widget.content);
    if (text.trim().isEmpty) {
      return const Center(
        child: Text(
          'No content available.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    final stanzas = text.split(RegExp(r'\n\n+'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toolbar row ────────────────────────────────────────────────────
        Row(
          children: [
            _buildFontSizeControl(),
            const Spacer(),
            if (widget.sourceUrl != null && widget.sourceUrl!.isNotEmpty)
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
                        constraints: const BoxConstraints(maxWidth: 140),
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
          ],
        ),
        const SizedBox(height: 10),

        // ── Poem body ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDFCF9), Color(0xFFFDF8F5)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCE7F3).withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stanzas.asMap().entries.map((entry) {
              final stanza = entry.value.trim();
              if (stanza.isEmpty) return const SizedBox.shrink();
              final lines = stanza.split('\n');
              return Padding(
                padding: EdgeInsets.only(
                    bottom: entry.key < stanzas.length - 1 ? 20 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines
                      .map((line) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              line,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: _fontSize,
                                height: 1.9,
                                color: const Color(0xFF1a1a1a),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}