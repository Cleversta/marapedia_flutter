import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marapedia_flutter/screens/home/marapedia_footer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/marapedia_app_bar.dart';

const _ink = Color(0xFF1C1812);
const _inkMid = Color(0xFF4A4035);
const _inkLight = Color(0xFF8C7E6A);
const _sage = Color(0xFF5A7A5C);
const _sageBg = Color(0xFFEBF1EB);
const _sageLight = Color(0xFFD4E4D4);
const _border = Color(0xFFE5E7EB);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: const MarapediaAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildWhatIs(),
                  const SizedBox(height: 32),
                  _buildMission(),
                  const SizedBox(height: 32),
                  _buildHowItWorks(context),
                  const SizedBox(height: 32),
                  _buildHowToContribute(context),
                  const SizedBox(height: 32),
                  _buildContentGuidelines(),
                  const SizedBox(height: 32),
                  _buildContact(),
                  const SizedBox(height: 32),
                  _buildCTA(context),
                  const SizedBox(height: 32),
                  _buildFounder(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            const MarapediaFooter(),
          ],
        ),
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECFDF5), Color(0xFFFEF9EE)],
        ),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        children: [
          const Text(
            'SINCE 2026',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _sage,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.lora(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF052E16),
                height: 1.2,
              ),
              children: [
                const TextSpan(text: 'About Mara'),
                TextSpan(
                  text: 'pedia',
                  style: GoogleFonts.lora(color: _sage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A free, community-built encyclopedia dedicated to\npreserving and sharing the rich heritage of the Mara people.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _inkMid, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── What Is ─────────────────────────────────────────────────────────────────

  Widget _buildWhatIs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('📖', 'What is Marapedia?'),
        const SizedBox(height: 12),
        const Text(
          'Marapedia is a free, open encyclopedia built by and for the Mara community. Like Wikipedia, it is written collaboratively by volunteers who care about preserving knowledge — but Marapedia focuses specifically on the Mara people: their history, culture, language, songs, poems, famous figures, villages, and traditions.',
          style: TextStyle(fontSize: 13, color: _inkMid, height: 1.7),
        ),
        const SizedBox(height: 10),
        const Text(
          'The Mara people have a rich and unique heritage that deserves to be documented, celebrated, and passed on to future generations. Marapedia exists to make that possible — in our own languages, on our own terms.',
          style: TextStyle(fontSize: 13, color: _inkMid, height: 1.7),
        ),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 13, color: _inkMid, height: 1.7),
            children: [
              TextSpan(
                  text:
                      'All content on Marapedia is available in four languages: '),
              TextSpan(
                text: 'Mara, English, Myanmar, and Mizo',
                style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
              ),
              TextSpan(
                  text:
                      ' — so our community can read and contribute in the language they are most comfortable with.'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mission ─────────────────────────────────────────────────────────────────

  Widget _buildMission() {
    final items = [
      {
        'icon': '🏛️',
        'title': 'Preserve',
        'desc':
            'Document Mara history, culture, and traditions before they are lost to time.'
      },
      {
        'icon': '🌍',
        'title': 'Share',
        'desc':
            'Make Mara knowledge accessible to the whole community, wherever they are in the world.'
      },
      {
        'icon': '🤝',
        'title': 'Connect',
        'desc':
            'Build a living archive that connects Mara people across generations and geographies.'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _sageBg,
        border: Border.all(color: _sageLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🌿', 'Our Mission', color: const Color(0xFF14532D)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Text(item['icon']!,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text(
                              item['title']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF14532D),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['desc']!,
                              style: const TextStyle(
                                  fontSize: 11, color: _sage, height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── How It Works ─────────────────────────────────────────────────────────────

  Widget _buildHowItWorks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('⚙️', 'How It Works'),
        const SizedBox(height: 8),
        const Text(
          'Marapedia works just like Wikipedia — anyone can read, and registered members can write and edit. Here is a simple overview of how everything works.',
          style: TextStyle(fontSize: 13, color: _inkMid, height: 1.7),
        ),
        const SizedBox(height: 20),

        // Reading
        _howItWorksCard(
          icon: '👁️',
          color: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
          iconColor: const Color(0xFF3B82F6),
          title: 'Reading Articles',
          points: [
            'No account is needed to read any article on Marapedia.',
            'All articles are freely accessible to anyone in the world.',
            'You can browse by category — History, Songs, Poems, People, Places, Culture, and more.',
            'Use the search bar to find any topic quickly.',
            'Switch between Mara, English, Myanmar, and Mizo languages on any article.',
          ],
        ),
        const SizedBox(height: 12),

        // Contributing
        _howItWorksCard(
          icon: '✍️',
          color: _sageBg,
          borderColor: _sageLight,
          iconColor: _sage,
          title: 'Writing & Contributing',
          points: [
            'Create a free account to start contributing.',
            'Write new articles using our simple editor — no technical skills needed.',
            'Choose the category and language for your article.',
            'Add a title, content, images, and a source link if available.',
            'Submit your article for review. Once approved by an editor, it goes live for everyone to read.',
          ],
        ),
        const SizedBox(height: 12),

        // Languages
        _howItWorksCard(
          icon: '🌐',
          color: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
          iconColor: const Color(0xFFD97706),
          title: 'Multilingual Support',
          points: [
            'Every article can have translations in Mara, English, Myanmar, and Mizo.',
            'If an article exists in one language, you can add a translation in another.',
            'Readers can switch languages on any article with a single tap.',
            'This ensures the Mara community anywhere in the world can read in their preferred language.',
          ],
        ),
        const SizedBox(height: 12),

        // Review
        _howItWorksCard(
          icon: '✅',
          color: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          iconColor: const Color(0xFF16A34A),
          title: 'Review & Quality',
          points: [
            'All new articles go through a review process before being published.',
            'Editors check that content is accurate, respectful, and relevant to the Mara community.',
            'Once approved, articles are published and visible to all readers.',
            'Existing articles can be improved and updated by the community at any time.',
            'Admins and editors can remove content that does not meet our guidelines.',
          ],
        ),
        const SizedBox(height: 12),

        // Songs & Poems
        _howItWorksCard(
          icon: '🎵',
          color: const Color(0xFFFDF4FF),
          borderColor: const Color(0xFFE9D5FF),
          iconColor: const Color(0xFF9333EA),
          title: 'Songs, Poems & Special Content',
          points: [
            'Marapedia has dedicated formats for songs and poems.',
            'Song lyrics are displayed in a special viewer with verse-by-verse formatting.',
            'You can record the singer, songwriter, and song type (Worship, Hymn, Love Song, etc.).',
            'Poems are displayed with elegant typography suited for reading.',
            'This makes Marapedia a living archive of Mara oral tradition.',
          ],
        ),
      ],
    );
  }

  Widget _howItWorksCard({
    required String icon,
    required Color color,
    required Color borderColor,
    required Color iconColor,
    required String title,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _inkMid,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  // ── Content Guidelines ───────────────────────────────────────────────────────

  Widget _buildContentGuidelines() {
    final guidelines = [
      'Articles should be factual and respectful of the Mara community.',
      'Content should be relevant to Mara history, culture, people, places, language, or traditions.',
      'Do not copy content from other sources without permission.',
      'All contributors are responsible for the accuracy of what they write.',
      'Editors and admins may edit or remove content that does not meet our guidelines.',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📋', 'Content Guidelines',
              color: const Color(0xFF78350F)),
          const SizedBox(height: 14),
          ...guidelines.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFBBF24),
                            height: 1.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                            height: 1.6),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Contact ──────────────────────────────────────────────────────────────────

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('📬', 'Contact Us'),
        const SizedBox(height: 8),
        const Text(
          "Have questions, suggestions, or want to report an issue? We'd love to hear from you.",
          style: TextStyle(fontSize: 13, color: _inkMid, height: 1.7),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('mailto:contact@marapedia.org')),
          child: _contactCard(
            icon: '📧',
            iconBg: _sageBg,
            title: 'Email',
            subtitle: 'contact@marapedia.org',
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://facebook.com/Marapedia')),
          child: _contactCard(
            icon: '📘',
            iconBg: const Color(0xFFEFF6FF),
            title: 'Facebook',
            subtitle: 'facebook.com/Marapedia',
          ),
        ),
      ],
    );
  }

  Widget _contactCard({
    required String icon,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: _inkLight)),
            ],
          ),
        ],
      ),
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