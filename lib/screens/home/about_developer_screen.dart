import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/marapedia_app_bar.dart';

const _ink = Color(0xFF1C1812);
const _inkMid = Color(0xFF4A4035);
const _inkLight = Color(0xFF8C7E6A);
const _sage = Color(0xFF5A7A5C);
const _sageBg = Color(0xFFEBF1EB);
const _sageLight = Color(0xFFD4E4D4);
const _border = Color(0xFFE5E7EB);

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: const MarapediaAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: _buildFounder(context),
        ),
      ),
    );
  }

  // ── Founder ──────────────────────────────────────────────────────────────────

  Widget _buildFounder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('👤', 'About the Founder'),
          const SizedBox(height: 16),

          Text(
            'Marason Tleitu',
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Founder & Developer of Marapedia',
            style: TextStyle(
              fontSize: 12,
              color: _sage,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: _border),
          const SizedBox(height: 16),

          _sectionTitle('👋', 'Introduction'),
          const SizedBox(height: 10),
          const Text(
            'My name is Marason Tleitu. I\'m 25 years old, from the Mara community, '
            'currently based in Malaysia. I\'m a self-taught developer, building apps '
            'and websites for the Mara people in whatever time I can find outside my '
            'day-to-day life abroad.',
            style: TextStyle(fontSize: 13, color: _inkMid, height: 1.75),
          ),
          const SizedBox(height: 10),
          const Text(
            'Being away from home made me think more, not less, about where I come '
            'from. In 2023, I wrote Mara Hlabu, a book collecting Mara song lyrics, '
            'and later turned it into a mobile app so anyone could carry the songs '
            'with them and read the lyrics on the go.',
            style: TextStyle(fontSize: 13, color: _inkMid, height: 1.75),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(
                'https://play.google.com/store/apps/details?id=com.marahlabu.marahlaapp&pcampaignid=web_share')),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📱', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'Mara Hlabu on Google Play',
                  style: TextStyle(
                    fontSize: 13,
                    color: _sage,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new, size: 12, color: _sage),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Marapedia grew out of that same motivation: Mara Hlabu preserved the '
            'songs, and Marapedia expands that mission to history, language, stories, '
            'and culture — making sure it all has a home online that anyone, anywhere, '
            'can reach.',
            style: TextStyle(fontSize: 13, color: _inkMid, height: 1.75),
          ),

          const SizedBox(height: 16),
          const Divider(color: _border),
          const SizedBox(height: 16),

          _founderPara(
            '💡',
            'The Idea',
            'Marapedia began with a simple but powerful idea — to gather everything about the Mara people in one place and make it freely accessible to the world. Looking around, Marason noticed something missing: while the world was moving fast with technology and information, the Mara people did not yet have a dedicated digital space to call their own.',
          ),
          const SizedBox(height: 14),
          _founderPara(
            '🤝',
            'Why Community?',
            'Preserving an entire people\'s heritage is far too great a task for one person to carry alone. No single individual could document all the songs, histories, poems, stories, and traditions of the Mara people. So Marapedia was built in the spirit of Wikipedia — a community-driven encyclopedia where every Mara person, wherever they are in the world, can contribute, edit, and grow the knowledge together.',
          ),
          const SizedBox(height: 14),
          _founderPara(
            '🎵',
            'What We Are Preserving',
            'The Mara people have a rich and unique culture — beautiful songs and hymns, poetry, histories of villages and clans, stories of leaders and community figures, and traditions that define who we are. Much of this exists only in the memories of our elders. Marapedia exists to capture all of it before it fades and give it a permanent home.',
          ),
          const SizedBox(height: 14),
          _founderPara(
            '🌍',
            'Open to the World',
            'Marapedia is written in four languages — Mara, English, Myanmar, and Mizo — so that not only our own community but the wider world can discover and appreciate who the Mara people are. This openness is intentional. The Mara people have a story worth telling, and the world deserves to hear it.',
          ),
          const SizedBox(height: 14),
          _founderPara(
            '🌱',
            'Building for the Future',
            'The deepest motivation behind Marapedia is the future. If we do not preserve our heritage in the digital world today, the next generation may never find it. Marapedia is being built so that tomorrow, a young Mara child anywhere in the world can open this encyclopedia and discover exactly who they are and where they come from.',
          ),

          const SizedBox(height: 20),

          // Quote
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _sageBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sageLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❝',
                    style: TextStyle(fontSize: 28, color: _sage, height: 1)),
                const SizedBox(height: 6),
                const Text(
                  'Technology is moving fast. The Mara people deserve to be part of that world too — with our own history, our own songs, and our own voice preserved for every generation to come.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _sage,
                    fontStyle: FontStyle.italic,
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '— Marason Tleitu, Founder of Marapedia',
                  style: TextStyle(
                    fontSize: 11,
                    color: _inkLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: _border),
          const SizedBox(height: 16),

          Text(
            'Get in Touch',
            style: GoogleFonts.lora(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () =>
                launchUrl(Uri.parse('mailto:marasontleitu@gmail.com')),
            child: _contactRow(
                Icons.email_outlined, 'marasontleitu@gmail.com'),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('tel:0182159223')),
            child: _contactRow(Icons.phone_outlined, '0182159223'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _founderPara(String emoji, String heading, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              heading,
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13,
            color: _inkMid,
            height: 1.75,
          ),
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _sage),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: _inkMid,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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