import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ArticleComment {
  final String id;
  final String displayName;
  final String body;
  final String createdAt;
  final String? userId;
  final String? avatarUrl;

  const ArticleComment({
    required this.id,
    required this.displayName,
    required this.body,
    required this.createdAt,
    this.userId,
    this.avatarUrl,
  });

  factory ArticleComment.fromJson(Map<String, dynamic> j) {
    final profiles = j['profiles'];
    String? avatarUrl;

    if (profiles is Map) {
      avatarUrl = profiles['avatar_url'] as String?;
    } else if (profiles is List && profiles.isNotEmpty) {
      avatarUrl = profiles.first['avatar_url'] as String?;
    }

    return ArticleComment(
      id: j['id'] as String? ?? '',
      displayName: j['display_name'] as String? ?? 'Anonymous',
      body: j['body'] as String? ?? '',
      createdAt: j['created_at'] as String? ?? '',
      userId: j['user_id'] as String?,
      avatarUrl: avatarUrl,
    );
  }
}

// ─── Fingerprint helper ───────────────────────────────────────────────────────

Future<String> _getFingerprint() async {
  final prefs = await SharedPreferences.getInstance();
  var fp = prefs.getString('mp_fp');
  if (fp == null) {
    fp = const Uuid().v4();
    await prefs.setString('mp_fp', fp);
  }
  return fp;
}

// ─── Avatar widget ────────────────────────────────────────────────────────────

class _CommentAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double size;

  const _CommentAvatar({
    required this.avatarUrl,
    required this.displayName,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _InitialCircle(initial: initial, size: size),
          errorWidget: (_, __, ___) =>
              _InitialCircle(initial: initial, size: size),
        ),
      );
    }
    return _InitialCircle(initial: initial, size: size);
  }
}

class _InitialCircle extends StatelessWidget {
  final String initial;
  final double size;
  const _InitialCircle({required this.initial, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF78716C),
        ),
      ),
    );
  }
}

// ─── Main widget ──────────────────────────────────────────────────────────────

class CommentsSection extends StatefulWidget {
  final String articleId;

