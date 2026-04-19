import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

// ─── Notification model ───────────────────────────────────────────────────────

class _Notif {
  final String id;
  final String type;
  final String actorName;
  final String articleTitle;
  final String articleSlug;
  final bool read;
  final DateTime createdAt;

  _Notif({
    required this.id,
    required this.type,
    required this.actorName,
    required this.articleTitle,
    required this.articleSlug,
    required this.read,
    required this.createdAt,
  });

  factory _Notif.fromMap(Map<String, dynamic> m) => _Notif(
        id: m['id'] as String,
        type: m['type'] as String,
        actorName: (m['actor_name'] as String?) ?? 'Someone',
        articleTitle: (m['article_title'] as String?) ?? '',
        articleSlug: (m['article_slug'] as String?) ?? '',
        read: (m['read'] as bool?) ?? false,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  _Notif copyWith({bool? read}) => _Notif(
        id: id,
        type: type,
        actorName: actorName,
        articleTitle: articleTitle,
        articleSlug: articleSlug,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class MarapediaAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showSearch;
  final bool showBackButton;

  const MarapediaAppBar({
    super.key,
    this.showSearch = true,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<MarapediaAppBar> createState() => _MarapediaAppBarState();
}

class _MarapediaAppBarState extends State<MarapediaAppBar> {
  bool _searching = false;
  final _ctrl = TextEditingController();

  List<_Notif> _notifs = [];
  Timer? _timer;
  String? _currentUserId;

  int get _unread => _notifs.where((n) => !n.read).length;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _currentUserId = user.id;
    _loadNotifications();
    _timer = Timer.periodic(
        const Duration(seconds: 60), (_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(20);
      if (mounted) {
        setState(() {
          _notifs = (data as List)
              .map((m) => _Notif.fromMap(Map<String, dynamic>.from(m)))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final unreadIds =
        _notifs.where((n) => !n.read).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true}).inFilter('id', unreadIds);
      if (mounted) {
        setState(() {
          _notifs = _notifs.map((n) => n.copyWith(read: true)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _markOneRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true}).eq('id', id);
      if (mounted) {
        setState(() {
          _notifs = _notifs
              .map((n) => n.id == id ? n.copyWith(read: true) : n)
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _submitSearch() {
    if (_ctrl.text.trim().isNotEmpty) {
      context.push('/search?q=${Uri.encodeComponent(_ctrl.text.trim())}');
      setState(() {
        _searching = false;
        _ctrl.clear();
      });
    }
  }

  void _openNotifications() {
    _markAllRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(
        notifs: _notifs,
        onTap: (n) async {
          Navigator.pop(context);
          if (!n.read) await _markOneRead(n.id);
          if (n.articleSlug.isNotEmpty && mounted) {
            context.push('/articles/${n.articleSlug}');
          }
        },
      ),
    );
  }

  void _openInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Marapedia',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            const Text(
              'The Free Mara Encyclopedia',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            for (final item in [
              (Icons.info_outline_rounded, 'About Marapedia', '/about'),
              (Icons.shield_outlined, 'Privacy Policy', '/privacy'),
              (Icons.people_outline_rounded, 'Contributors', '/contributors'),
              (Icons.edit_outlined, 'How to Contribute', '/about'),
            ])
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push(item.$3);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(item.$1, color: AppTheme.greenPrimary, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF374151)),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openProfileDrawer(AuthAuthenticated state) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'profile-drawer',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        final fade = Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeIn));

        return FadeTransition(
          opacity: fade,
          child: Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: slide,
              child: _ProfileDrawer(
                state: state,
                onNavigate: (route) {
                  Navigator.pop(ctx);
                  context.push(route);
                },
                onLogout: () {
                  Navigator.pop(ctx);
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  context.go('/');
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Shared actions (right side) ─────────────────────────────────────────────

  List<Widget> _buildActions() {
    return [
      if (widget.showSearch && !_searching)
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          onPressed: () => setState(() => _searching = true),
        ),
      if (!_searching)
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BellButton(unread: _unread, onTap: _openNotifications),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => _openProfileDrawer(state),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, left: 4),
                      child: _buildAvatar(state),
                    ),
                  ),
                ],
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline,
                      color: Color(0xFF6B7280), size: 20),
                  onPressed: _openInfoSheet,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign in')),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () => context.push('/register'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero),
                    child: const Text('Register',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            );
          },
        ),
      if (_searching)
        IconButton(
            icon: const Icon(Icons.search), onPressed: _submitSearch),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // ── Back-button mode ────────────────────────────────────────────────────
    if (widget.showBackButton) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: _searching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _searching = false;
                  _ctrl.clear();
                }),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF374151), size: 20),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
        title: _searching
            ? TextField(
                controller: _ctrl,
                autofocus: true,
                autofillHints: const [],
                enableIMEPersonalizedLearning: false,
                decoration: const InputDecoration(
                  hintText: 'Search the encyclopedia...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitSearch(),
              )
            : null,
        actions: _buildActions(),
      );
    }

