import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marapedia_flutter/screens/home/marapedia_footer.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/article_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/article_card.dart';
import '../../widgets/category_tabs.dart';
import '../../widgets/shimmer_card.dart';
import '../../widgets/marapedia_app_bar.dart';

const _parchment = Color(0xFFF7F3EC);
const _parchmentDk = Color(0xFFEDE5D4);
const _border = Color(0xFFDDD4C0);
const _ink = Color(0xFF1C1812);
const _inkMid = Color(0xFF4A4035);
const _inkLight = Color(0xFF8C7E6A);
const _sage = Color(0xFF5A7A5C);
const _sageBg = Color(0xFFEBF1EB);
const _sageLight = Color(0xFFD4E4D4);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  late AnimationController _heroCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parchment,
      appBar: const MarapediaAppBar(),
      body: Column(
        children: [
          CategoryTabs(
            selected: _selectedCategory,
            onTap: (cat) {
              if (cat == 'photos') {
                context.push('/photos');
                return;
              }
              setState(() => _selectedCategory = cat);
              context.push('/category/$cat');
            },
          ),
          Expanded(
            child: BlocConsumer<ArticleBloc, ArticleState>(
              listener: (context, state) {
                if (state is ArticleHomeLoaded) {
                  _heroCtrl.forward(from: 0);
                }
              },
              builder: (context, state) {
                if (state is ArticleLoading) {
                  return const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(count: 4),
                  );
                }
                if (state is ArticleHomeLoaded) {
                  return _buildHome(context, state);
                }
                if (state is ArticleError) {
                  return _buildError(context, state.message);
                }
                return const SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(count: 4),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return FloatingActionButton.extended(
              onPressed: () => context.push('/articles/create'),
              backgroundColor: _sage,
              elevation: 2,
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 18),
              label: Text(
                'Contribute',
                style: GoogleFonts.lora(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context, ArticleHomeLoaded state) {
    final nonFeaturedMostViewed = state.mostViewed
        .where((a) => a.id != state.featured?.id)
        .toList();

    return RefreshIndicator(
      color: _sage,
      onRefresh: () async =>
          context.read<ArticleBloc>().add(ArticleHomeLoadRequested()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _heroFade,
              child: SlideTransition(
                position: _heroSlide,
                child: _buildHero(context, state),
              ),
            ),
            const SizedBox(height: 28),
            if (state.featured != null) ...[
              _sectionHeader('Featured Article', icon: '✦'),
              const SizedBox(height: 12),
              _buildFeatured(context, state),
              const SizedBox(height: 28),
            ],
            _sectionHeader('Recent Articles', icon: '◈'),
            const SizedBox(height: 12),
            _buildArticleGrid(context, state.recent),
            if (nonFeaturedMostViewed.isNotEmpty) ...[
              const SizedBox(height: 28),
              _sectionHeader('Most Viewed', icon: '◉'),
              const SizedBox(height: 12),
              _buildArticleGrid(context, nonFeaturedMostViewed),
            ],
            const SizedBox(height: 32),
            const MarapediaFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, ArticleHomeLoaded state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: _parchmentDk,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.5),
                  ),
                  child: Text(
                    'THE FREE MARA ENCYCLOPEDIA',
                    style: GoogleFonts.lora(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _inkLight,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Preserving Mara\nHistory & Culture',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A community-built encyclopedia for the Mara people.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: _inkLight, height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: ['Mara', 'English', 'Myanmar', 'Mizo']
                      .map((lang) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              border: Border.all(color: _border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              lang,
                              style: TextStyle(
                                fontSize: 11,
                                color: _inkMid,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _statCard('${state.articleCount}',
                          'Articles', Icons.article_outlined),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard('${state.userCount}',
                          'Contributors', Icons.people_outline),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                          '4', 'Languages', Icons.translate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _sage, size: 15),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _inkLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {String icon = '◈'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(icon,
              style: const TextStyle(fontSize: 11, color: _sage)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_border, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatured(BuildContext context, ArticleHomeLoaded state) {
    final article = state.featured!;
    final t = Helpers.getPreferredTranslation(
      article.translations
          .map((t) => {
                'language': t.language,
                'title': t.title,
                'content': t.content,
                'excerpt': t.excerpt,
              })
          .toList(),
    );
    if (t == null) return const SizedBox.shrink();

    final title = t['title'] as String? ?? '';
    final excerpt = t['excerpt'] as String? ??
        Helpers.makeExcerpt(t['content'] as String? ?? '', length: 180);
    final hasThumb = article.thumbnailUrl != null &&
        article.thumbnailUrl!.isNotEmpty;
    final cat = Helpers.getCategoryInfo(article.category);

    return GestureDetector(
      onTap: () => context.push('/articles/${article.slug}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasThumb)
                Stack(
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: article.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: _parchmentDk),
                        errorWidget: (_, __, ___) =>
                            Container(color: _parchmentDk),
                      ),
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0, height: 80,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.22),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              'Featured',
                              style: GoogleFonts.lora(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 56,
                  color: _parchmentDk,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              'Featured',
                              style: GoogleFonts.lora(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _sageBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _sageLight),
                      ),
                      child: Text(
                        '${cat?['icon'] ?? ''} ${cat?['label'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _sage,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      excerpt,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _inkLight,
                        height: 1.6,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Container(height: 1, color: _border),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: _sageBg,
                          child: Text(
                            (article.profile?.username ?? 'A')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _sage,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.profile?.username ?? 'Anonymous',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _inkMid,
                                ),
                              ),
                              Text(
                                Helpers.timeAgo(article.updatedAt ??
                                    article.createdAt),
                                style: const TextStyle(
                                    fontSize: 11, color: _inkLight),
                              ),
                            ],
                          ),
                        ),
                        if (article.viewCount > 0) ...[
                          const Icon(Icons.remove_red_eye_outlined,
                              size: 12, color: _inkLight),
                          const SizedBox(width: 3),
                          Text(
                            '${article.viewCount}',
                            style: const TextStyle(
                                fontSize: 11, color: _inkLight),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Read →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleGrid(
      BuildContext context, List<ArticleModel> articles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: articles.length,
        itemBuilder: (_, i) => ArticleCard(article: articles[i]),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD9A0)),
              ),
              child: const Icon(Icons.wifi_off_outlined,
                  size: 26, color: Color(0xFFD4860A)),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load articles',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _inkLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<ArticleBloc>()
                  .add(ArticleHomeLoadRequested()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sage,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8C7E6A).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 26.0;
    for (double i = -size.height;
        i < size.width + size.height;
        i += spacing) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }

    final accentPaint = Paint()
      ..color = const Color(0xFF8C7E6A).withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int r = 1; r <= 4; r++) {
      canvas.drawCircle(
          Offset(size.width, 0), r * 30.0, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}