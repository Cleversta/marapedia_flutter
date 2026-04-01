import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/helpers.dart';

class PoemViewer extends StatelessWidget {
  final String content;
  const PoemViewer({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final text = Helpers.parsePoemHtml(content);
    if (text.trim().isEmpty) {
      return const Center(child: Text('No content available.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));
    }

    final stanzas = text.split(RegExp(r'\n\n+'));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
            padding: EdgeInsets.only(bottom: entry.key < stanzas.length - 1 ? 20 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(line, style: GoogleFonts.playfairDisplay(fontSize: 17, height: 1.9, color: const Color(0xFF1a1a1a))),
              )).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