    // ── Default logo mode ───────────────────────────────────────────────────
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      leadingWidth: _searching ? 56 : 160,
      leading: _searching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _searching = false;
                _ctrl.clear();
              }),
            )
          : GestureDetector(
              onTap: () => context.go('/'),
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png',
                        width: 32, height: 32, fit: BoxFit.contain),
                    const SizedBox(width: 6),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827)),
                        children: [
                          TextSpan(text: 'Mara'),
                          TextSpan(
                              text: 'pedia',
                              style:
                                  TextStyle(color: AppTheme.greenPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      title: _searching
          ? TextField(
              controller: _ctrl,
              autofocus: true,
              autofillHints: const [],
              enableIMEPersonalizedLearning: false,
              decoration: const InputDecoration(
                hintText: 'Search the encyclopedia...',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitSearch(),
            )
          : null,
      actions: _buildActions(),
    );
  }

  Widget _buildAvatar(AuthAuthenticated state) {
    final url = state.profile.avatarUrl;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.greenPrimary, width: 2),
      ),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: AppTheme.greenLight,
        backgroundImage: (url != null && url.isNotEmpty)
            ? CachedNetworkImageProvider(url)
            : null,
        onBackgroundImageError:
            (url != null && url.isNotEmpty) ? (_, __) {} : null,
        child: (url == null || url.isEmpty)
            ? Text(
                state.profile.username[0].toUpperCase(),
                style: const TextStyle(
                    color: AppTheme.greenDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              )
            : null,
      ),
    );
  }
}

// ─── Profile Drawer ───────────────────────────────────────────────────────────

class _ProfileDrawer extends StatelessWidget {
  final AuthAuthenticated state;
  final void Function(String route) onNavigate;
  final VoidCallback onLogout;

