import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marapedia_flutter/widgets/comments_section.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/article_model.dart';
import '../../repositories/article_repository.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/shimmer_card.dart';
import 'song_viewer.dart';
import 'poem_viewer.dart';
import 'package:collection/collection.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});
  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  String _currentLang = 'mara';
  int? _lightboxIndex;

  void _shareArticle(String slug, String title) {
    Share.share(
      'Read "$title" on Marapedia\nhttps://marapedia.org/articles/$slug',
      subject: title,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Called once after the article loads to check the favorite status.
  Future<void> _checkFavoriteStatus(
      BuildContext context, String articleId) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final repo = context.read<ArticleRepository>();
    final favorited = await repo.isFavorited(articleId, authState.userId);

    if (!context.mounted) return;
    final current = context.read<ArticleBloc>().state;
    if (current is ArticleDetailLoaded) {
      // ignore: invalid_use_of_visible_for_testing_member
      context.read<ArticleBloc>().emit(
            current.copyWith(isFavorited: favorited),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArticleBloc, ArticleState>(
      listenWhen: (prev, curr) =>
          prev is ArticleLoading && curr is ArticleDetailLoaded,
      listener: (context, state) {
        if (state is ArticleDetailLoaded) {
          _checkFavoriteStatus(context, state.article.id);
        }
      },
      builder: (context, state) {
        if (state is ArticleLoading) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 3),
            ),
          );
        }
        if (state is ArticleDetailLoaded) {
          return _buildDetail(
            context,
            state.article,
            isOffline: state.isOffline,
            isFavorited: state.isFavorited,
          );
        }
        if (state is ArticleError) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
            body: Center(child: Text(state.message)),
          );
        }
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    ArticleModel article, {
    bool isOffline = false,
    bool isFavorited = false,
  }) {
    final cat = Helpers.getCategoryInfo(article.category);
    final availLangs = article.translations.map((t) => t.language).toList();

    if (!availLangs.contains(_currentLang)) {
      for (final lang in AppConstants.languagePriority) {
        if (availLangs.contains(lang)) {
          _currentLang = lang;
          break;
        }
      }
    }

    if (article.translations.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('No content available')),
      );
    }

    final translation =
        article.translations.firstWhereOrNull(
          (t) => t.language == _currentLang,
        ) ??
        article.translations.first;

    final typeLabel = Helpers.getArticleTypeLabel(
      article.category,
      article.articleType,
    );

    final sourceUrlDisplay = article.sourceUrl
        ?.replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');
final hasThumb =
    article.thumbnailUrl != null && article.thumbnailUrl!.isNotEmpty;
final allImages = <ArticleImage>[
  if (hasThumb) ArticleImage(url: article.thumbnailUrl!),
  ...article.images.where(
    (img) => img.url != article.thumbnailUrl,
  ),
];

