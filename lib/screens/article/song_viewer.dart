import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/helpers.dart';

class SongViewer extends StatelessWidget {
  final String content;
  final String title;
  const SongViewer({super.key, required this.content, required this.title});

  @override
  Widget build(BuildContext context) {
    final parsed = Helpers.parseSongHtml(content);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta row
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
                    Text(
                      'Doh is ${meta['key']}',
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (meta['reference'] != null &&
                      meta['reference']!.isNotEmpty)
                    Text(
                      meta['reference']!,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (meta['timeSignature'] != null &&
                      meta['timeSignature']!.isNotEmpty)
                    Text(
                      meta['timeSignature']!,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

          // Writer / Singer
          if (meta['writer'] != null || meta['singer'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  if (meta['writer'] != null && meta['writer']!.isNotEmpty)
                    Text(
                      'Words: ${meta['writer']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  if (meta['writer'] != null && meta['singer'] != null)
                    const SizedBox(width: 16),
                  if (meta['singer'] != null && meta['singer']!.isNotEmpty)
                    Text(
                      'Music: ${meta['singer']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),

          // Sections
          ...sections.asMap().entries.map((entry) {
            final section = entry.value;
            final type = section['type'] as String;
            final label = section['label'] as String;
            final lines = (section['lines'] as List).cast<String>();

            // Trim trailing empty lines
            final trimmed = [...lines];
            while (trimmed.isNotEmpty && trimmed.last.isEmpty)
              trimmed.removeLast();

            if (type == 'verse') {
              final numMatch = RegExp(
                r'verse\s*(\d+)',
                caseSensitive: false,
              ).firstMatch(label);
              final num = numMatch?.group(1) ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$num.',
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1a1a1a),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: trimmed
                            .map(
                              (line) => line.isEmpty
                                  ? const SizedBox(height: 8)
                                  : Text(
                                      line,
                                      style: GoogleFonts.lora(
                                        fontSize: 15,
                                        height: 1.75,
                                        color: const Color(0xFF1a1a1a),
                                      ),
                                    ),
                            )
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
                      .map(
                        (line) => line.isEmpty
                            ? const SizedBox(height: 8)
                            : Text(
                                line,
                                style: GoogleFonts.lora(
                                  fontSize: 15,
                                  height: 1.75,
                                  color: const Color(0xFF1a1a1a),
                                ),
                              ),
                      )
                      .toList(),
                ),
              );
            }

            // Intro / Outro / other
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...trimmed.map(
                    (line) => line.isEmpty
                        ? const SizedBox(height: 8)
                        : Text(
                            line,
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              height: 1.75,
                              color: const Color(0xFF1a1a1a),
                            ),
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