  const CommentsSection({super.key, required this.articleId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _db = Supabase.instance.client;
  final _bodyController = TextEditingController();
  final _focusNode = FocusNode();

  // Auth
  String? _currentUserId;
  String? _username;
  String? _userAvatarUrl;

  // Likes
  int _likeCount = 0;
  bool _liked = false;
  bool _likeLoading = false;

  // Comments
  List<ArticleComment> _comments = [];
  bool _loading = true;
  bool _showForm = false;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final session = _db.auth.currentSession;
    if (session != null) {
      _currentUserId = session.user.id;
      try {
        final profile = await _db
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', session.user.id)
            .maybeSingle();
        if (profile != null) {
          _username = profile['username'] as String?;
          _userAvatarUrl = profile['avatar_url'] as String?;
        }
      } catch (e) {
        debugPrint('Profile fetch error: $e');
      }
    }
    await _load();
  }

  // ── Load likes & comments ──────────────────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final fp = await _getFingerprint();
      final uid = _currentUserId;

      // ── 1. Like count — v2 API: chain .count() after filters ──────────────
      final countResponse = await _db
          .from('article_likes')
          .select()
          .eq('article_id', widget.articleId)
          .count(CountOption.exact);

      // ── 2. Did I like this? ────────────────────────────────────────────────
      dynamic myLike;
      if (uid != null) {
        myLike = await _db
            .from('article_likes')
            .select('id')
            .eq('article_id', widget.articleId)
            .eq('user_id', uid)
            .maybeSingle();
      } else {
        myLike = await _db
            .from('article_likes')
            .select('id')
            .eq('article_id', widget.articleId)
            .eq('fingerprint', fp)
            .isFilter('user_id', null)
            .maybeSingle();
      }

      // ── 3. Comments ────────────────────────────────────────────────────────
      final cmts = await _db
          .from('article_comments')
          .select(
              'id, display_name, body, created_at, user_id, profiles(avatar_url)')
          .eq('article_id', widget.articleId)
          .order('created_at', ascending: false)
          .limit(50);

      if (!mounted) return;

      setState(() {
        _likeCount = countResponse.count ?? 0;
        _liked = myLike != null;
        _comments = (cmts as List)
            .map((c) => ArticleComment.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('CommentsSection _load error: $e');
      debugPrint('$st');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Toggle like ────────────────────────────────────────────────────────────

  Future<void> _toggleLike() async {
    if (_likeLoading) return;
    setState(() => _likeLoading = true);

    try {
      final fp = await _getFingerprint();
      final uid = _currentUserId;

      if (_liked) {
        // ── Unlike ───────────────────────────────────────────────────────────
        if (uid != null) {
          await _db
              .from('article_likes')
              .delete()
              .eq('article_id', widget.articleId)
              .eq('user_id', uid);
        } else {
          await _db
              .from('article_likes')
              .delete()
              .eq('article_id', widget.articleId)
              .eq('fingerprint', fp)
              .isFilter('user_id', null);
        }
        if (mounted) {
          setState(() {
            _liked = false;
            _likeCount = (_likeCount - 1).clamp(0, 999999);
          });
        }
      } else {
        // ── Like ─────────────────────────────────────────────────────────────
        await _db.from('article_likes').insert({
          'article_id': widget.articleId,
          'fingerprint': fp,
          'user_id': uid,
        });
        if (mounted) {
          setState(() {
            _liked = true;
            _likeCount++;
          });
        }
      }
    } catch (e) {
      debugPrint('toggleLike error: $e');
      await _load();
    }

    if (mounted) setState(() => _likeLoading = false);
  }

  // ── Post comment ───────────────────────────────────────────────────────────

  Future<void> _postComment() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _db.from('article_comments').insert({
        'article_id': widget.articleId,
        'display_name': _username ?? 'Anonymous',
        'body': body,
        'user_id': _currentUserId,
      });

      _bodyController.clear();
      if (mounted) {
        setState(() {
          _showForm = false;
          _submitted = true;
          _submitting = false;
        });
      }
      await _load();
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) setState(() => _submitted = false);
    } catch (e) {
      debugPrint('postComment error: $e');
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _submitting = false;
        });
      }
    }
  }

  // ── Delete comment ─────────────────────────────────────────────────────────

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete comment?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
          'This cannot be undone.',
          style: TextStyle(fontSize: 14, color: Color(0xFF78716C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF78716C))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingId = commentId);

    try {
      await _db
          .from('article_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', _currentUserId!);

      if (mounted) {
        setState(() {
          _comments = _comments.where((c) => c.id != commentId).toList();
          _deletingId = null;
        });
      }
    } catch (e) {
      debugPrint('deleteComment error: $e');
      if (mounted) setState(() => _deletingId = null);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // ── Action bar ──────────────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ActionPill(
              onTap: _toggleLike,
              loading: _likeLoading,
              active: _liked,
              activeColor: Colors.red[400]!,
              activeBg: const Color(0xFFFFF1F2),
              activeBorder: const Color(0xFFFECDD3),
              icon: _liked ? Icons.favorite : Icons.favorite_border,
              label: _likeCount > 0 ? _likeCount.toString() : 'Like',
            ),
            _ActionPill(
              onTap: () {
                final willShow = !_showForm;
                setState(() => _showForm = willShow);
                if (willShow) {
                  Future.delayed(const Duration(milliseconds: 100),
                      () => _focusNode.requestFocus());
                }
              },
              icon: Icons.chat_bubble_outline,
              label: _comments.isNotEmpty
                  ? '${_comments.length} comment${_comments.length == 1 ? '' : 's'}'
                  : 'Comment',
            ),
            if (_submitted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 14, color: AppTheme.greenPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Comment posted',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.greenPrimary),
                  ),
                ],
              ),
          ],
        ),

        // ── Comment form ────────────────────────────────────────────────────
        if (_showForm) ...[
          const SizedBox(height: 16),
          _CommentForm(
            controller: _bodyController,
            focusNode: _focusNode,
            username: _username,
            avatarUrl: _userAvatarUrl,
            submitting: _submitting,
            error: _error,
            onPost: _postComment,
            onCancel: () {
              setState(() {
                _showForm = false;
                _error = null;
              });
            },
          ),
        ],

        // ── Comments list ───────────────────────────────────────────────────
        if (_loading) ...[
          const SizedBox(height: 20),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ] else if (_comments.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            '${_comments.length} comment${_comments.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFA8A29E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ..._comments.map((c) => _CommentTile(
                comment: c,
                isOwn: _currentUserId != null && c.userId == _currentUserId,
                isDeleting: _deletingId == c.id,
                onDelete: () => _deleteComment(c.id),
              )),
        ],
      ],
    );
  }
}

