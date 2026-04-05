import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marapedia_flutter/repositories/contributors_repository.dart';
import 'package:marapedia_flutter/utils/helpers.dart';

const _parchment   = Color(0xFFF7F3EC);
const _parchmentDk = Color(0xFFEDE5D4);
const _border      = Color(0xFFDDD4C0);
const _ink         = Color(0xFF1C1812);
const _inkMid      = Color(0xFF4A4035);
const _inkLight    = Color(0xFF8C7E6A);
const _sage        = Color(0xFF5A7A5C);
const _sageBg      = Color(0xFFEBF1EB);

class ContributorsScreen extends StatefulWidget {
  const ContributorsScreen({super.key});

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen> {
  final _repo = ContributorsRepository();
  List<ContributorInfo>? _contributors;
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
      final data = await _repo.getContributors();
      setState(() { _contributors = data; _loading = false; });
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
          'Contributors',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
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
            const Icon(Icons.wifi_off_outlined, size: 40, color: _inkLight),
            const SizedBox(height: 12),
            Text('Could not load contributors',
                style: GoogleFonts.lora(fontSize: 16, color: _ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _inkLight)),
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
    final contributors = _contributors ?? [];
    final active = contributors.where((c) => c.publishedCount > 0).toList();
    final members = contributors.where((c) => c.publishedCount == 0).toList();

    final totalPublished = active.fold(0, (s, c) => s + c.publishedCount);

    return RefreshIndicator(
      color: _sage,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Stats header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _parchmentDk,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Text(
                    'The people preserving Mara history,\nsongs, stories, and culture.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _inkLight, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem('${contributors.length}', 'Members'),
                      Container(width: 1, height: 28, color: _border),
                      _statItem('${active.length}', 'Contributors'),
                      Container(width: 1, height: 28, color: _border),
                      _statItem('$totalPublished', 'Articles'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Active contributors ───────────────────────────────────────
          if (active.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    const Text('✦', style: TextStyle(fontSize: 11, color: _sage)),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVE CONTRIBUTORS',
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _inkLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ContributorTile(
                  info: active[index],
                  rank: index,
                ),
                childCount: active.length,
              ),
            ),
          ],

          // ── Members (no articles) ─────────────────────────────────────
          if (members.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Row(
                  children: [
                    const Text('◈', style: TextStyle(fontSize: 11, color: _inkLight)),
                    const SizedBox(width: 8),
                    Text(
                      'MEMBERS',
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _inkLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MemberChip(profile: members[index].profile),
                  childCount: members.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.lora(
                fontSize: 22, fontWeight: FontWeight.w700, color: _sage)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _inkLight)),
      ],
    );
  }
}

// ── Contributor list tile ─────────────────────────────────────────────────────

class _ContributorTile extends StatelessWidget {
  final ContributorInfo info;
  final int rank;

  const _ContributorTile({required this.info, required this.rank});

  @override
  Widget build(BuildContext context) {
    final profile = info.profile;
    final rankWidget = rank == 0
        ? const Text('🥇', style: TextStyle(fontSize: 18))
        : rank == 1
            ? const Text('🥈', style: TextStyle(fontSize: 18))
            : rank == 2
                ? const Text('🥉', style: TextStyle(fontSize: 18))
                : SizedBox(
                    width: 28,
                    child: Text(
                      '#${rank + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, color: _inkLight, fontWeight: FontWeight.w600),
                    ),
                  );

    return GestureDetector(
      onTap: () => context.push('/contributors/${profile.username}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(width: 28, child: rankWidget),
            const SizedBox(width: 10),

            // Avatar
            _Avatar(avatarUrl: profile.avatarUrl, username: profile.username, radius: 20),
            const SizedBox(width: 12),

            // Info
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RoleBadge(role: profile.role),
                    ],
                  ),
                  if (profile.fullName != null && profile.fullName!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      profile.fullName!,
                      style: const TextStyle(fontSize: 11, color: _inkLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Joined ${Helpers.formatDate(profile.createdAt)}',
                    style: const TextStyle(fontSize: 10, color: _inkLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Article count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${info.publishedCount}',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _sage,
                  ),
                ),
                Text(
                  info.publishedCount == 1 ? 'article' : 'articles',
                  style: const TextStyle(fontSize: 10, color: _inkLight),
                ),
                if (info.totalCount > info.publishedCount)
                  Text(
                    '+${info.totalCount - info.publishedCount} draft',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFD4860A)),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _inkLight),
          ],
        ),
      ),
    );
  }
}

// ── Member chip (no articles) ─────────────────────────────────────────────────

class _MemberChip extends StatelessWidget {
  final dynamic profile;
  const _MemberChip({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _parchmentDk,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _Avatar(avatarUrl: profile.avatarUrl, username: profile.username, radius: 10),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              profile.username,
              style: const TextStyle(fontSize: 11, color: _inkMid, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String? username;
  final double radius;

  const _Avatar({this.avatarUrl, this.username, required this.radius});

  @override
  Widget build(BuildContext context) {
    final safe = avatarUrl != null && avatarUrl!.isNotEmpty ? avatarUrl : null;
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
                errorWidget: (_, __, ___) => _initial(),
              ),
            )
          : _initial(),
    );
  }

  Widget _initial() => Text(
        (username ?? 'A')[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.7,
          color: _sage,
          fontWeight: FontWeight.bold,
        ),
      );
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
    return const SizedBox.shrink();
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}