import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/marapedia_app_bar.dart';

const _ink = Color(0xFF1C1812);
const _inkMid = Color(0xFF4A4035);
const _inkLight = Color(0xFF8C7E6A);
const _sage = Color(0xFF5A7A5C);
const _border = Color(0xFFE5E7EB);

class HowToContributeScreen extends StatelessWidget {
  const HowToContributeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: const MarapediaAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHowToContribute(context),
              _buildCTA(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── How To Contribute ────────────────────────────────────────────────────────

  Widget _buildHowToContribute(BuildContext context) {
    final steps = [
      {
        'step': '1',
        'title': 'Create an account',
        'desc': 'Register for a free account to start contributing.',
        'href': '/register',
        'cta': 'Register now'
      },
      {
        'step': '2',
        'title': 'Write an article',
        'desc':
            'Use our editor to write about any topic related to the Mara people. You can write in any of our four supported languages.',
        'href': '/articles/create',
        'cta': 'Start writing'
      },
      {
        'step': '3',
        'title': 'Get reviewed',
        'desc':
            'New articles are reviewed by our editors before publishing to ensure quality and accuracy.'
      },
      {
        'step': '4',
        'title': 'Keep it growing',
        'desc':
            'Edit and improve existing articles, add translations, and help build the encyclopedia together.'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('✍️', 'How to Contribute'),
        const SizedBox(height: 8),
        const Text(
          'Marapedia is built by the community, for the community. Anyone can contribute — you do not need to be an expert.',
          style: TextStyle(fontSize: 13, color: _inkMid, height: 1.7),
        ),
        const SizedBox(height: 20),
        ...steps.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _sage,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item['step']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['desc']!,
                          style: const TextStyle(
                              fontSize: 12, color: _inkLight, height: 1.6),
                        ),
                        if (item.containsKey('href')) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => context.push(item['href']!),
                            child: Text(
                              '${item['cta']} →',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _sage,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── CTA ──────────────────────────────────────────────────────────────────────

  Widget _buildCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        children: [
          Text(
            'Ready to contribute?',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Join the community and help preserve Mara heritage\nfor future generations.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _inkLight, height: 1.6),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.push('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sage,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Create Account',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _inkMid,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Browse Articles',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String emoji, String title, {Color color = _ink}) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