// ─── Action pill button ───────────────────────────────────────────────────────

class _ActionPill extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool loading;
  final bool active;
  final Color activeColor;
  final Color activeBg;
  final Color activeBorder;

  const _ActionPill({
    required this.onTap,
    required this.icon,
    required this.label,
    this.loading = false,
    this.active = false,
    this.activeColor = AppTheme.greenPrimary,
    this.activeBg = const Color(0xFFF0FDF4),
    this.activeBorder = const Color(0xFFBBF7D0),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.white,
          border: Border.all(
            color: active ? activeBorder : const Color(0xFFE7E5E4),
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: active ? activeColor : const Color(0xFF78716C),
                ),
              )
            else
              AnimatedScale(
                scale: active ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 15,
                  color: active ? activeColor : const Color(0xFF78716C),
                ),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? activeColor : const Color(0xFF78716C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Comment form ─────────────────────────────────────────────────────────────

class _CommentForm extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? username;
  final String? avatarUrl;
  final bool submitting;
  final String? error;
  final VoidCallback onPost;
  final VoidCallback onCancel;

  const _CommentForm({
    required this.controller,
    required this.focusNode,
    required this.username,
    required this.avatarUrl,
    required this.submitting,
    required this.error,
    required this.onPost,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E5E4)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LEAVE A COMMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA8A29E),
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Posting as ',
                    style: TextStyle(fontSize: 11, color: Color(0xFFA8A29E)),
                  ),
                  Text(
                    username ?? 'Anonymous',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF44403C),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (username != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _CommentAvatar(avatarUrl: avatarUrl, displayName: username!),
                const SizedBox(width: 8),
                Text(
                  username!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA8A29E),
                  ),
                ),
              ],
            ),
          ],
          if (username == null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Text(
                'Sign in to use your name',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.greenPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => TextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: 1000,
              maxLines: 4,
              minLines: 3,
              inputFormatters: [LengthLimitingTextInputFormatter(1000)],
              style: const TextStyle(fontSize: 14, color: Color(0xFF1C1917)),
              decoration: InputDecoration(
                hintText: 'Write your comment…',
                hintStyle: const TextStyle(
                    color: Color(0xFFD6D3D1), fontSize: 14),
                counterText: '${value.text.length}/1000',
                counterStyle: const TextStyle(
                    fontSize: 11, color: Color(0xFFD6D3D1)),
                filled: true,
                fillColor: const Color(0xFFFAFAF9),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppTheme.greenPrimary, width: 1.5),
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(
              error!,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA8A29E),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, __) => ElevatedButton(
                  onPressed:
                      (submitting || value.text.trim().isEmpty) ? null : onPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.greenPrimary,
                    disabledBackgroundColor:
                        AppTheme.greenPrimary.withOpacity(0.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.white),
                        )
                      : const Text('Post',
                          style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Comment tile ─────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final ArticleComment comment;
  final bool isOwn;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isOwn,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentAvatar(
            avatarUrl: comment.avatarUrl,
            displayName: comment.displayName,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF44403C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Helpers.timeAgo(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD6D3D1),
                      ),
                    ),
                    const Spacer(),
                    if (isOwn)
                      isDeleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.redAccent),
                            )
                          : GestureDetector(
                              onTap: onDelete,
                              child: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Color(0xFFD6D3D1),
                              ),
                            ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF57534E),
                    height: 1.6,
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