  const _ProfileDrawer({
    required this.state,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final url = profile.avatarUrl;
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: screenWidth * 0.78,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 24,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF14532D), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -24,
                      top: -24,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: -30,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.25),
                            ),
                            child: CircleAvatar(
                              radius: 34,
                              backgroundColor: Colors.white24,
                              backgroundImage:
                                  (url != null && url.isNotEmpty)
                                      ? CachedNetworkImageProvider(url)
                                      : null,
                              child: (url == null || url.isEmpty)
                                  ? Text(
                                      profile.username[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            profile.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (profile.isAdmin)
                                _RoleBadge(
                                  label: '⚙️  Admin',
                                  bg: Colors.red.withOpacity(0.25),
                                  border: Colors.red[200]!,
                                  textColor: Colors.red[100]!,
                                )
                              else if (profile.isEditor)
                                _RoleBadge(
                                  label: '✏️  Editor',
                                  bg: Colors.amber.withOpacity(0.25),
                                  border: Colors.amber[200]!,
                                  textColor: Colors.amber[100]!,
                                )
                              else
                                _RoleBadge(
                                  label: '📖  Member',
                                  bg: Colors.white.withOpacity(0.15),
                                  border: Colors.white30,
                                  textColor: Colors.white70,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    const _SectionLabel('Account'),
                    _DrawerItem(
                      icon: Icons.person_rounded,
                      label: 'My Profile',
                      subtitle: 'View & edit your info',
                      onTap: () => onNavigate('/profile'),
                    ),
                    _DrawerItem(
                      icon: Icons.article_rounded,
                      label: 'My Articles',
                      subtitle: 'Manage your contributions',
                      onTap: () => onNavigate('/my-articles'),
                    ),
                    if (profile.isEditor || profile.isAdmin) ...[
                      const SizedBox(height: 4),
                      const _SectionLabel('Management'),
                    ],
                    if (profile.isEditor)
                      _DrawerItem(
                        icon: Icons.edit_note_rounded,
                        label: 'Editor Panel',
                        subtitle: 'Review & publish content',
                        accent: true,
                        onTap: () => onNavigate('/editor'),
                      ),
                    if (profile.isAdmin)
                      _DrawerItem(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin Panel',
                        subtitle: 'Full site control',
                        accent: true,
                        onTap: () => onNavigate('/admin'),
                      ),
                    const SizedBox(height: 4),
                    const _SectionLabel('Info'),
                    _DrawerItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About Marapedia',
                      subtitle: 'Our mission & story',
                      onTap: () => onNavigate('/about'),
                    ),
                    _DrawerItem(
                      icon: Icons.shield_outlined,
                      label: 'Privacy Policy',
                      subtitle: 'How we handle your data',
                      onTap: () => onNavigate('/privacy'),
                    ),
                    _DrawerItem(
                      icon: Icons.people_outline_rounded,
                      label: 'Contributors',
                      subtitle: 'Meet the community',
                      onTap: () => onNavigate('/contributors'),
                    ),
                    _DrawerItem(
                      icon: Icons.edit_outlined,
                      label: 'How to Contribute',
                      subtitle: 'Help grow the encyclopedia',
                      onTap: () => onNavigate('/about'),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 13, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 18, color: Colors.red[400]),
                        const SizedBox(width: 10),
                        Text(
                          'Sign out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[400],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: Colors.red[300]),
                      ],
                    ),
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

// ─── Drawer sub-widgets ───────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color border;
  final Color textColor;

  const _RoleBadge({
    required this.label,
    required this.bg,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.accent ? AppTheme.greenPrimary : const Color(0xFF374151);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: _pressed
              ? (widget.accent
                  ? AppTheme.greenPrimary.withOpacity(0.08)
                  : Colors.grey[100])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.accent
                    ? AppTheme.greenPrimary.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.accent
                      ? AppTheme.greenPrimary.withOpacity(0.2)
                      : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: widget.accent
                          ? AppTheme.greenPrimary
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ─── Bell button ──────────────────────────────────────────────────────────────

class _BellButton extends StatelessWidget {
  final int unread;
  final VoidCallback onTap;
  const _BellButton({required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_outlined,
                color: Color(0xFF6B7280), size: 22),
            if (unread > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification bottom sheet ────────────────────────────────────────────────

class _NotificationSheet extends StatelessWidget {
  final List<_Notif> notifs;
  final void Function(_Notif) onTap;
  const _NotificationSheet({required this.notifs, required this.onTap});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Notifications',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          if (notifs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                Icon(Icons.notifications_off_outlined,
                    size: 40, color: Color(0xFFD1D5DB)),
                SizedBox(height: 12),
                Text('No notifications yet',
                    style: TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 14)),
              ]),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 56),
                itemBuilder: (_, i) {
                  final n = notifs[i];
                  return InkWell(
                    onTap: () => onTap(n),
                    child: Container(
                      color: n.read
                          ? Colors.transparent
                          : const Color(0xFFF0FDF4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.type == 'comment' ? '💬' : '❤️',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF374151),
                                        height: 1.4),
                                    children: [
                                      TextSpan(
                                          text: n.actorName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      TextSpan(
                                          text: n.type == 'comment'
                                              ? ' commented on '
                                              : ' liked '),
                                      TextSpan(
                                          text: '"${n.articleTitle}"',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF111827))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(_timeAgo(n.createdAt),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                          if (!n.read)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 6, left: 8),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: AppTheme.greenPrimary,
                                    shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}