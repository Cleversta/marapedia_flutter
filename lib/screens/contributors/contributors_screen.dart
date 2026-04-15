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

// Purple for admin, blue for editor
const _adminBg  = Color(0xFFF3E8FF);
const _adminFg  = Color(0xFF7E22CE);
const _editorBg = Color(0xFFEFF6FF);
const _editorFg = Color(0xFF1D4ED8);

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

  // Sort helpers
  static int _byArticles(ContributorInfo a, ContributorInfo b) {
    if (b.publishedCount != a.publishedCount) {
      return b.publishedCount.compareTo(a.publishedCount);
    }
    if (b.totalCount != a.totalCount) {
      return b.totalCount.compareTo(a.totalCount);
    }
    return a.profile.username.compareTo(b.profile.username);
  }

  static int _byNewest(ContributorInfo a, ContributorInfo b) =>
      b.profile.createdAt.compareTo(a.profile.createdAt);

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
    final all = _contributors ?? [];

    // Split into three groups
    final admins  = (all.where((c) => c.profile.role == 'admin').toList()  ..sort(_byArticles));
    final editors = (all.where((c) => c.profile.role == 'editor').toList() ..sort(_byArticles));
    final members = (all.where((c) => c.profile.role != 'admin' && c.profile.role != 'editor').toList()
      ..sort(_byNewest));

    final totalPublished = all.fold(0, (s, c) => s + c.publishedCount);

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
                    style: const TextStyle(fontSize: 13, color: _inkLight, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem('${all.length}', 'Members', _sage),
                      Container(width: 1, height: 28, color: _border),
                      _statItem('${admins.length}', 'Admins', _adminFg),
                      Container(width: 1, height: 28, color: _border),
                      _statItem('${editors.length}', 'Editors', _editorFg),
                      Container(width: 1, height: 28, color: _border),
                      _statItem('$totalPublished', 'Articles', _sage),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Admins ────────────────────────────────────────────────────
          if (admins.isNotEmpty) ...[
            _sectionHeader('ADMINS', '◆', _adminFg),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _StaffTile(info: admins[i], rank: i + 1),
                childCount: admins.length,
              ),
            ),
          ],

          // ── Editors ───────────────────────────────────────────────────
          if (editors.isNotEmpty) ...[
            _sectionHeader('EDITORS', '◆', _editorFg),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _StaffTile(info: editors[i], rank: i + 1),
                childCount: editors.length,
              ),
            ),
          ],

          // ── Members ───────────────────────────────────────────────────
          if (members.isNotEmpty) ...[
            _sectionHeader('MEMBERS', '◈', _inkLight),
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
                  (context, i) => _MemberChip(info: members[i]),
                  childCount: members.length,
                ),
              ),
            ),
          ],

          if (all.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: _parchmentDk,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: const Center(
                  child: Text('No contributors yet.',
                      style: TextStyle(fontSize: 13, color: _inkLight)),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String label, String icon, Color iconColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 10, color: iconColor)),
            const SizedBox(width: 8),
            Text(
              label,
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
    );
  }

  Widget _statItem(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.lora(
                fontSize: 20, fontWeight: FontWeight.w700, color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _inkLight)),
      ],
    );
  }
}

// ── Staff tile (admins & editors) ─────────────────────────────────────────────

class _StaffTile extends StatelessWidget {
  final ContributorInfo info;
  final int rank; // 1-based rank within their group

  const _StaffTile({required this.info, required this.rank});

  @override
  Widget build(BuildContext context) {
    final profile = info.profile;

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
            // Rank number (within group)
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: _inkLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar
            _Avatar(avatarUrl: profile.avatarUrl, username: profile.username, radius: 20),
            const SizedBox(width: 12),

            // Name + badge + meta
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

// ── Member chip (compact grid, newest first) ──────────────────────────────────

class _MemberChip extends StatelessWidget {
  final ContributorInfo info;
  const _MemberChip({required this.info});

  @override
  Widget build(BuildContext context) {
    final profile = info.profile;
    return GestureDetector(
      onTap: () => context.push('/contributors/${profile.username}'),
      child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile.username,
                    style: const TextStyle(
                      fontSize: 11, color: _inkMid, fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Show article count if member has any
                  if (info.publishedCount > 0)
                    Text(
                      '${info.publishedCount} art.',
                      style: const TextStyle(fontSize: 9, color: _sage),
                    ),
                ],
              ),
            ),
          ],
        ),
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
    final safe = (avatarUrl != null && avatarUrl!.isNotEmpty) ? avatarUrl : null;
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
    return switch (role) {
      'admin'  => _badge('admin',  _adminBg,  _adminFg),
      'editor' => _badge('editor', _editorBg, _editorFg),
      _        => _badge('member', _sageBg,   _sage),
    };
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}