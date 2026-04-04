import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _ink = Color(0xFF1C1812);
const _inkLight = Color(0xFF8C7E6A);
const _sage = Color(0xFF5A7A5C);
const _border = Color(0xFFE5E7EB);

const _footerLinks = {
  'Marapedia': [
    {'label': 'About Marapedia', 'href': '/about'},
    {'label': 'How to Contribute', 'href': '/about'},
    {'label': 'Contact Us', 'href': '/about'},
    {'label': 'Privacy Policy', 'href': '/privacy'},
  ],
  'Browse': [
    {'label': 'History', 'href': '/category/history'},
    {'label': 'Songs & Lyrics', 'href': '/category/songs'},
    {'label': 'Poems', 'href': '/category/poems'},
    {'label': 'Famous People', 'href': '/category/people'},
    {'label': 'Villages & Places', 'href': '/category/places'},
    {'label': 'Culture', 'href': '/category/culture'},
  ],
  'Contribute': [
    {'label': 'Write an Article', 'href': '/articles/create'},
    {'label': 'Register', 'href': '/register'},
    {'label': 'Sign In', 'href': '/login'},
  ],
};

class MarapediaFooter extends StatelessWidget {
  const MarapediaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrand(),
          const SizedBox(height: 24),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 20),
          ..._footerLinks.entries.map(
            (entry) => _buildLinkSection(context, entry.key, entry.value),
          ),
          const SizedBox(height: 8),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 14),
          _buildBottomBar(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
            children: const [
              TextSpan(text: 'Mara'),
              TextSpan(text: 'pedia', style: TextStyle(color: _sage)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'A free, community-built encyclopedia preserving the history,\nculture, language, and traditions of the Mara people.',
          style: TextStyle(fontSize: 12, color: _inkLight, height: 1.6),
        ),
        const SizedBox(height: 12),
        const Text(
          'Available in:',
          style: TextStyle(fontSize: 11, color: _inkLight),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: ['Mara', 'English', 'Myanmar', 'Mizo']
              .map((lang) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lang,
                      style: const TextStyle(
                          fontSize: 11, color: _inkLight),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLinkSection(
    BuildContext context,
    String title,
    List<Map<String, String>> links,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _inkLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...links.map(
            (link) => GestureDetector(
              onTap: () => context.push(link['href']!),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  link['label']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final year = DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '© $year Marapedia — The Free Mara Encyclopedia',
          style: const TextStyle(fontSize: 11, color: _inkLight),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            {'label': 'About', 'href': '/about'},
            {'label': 'Privacy', 'href': '/privacy'},
            {'label': 'Contact', 'href': '/about'},
          ]
              .map((item) => GestureDetector(
                    onTap: () => context.push(item['href']!),
                    child: Text(
                      item['label']!,
                      style: const TextStyle(
                          fontSize: 11, color: _inkLight),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Content available under community license',
          style: TextStyle(fontSize: 10, color: Color(0xFFD1C9BC)),
        ),
      ],
    );
  }
}