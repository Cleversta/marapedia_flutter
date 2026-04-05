import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marapedia_flutter/models/article_model.dart';
import 'package:marapedia_flutter/models/profile_model.dart';
import 'package:marapedia_flutter/repositories/contributors_repository.dart';
import 'package:marapedia_flutter/utils/helpers.dart';
import 'package:marapedia_flutter/widgets/article_card.dart';

const _parchment   = Color(0xFFF7F3EC);
const _parchmentDk = Color(0xFFEDE5D4);
const _border      = Color(0xFFDDD4C0);
const _ink         = Color(0xFF1C1812);
const _inkMid      = Color(0xFF4A4035);
const _inkLight    = Color(0xFF8C7E6A);
const _sage        = Color(0xFF5A7A5C);
const _sageBg      = Color(0xFFEBF1EB);

class ContributorDetailScreen extends StatefulWidget {
  final String username;
  const ContributorDetailScreen({super.key, required this.username});

  @override
  State<ContributorDetailScreen> createState() => _ContributorDetailScreenState();
}

class _ContributorDetailScreenState extends State<ContributorDetailScreen> {
  final _repo = ContributorsRepository();
  ProfileModel? _profile;
  List<ArticleModel> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Get all contributors and find matching username
      final all = await _repo.getContributors();
      final match = all.where((c) => c.profile.username == widget.username).firstOrNull;

      if (match == null) {
        setState(() { _error = 'Contributor not found.'; _loading = false; });
        return;
      }

      final articles = await _repo.getArticlesByAuthor(match.profile.id);
      setState(() {
        _profile = match.profile;
        _articles = articles;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parchment,
      appBar: AppBar(
        backgroundColor: _parchment,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _inkMid),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _profile?.username ?? widget.username,
          style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _sage))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 40, color: _inkLight),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(fontSize: 15, color: _ink)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: _sage,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final profile = _profile!;
    final totalViews = _articles.fold(0, (s, a) => s + a.viewCount);
    final categories = _articles.map((a) => a.category).toSet().length;

    return RefreshIndicator(
      color: _sage,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Profile card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar + name
                  Row(
                    children: [
                      _buildAvatar(profile, 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.username,
                                    style: GoogleFonts.lora(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _RoleBadge(role: profile.role),
                              ],
                            ),
                            if (profile.fullName != null && profile.fullName!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                profile.fullName!,
                                style: const TextStyle(fontSize: 13, color: _inkLight),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Member since ${Helpers.formatDate(profile.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: _inkLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: _border),
                    const SizedBox(height: 12),
                    Text(
                      profile.bio!,
                      style: const TextStyle(fontSize: 13, color: _inkMid, height: 1.6),
                    ),
                  ],

                  // Stats row
                  const SizedBox(height: 16),
                  Container(height: 1, color: _border),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _statItem('${_articles.length}',
                          _articles.length == 1 ? 'Article' : 'Articles')),
                      Container(width: 1, height: 32, color: _border),
                      Expanded(child: _statItem('$categories',
                          categories == 1 ? 'Category' : 'Categories')),
                      Container(width: 1, height: 32, color: _border),
                      Expanded(child: _statItem(
                          totalViews >= 1000
                              ? '${(totalViews / 1000).toStringAsFixed(1)}k'
                              : '$totalViews',
                          'Total Views')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Articles section header ────────────────────────────────────
          if (_articles.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    const Text('◈', style: TextStyle(fontSize: 11, color: _sage)),
                    const SizedBox(width: 8),
                    Text(
                      'Articles',
                      style: GoogleFonts.lora(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${_articles.length})',
                      style: const TextStyle(fontSize: 13, color: _inkLight),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_border, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Articles grid ─────────────────────────────────────────────
          if (_articles.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ArticleCard(article: _articles[index]),
                  childCount: _articles.length,
                ),
              ),
            ),

          // ── Empty state ───────────────────────────────────────────────
          if (_articles.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: _parchmentDk,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Text('✍️', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 10),
                    Text(
                      'No published articles yet.',
                      style: TextStyle(fontSize: 13, color: _inkLight),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProfileModel profile, double radius) {
    final safe = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
        ? profile.avatarUrl
        : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: _sageBg,
      child: safe != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: safe,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initial(profile.username, radius),
              ),
            )
          : _initial(profile.username, radius),
    );
  }

  Widget _initial(String username, double radius) => Text(
        username[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.7,
          color: _sage,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.lora(
                fontSize: 18, fontWeight: FontWeight.w700, color: _sage)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: _inkLight)),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == 'admin') {
      return _badge('admin', const Color(0xFFF3E8FF), const Color(0xFF7E22CE));
    }
    if (role == 'editor') {
      return _badge('editor', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8));
    }
    return _badge('member', _sageBg, _sage);
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}