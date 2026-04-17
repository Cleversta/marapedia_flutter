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
  final String type; // 'comment' | 'like'
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
  const MarapediaAppBar({super.key, this.showSearch = true});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<MarapediaAppBar> createState() => _MarapediaAppBarState();
}

class _MarapediaAppBarState extends State<MarapediaAppBar> {
  bool _searching = false;
  final _ctrl = TextEditingController();

  // ── Notifications state ──
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
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _loadNotifications());
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
          _notifs = (data as List).map((m) => _Notif.fromMap(Map<String, dynamic>.from(m))).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final unreadIds = _notifs.where((n) => !n.read).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .inFilter('id', unreadIds);
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
          .update({'read': true})
          .eq('id', id);
      if (mounted) {
        setState(() {
          _notifs = _notifs.map((n) => n.id == id ? n.copyWith(read: true) : n).toList();
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

  @override
  Widget build(BuildContext context) {
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
                    Image.asset('assets/logo.png', width: 32, height: 32, fit: BoxFit.contain),
                    const SizedBox(width: 6),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        children: [
                          TextSpan(text: 'Mara'),
                          TextSpan(text: 'pedia', style: TextStyle(color: AppTheme.greenPrimary)),
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
      actions: [
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
                    // ── Bell icon ──
                    _BellButton(unread: _unread, onTap: _openNotifications),
                    const SizedBox(width: 4),
                    // ── Avatar + menu ──
                    PopupMenuButton<String>(
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildAvatar(state),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person_outline, size: 18), SizedBox(width: 8), Text('My Profile')])),
                        const PopupMenuItem(value: 'articles', child: Row(children: [Icon(Icons.article_outlined, size: 18), SizedBox(width: 8), Text('My Articles')])),
                        if (state.profile.isEditor)
                          const PopupMenuItem(value: 'editor', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editor Panel')])),
                        if (state.profile.isAdmin)
                          const PopupMenuItem(value: 'admin', child: Row(children: [Icon(Icons.admin_panel_settings_outlined, size: 18), SizedBox(width: 8), Text('Admin Panel')])),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(children: [
                            Icon(Icons.logout, size: 18, color: Colors.red[400]),
                            const SizedBox(width: 8),
                            Text('Sign out', style: TextStyle(color: Colors.red[400])),
                          ]),
                        ),
                      ],
                      onSelected: (val) {
                        switch (val) {
                          case 'profile': context.push('/profile'); break;
                          case 'articles': context.push('/my-articles'); break;
                          case 'editor': context.push('/editor'); break;
                          case 'admin': context.push('/admin'); break;
                          case 'logout':
                            context.read<AuthBloc>().add(AuthLogoutRequested());
                            context.go('/');
                            break;
                        }
                      },
                    ),
                  ],
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: () => context.push('/login'), child: const Text('Sign in')),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero),
                      child: const Text('Register', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              );
            },
          ),
        if (_searching)
          IconButton(icon: const Icon(Icons.search), onPressed: _submitSearch),
      ],
    );
  }

  Widget _buildAvatar(AuthAuthenticated state) {
    final url = state.profile.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.greenLight,
        backgroundImage: CachedNetworkImageProvider(url),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.greenLight,
      child: Text(
        state.profile.username[0].toUpperCase(),
        style: const TextStyle(color: AppTheme.greenDark, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

// ─── Bell button with badge ───────────────────────────────────────────────────

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
            const Icon(Icons.notifications_outlined, color: Color(0xFF6B7280), size: 22),
            if (unread > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          // List
          if (notifs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                Icon(Icons.notifications_off_outlined, size: 40, color: Color(0xFFD1D5DB)),
                SizedBox(height: 12),
                Text('No notifications yet', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
              ]),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                itemBuilder: (_, i) {
                  final n = notifs[i];
                  return InkWell(
                    onTap: () => onTap(n),
                    child: Container(
                      color: n.read ? Colors.transparent : const Color(0xFFF0FDF4),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Text(n.type == 'comment' ? '💬' : '❤️', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
                                    children: [
                                      TextSpan(text: n.actorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      TextSpan(text: n.type == 'comment' ? ' commented on ' : ' liked '),
                                      TextSpan(text: '"${n.articleTitle}"', style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(_timeAgo(n.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                          // Unread dot
                          if (!n.read)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 8),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.greenPrimary, shape: BoxShape.circle),
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