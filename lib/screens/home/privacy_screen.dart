import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marapedia_flutter/screens/home/marapedia_footer.dart';
import '../../widgets/marapedia_app_bar.dart';

const _ink = Color(0xFF1C1812);
const _inkMid = Color(0xFF4A4035);
const _inkLight = Color(0xFF8C7E6A);
const _sage = Color(0xFF5A7A5C);
const _sageBg = Color(0xFFEBF1EB);
const _sageLight = Color(0xFFD4E4D4);
const _border = Color(0xFFE5E7EB);
const _parchment = Color(0xFFFAF9F7);

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parchment,
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
                  _section(
                    '1. Information We Collect',
                    Icons.info_outline,
                    [
                      _para(
                        'When you register for an account, we collect your username, email address, and optionally your full name and profile photo.',
                      ),
                      _para(
                        'When you contribute articles or translations, we store the content you submit along with your user ID and the timestamps of your contributions.',
                      ),
                      _para(
                        'We automatically collect basic usage data such as which articles are viewed, to maintain view counts. We do not track individual users across sessions.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _section(
                    '2. How We Use Your Information',
                    Icons.settings_outlined,
                    [
                      _para('We use your information to:'),
                      _bulletList([
                        'Create and manage your Marapedia account.',
                        'Display your username alongside articles and contributions you have made.',
                        'Allow editors and administrators to review and manage content.',
                        'Send important account-related emails such as password resets.',
                        'Improve the encyclopedia and understand how content is being used.',
                      ]),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _section(
                    '3. Information We Do Not Collect',
                    Icons.block_outlined,
                    [
                      _para(
                        'Marapedia does not collect payment information, precise location data, or device identifiers beyond what is necessary to serve the application.',
                      ),
                      _para(
                        'We do not serve advertisements and do not share your data with advertisers.',
                      ),
                      _para(
                        'We do not sell, rent, or trade your personal information to any third party.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _section(
                    '4. Data Storage & Security',
                    Icons.lock_outline,
                    [
                      _para(
                        'Your data is stored securely using Supabase, a trusted backend platform. All data is encrypted in transit using HTTPS.',
                      ),
                      _para(
                        'Passwords are never stored in plain text. We use industry-standard authentication practices.',
                      ),
                      _para(
                        'While we take reasonable measures to protect your information, no system is completely secure. We encourage you to use a strong, unique password for your account.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _section(
                    '5. Public Content',
                    Icons.public_outlined,
                    [
                      _para(
                        'All articles, translations, and contributions you publish on Marapedia are public. Your username will be displayed alongside your contributions.',
                      ),
                      _para(
                        'Content you contribute may be edited, improved, or moderated by other community members and administrators in accordance with our content guidelines.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _section(
                    '6. Your Rights',
                    Icons.person_outline,
                    [
                      _para('You have the right to:'),
                      _bulletList([
                        'Access the personal information we hold about you.',
                        'Request correction of inaccurate information.',
                        'Request deletion of your account and associated personal data.',
                        'Withdraw consent for optional data uses at any time.',
                      ]),
                      _para(
                        'To exercise any of these rights, contact us at contact@marapedia.org.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _section(
                    '7. Cookies',
                    Icons.cookie_outlined,
                    [
                      _para(
                        'Marapedia uses only essential cookies required for authentication and session management. We do not use tracking or advertising cookies.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _section(
                    '8. Children\'s Privacy',
                    Icons.child_care_outlined,
                    [
                      _para(
                        'Marapedia is not directed at children under the age of 13. We do not knowingly collect personal information from children. If you believe a child has provided us with personal information, please contact us so we can delete it.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _section(
                    '9. Changes to This Policy',
                    Icons.edit_note_outlined,
                    [
                      _para(
                        'We may update this privacy policy from time to time. When we do, we will update the effective date at the top of this page. Continued use of Marapedia after changes constitutes acceptance of the updated policy.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _contactBox(),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: _sageLight),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.6),
            ),
            child: const Text(
              'LAST UPDATED: APRIL 2026',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _sage,
                letterSpacing: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.lora(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF052E16),
                height: 1.2,
              ),
              children: [
                const TextSpan(text: 'Privacy '),
                TextSpan(
                  text: 'Policy',
                  style: GoogleFonts.lora(color: _sage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We respect your privacy and are committed to\nprotecting your personal information.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _inkMid, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _sageBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _sageLight),
              ),
              child: Icon(icon, size: 18, color: _sage),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _para(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: _inkMid,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _bulletList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        color: _sage,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _inkMid,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _contactBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _sageBg,
        border: Border.all(color: _sageLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline, color: _sage, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions about this policy?',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Contact us at contact@marapedia.org and we will be happy to help.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _inkLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}