debugPrint('🖼️ thumbnailUrl: ${article.thumbnailUrl}');
debugPrint('🖼️ images count: ${article.images.length}');
debugPrint('🖼️ allImages count: ${allImages.length}');
for (final img in allImages) {
  debugPrint('🖼️ image url: ${img.url}');
}

    final isSong =
        article.category == 'songs' || article.articleType == 'song';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── App bar ───────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor:
                    const Color(0xFFFAFAF8).withOpacity(0.92),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  // ── Favorite heart button ──────────────────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (ctx, authState) {
                      if (authState is! AuthAuthenticated) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: child,
                          ),
                          child: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey(isFavorited),
                            color: isFavorited
                                ? Colors.red[400]
                                : null,
                            size: 20,
                          ),
                        ),
                        tooltip: isFavorited
                            ? 'Remove from saved'
                            : 'Save article',
                        onPressed: () {
                          ctx.read<ArticleBloc>().add(
                                ArticleFavoriteToggleRequested(
                                  articleId: article.id,
                                  userId: authState.userId,
                                  isFavorited: isFavorited,
                                ),
                              );
                        },
                      );
                    },
                  ),

                  // ── Share ──────────────────────────────────────────────
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    onPressed: () =>
                        _shareArticle(article.slug, translation.title),
                  ),

                  // ── Category pill ──────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cat?['icon'] ?? ''} ${cat?['label'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),

                  // ── Edit (owner / admin / editor) ──────────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (ctx, authState) {
                      if (authState is AuthAuthenticated) {
                        final isOwner =
                            authState.userId == article.authorId;
                        final isAdmin = authState.profile.isAdmin;
                        final isEditor = authState.profile.isEditor;
                        if (isOwner || isAdmin || isEditor) {
                          return IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => context
                                .push('/articles/edit/${article.slug}'),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),

              // ── Offline banner ─────────────────────────────────────────
              if (isOffline)
                const SliverToBoxAdapter(child: OfflineBanner()),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Author row ──────────────────────────────────────
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.greenLight,
                            backgroundImage: (article.profile?.avatarUrl !=
                                        null &&
                                    article.profile!.avatarUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(
                                    article.profile!.avatarUrl!)
                                : null,
                            child: article.profile?.avatarUrl == null
                                ? Text(
                                    (article.profile?.username ?? 'A')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.greenDark,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              children: [
                                Text(
                                  article.profile?.username ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF44403C),
                                  ),
                                ),
                                Text('·',
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12)),
                                Text(
                                  Helpers.formatDate(article.updatedAt ??
                                      article.createdAt),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400]),
                                ),
                                Text('·',
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.remove_red_eye_outlined,
                                        size: 11,
                                        color: Colors.grey),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${article.viewCount}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Title ───────────────────────────────────────────
                      Text(
                        translation.title,
                        style: GoogleFonts.lora(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1C1917),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Type label + Source URL ─────────────────────────
                      if (typeLabel != null || article.sourceUrl != null)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (typeLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  border: Border.all(
                                      color: Colors.grey[200]!),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (article.sourceUrl != null &&
                                article.sourceUrl!.isNotEmpty)
                              GestureDetector(
                                onTap: () =>
                                    _launchUrl(article.sourceUrl!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    border: Border.all(
                                        color: const Color(0xFFBFDBFE)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.link,
                                          size: 13,
                                          color: Color(0xFF3B82F6)),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 180),
                                        child: Text(
                                          sourceUrlDisplay ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.open_in_new,
                                          size: 11,
                                          color: Color(0xFF93C5FD)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                      // ── Image strip ─────────────────────────────────────
                      if (allImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: allImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () =>
                                  setState(() => _lightboxIndex = i),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: CachedNetworkImage(
                                      imageUrl: allImages[i].url,
                                      width: 88,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        width: 88,
                                        height: 64,
                                        color: Colors.grey[200],
                                      ),
                                    ),
                                  ),
                                  if (i == 0)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Cover',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE7E5E4)),
                      const SizedBox(height: 16),

                      // ── Language switcher ───────────────────────────────
                      if (availLangs.length > 1)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availLangs.map((lang) {
                              final isActive = _currentLang == lang;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _currentLang = lang),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isActive
                                            ? AppTheme.greenPrimary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    AppConstants.languageLabels[lang] ??
                                        lang,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isActive
                                          ? AppTheme.greenPrimary
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ── Content ─────────────────────────────────────────
                      _buildContent(article, translation.content,
                          translation.title),
const SizedBox(height: 40),
const Divider(color: Color(0xFFE7E5E4)),
const SizedBox(height: 12),
 
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Updated ${Helpers.timeAgo(article.updatedAt ?? article.createdAt)}',
      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
    ),
    GestureDetector(
      onTap: () => context.go('/'),
      child: const Text(
        '← Marapedia',
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.greenPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ],
),
 
const SizedBox(height: 16),
 
// ── Share button ─────────────────────────────────────────────────────────
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () => _shareArticle(article.slug, translation.title),
    icon: const Icon(Icons.share_outlined, size: 16),
    label: const Text('Share Article'),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTheme.greenPrimary,
      side: const BorderSide(color: AppTheme.greenPrimary),
      padding: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
),
 
if (isSong) ...[
  const SizedBox(height: 8),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.download_outlined, size: 16),
      label: const Text('Save Lyrics as Image'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  ),
],
 
// ── Likes + Comments ────
CommentsSection(articleId: article.id),
const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Lightbox ─────────────────────────────────────────────────
          if (_lightboxIndex != null) _buildLightbox(allImages),
        ],
      ),
    );
  }

  Widget _buildContent(
      ArticleModel article, String content, String title) {
    final type = article.articleType ??
        (article.category == 'songs'
            ? 'song'
            : article.category == 'poems'
                ? 'poem'
                : null);

    if (type == 'song' || article.category == 'songs') {
      return SongViewer(content: content, title: title);
    }
    if (type == 'poem' || article.category == 'poems') {
      return PoemViewer(content: content);
    }
    return Html(
      data: content,
      style: {
        'body': Style(
          fontFamily: 'Lora',
          fontSize: FontSize(16),
          lineHeight: LineHeight(1.85),
          color: const Color(0xFF292524),
        ),
        'p': Style(margin: Margins.only(bottom: 20)),
        'h1': Style(
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.w700,
          fontSize: FontSize(26),
        ),
        'h2': Style(
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.w700,
          fontSize: FontSize(20),
        ),
        'h3': Style(
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.w600,
          fontSize: FontSize(17),
        ),
        'blockquote': Style(
          border: const Border(
            left: BorderSide(color: AppTheme.greenPrimary, width: 3),
          ),
          padding: HtmlPaddings.only(left: 16),
          color: const Color(0xFF166534),
          fontStyle: FontStyle.italic,
          margin:
              Margins.only(left: 0, right: 0, top: 12, bottom: 12),
        ),
        'a': Style(
          color: AppTheme.greenPrimary,
          textDecoration: TextDecoration.underline,
        ),
        'li': Style(lineHeight: LineHeight(1.7)),
        'img': Style(width: Width(double.infinity)),
      },
    );
  }

  Widget _buildLightbox(List<ArticleImage> images) {
    return GestureDetector(
      onTap: () => setState(() => _lightboxIndex = null),
      child: Container(
        color: Colors.black.withOpacity(0.92),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: images[_lightboxIndex!].url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.7,
                      ),
                      if (images[_lightboxIndex!].caption != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          images[_lightboxIndex!].caption!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${_lightboxIndex! + 1} / ${images.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                  ),
                  onPressed: () =>
                      setState(() => _lightboxIndex = null),
                ),
              ),
              if (_lightboxIndex! > 0)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left,
                            color: Colors.white),
                      ),
                      onPressed: () => setState(
                          () => _lightboxIndex = _lightboxIndex! - 1),
                    ),
                  ),
                ),
              if (_lightboxIndex! < images.length - 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right,
                            color: Colors.white),
                      ),
                      onPressed: () => setState(
                          () => _lightboxIndex = _lightboxIndex! + 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}