import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/photo/photo_bloc.dart';
import '../../blocs/photo/photo_event.dart';
import '../../blocs/photo/photo_state.dart';
import '../../models/article_model.dart';
import '../../models/article_translation_model.dart';
import '../../models/profile_model.dart';
import '../../services/upload_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/marapedia_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _avatarUploading = false;
  String _activeTab = 'articles';
  final _fullNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ArticleBloc>().add(ArticleMyListLoadRequested(authState.userId));
      context.read<PhotoBloc>().add(PhotoMyAlbumsLoadRequested(authState.userId));
      _fullNameCtrl.text = authState.profile.fullName ?? '';
      _bioCtrl.text = authState.profile.bio ?? '';
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    setState(() => _avatarUploading = true);
    try {
      final url = await UploadService.uploadImage(File(picked.path));
      if (mounted) context.read<AuthBloc>().add(AuthAvatarUpdateRequested(authState.userId, url));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  void _saveProfile(ProfileModel profile) {
    context.read<AuthBloc>().add(AuthProfileUpdateRequested(
      profile.id,
      fullName: _fullNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    ));
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return Scaffold(
            appBar: const MarapediaAppBar(),
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign in to view profile'),
              ),
            ),
          );
        }

        final profile = authState.profile;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            title: const Text('My Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
                onPressed: () => setState(() => _editing = !_editing),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.greenLight,
                              backgroundImage: profile.avatarUrl != null
                                  ? CachedNetworkImageProvider(profile.avatarUrl!)
                                  : null,
                              child: profile.avatarUrl == null
                                  ? Text(
                                      profile.username[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.greenDark),
                                    )
                                  : null,
                            ),
                            if (_avatarUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                  child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                ),
                              ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(color: AppTheme.greenPrimary, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(profile.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      if (profile.fullName != null)
                        Text(profile.fullName!, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: profile.isAdmin
                              ? const Color(0xFFF3E8FF)
                              : profile.isEditor ? const Color(0xFFEFF6FF) : AppTheme.greenBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile.role,
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: profile.isAdmin
                                ? const Color(0xFF7C3AED)
                                : profile.isEditor ? const Color(0xFF1D4ED8) : AppTheme.greenDark,
                          ),
                        ),
                      ),
                      if (_editing) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _fullNameCtrl,
                          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, size: 18)),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _bioCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true, prefixIcon: Icon(Icons.info_outline, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(onPressed: () => _saveProfile(profile), child: const Text('Save Changes')),
                        ),
                      ] else if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(profile.bio!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
                      ],
                    ],
                  ),
                ),

                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BlocBuilder<ArticleBloc, ArticleState>(
                    builder: (context, artState) {
                      final articles = artState is ArticleMyListLoaded ? artState.articles : <ArticleModel>[];
                      final published = articles.where((a) => a.status == 'published').length;
                      return BlocBuilder<PhotoBloc, PhotoState>(
                        builder: (context, photoState) {
                          final albums = photoState is PhotoMyAlbumsLoaded ? photoState.albums : <dynamic>[];
                          final totalPhotos = albums.fold(0, (s, a) => s + a.images.length as int);
                          return Row(
                            children: [
                              _statCard('Articles', '${articles.length}', Colors.grey[800]!),
                              const SizedBox(width: 8),
                              _statCard('Published', '$published', AppTheme.greenPrimary),
                              const SizedBox(width: 8),
                              _statCard('Albums', '${albums.length}', Colors.pink[600]!),
                              const SizedBox(width: 8),
                              _statCard('Photos', '$totalPhotos', Colors.blue[600]!),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Tabs
                Container(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                  child: Row(children: [_tab('articles', 'Articles'), _tab('photos', 'Photo Albums')]),
                ),

                if (_activeTab == 'articles') _buildArticlesTab() else _buildPhotosTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    ),
  );

  Widget _tab(String key, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: _activeTab == key ? AppTheme.greenPrimary : Colors.transparent,
            width: 2,
          )),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: _activeTab == key ? AppTheme.greenPrimary : Colors.grey[500],
          ),
        ),
      ),
    ),
  );

  Widget _buildArticlesTab() => BlocBuilder<ArticleBloc, ArticleState>(
    builder: (context, state) {
      if (state is ArticleLoading) {
        return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
      }

      final articles = state is ArticleMyListLoaded ? state.articles : <ArticleModel>[];

      if (articles.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Text('📑', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text("You haven't written any articles yet.", style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/articles/create'),
                  child: const Text('Write your first article'),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: articles.map<Widget>((a) {
          final ArticleTranslationModel? t = a.translations.isNotEmpty
              ? a.translations.firstWhere((t) => t.language == 'english', orElse: () => a.translations.first)
              : null;
          final cat = Helpers.getCategoryInfo(a.category);
          final isPublished = a.status == 'published';

          return GestureDetector(
            onTap: () => context.push('/articles/${a.slug}'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Text(cat?['icon'] ?? '', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t?.title ?? 'Untitled',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                        Text('${cat?['label'] ?? ''} · ${Helpers.timeAgo(a.updatedAt ?? a.createdAt)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPublished ? AppTheme.greenBg : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(a.status, style: TextStyle(fontSize: 10, color: isPublished ? AppTheme.greenDark : Colors.grey)),
                  ),
                  const SizedBox(width: 6),
                  // Publish / Unpublish — ArticlePublishRequested(id, bool publish)
                  GestureDetector(
                    onTap: () => context.read<ArticleBloc>().add(
                      ArticlePublishRequested(a.id, !isPublished),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isPublished ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPublished ? 'Unpublish' : 'Publish',
                        style: TextStyle(fontSize: 11, color: isPublished ? const Color(0xFFD97706) : AppTheme.greenDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Edit
                  GestureDetector(
                    onTap: () => context.push('/articles/edit/${a.slug}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Edit', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Delete
                  GestureDetector(
                    onTap: () => _confirmDelete(context, a.id, t?.title ?? a.slug),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(border: Border.all(color: Colors.red[200]!), borderRadius: BorderRadius.circular(8)),
                      child: Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red[400])),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList()
          ..add(const SizedBox(height: 40)),
      );
    },
  );

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Article', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "$title"? This cannot be undone.', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ArticleBloc>().add(ArticleDeleteRequested(id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() => BlocBuilder<PhotoBloc, PhotoState>(
    builder: (context, state) {
      final albums = state is PhotoMyAlbumsLoaded ? state.albums : <dynamic>[];

      if (albums.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Text('📷', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text("No photo albums yet.", style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => context.push('/photos'), child: const Text('Upload Photos')),
              ],
            ),
          ),
        );
      }

      return Column(
        children: albums.map<Widget>((a) {
          final isPublic = a.isPublic as bool;
          return GestureDetector(
            onTap: () => context.push('/photos/${a.id}'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: a.thumbnailUrl != null
                        ? Image.network(a.thumbnailUrl!, width: 52, height: 52, fit: BoxFit.cover)
                        : Container(width: 52, height: 52, color: Colors.grey[200], child: const Icon(Icons.photo, color: Colors.grey)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                        Text('${a.images.length} photos · ${Helpers.timeAgo(a.createdAt)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                        const SizedBox(height: 2),
                        // Public / Hidden badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPublic ? AppTheme.greenBg : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPublic ? 'Public' : 'Hidden',
                            style: TextStyle(fontSize: 9, color: isPublic ? AppTheme.greenDark : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hide / Make Public — PhotoTogglePublicRequested(id, newValue)
                  GestureDetector(
                    onTap: () => context.read<PhotoBloc>().add(PhotoTogglePublicRequested(a.id, !isPublic)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: isPublic ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPublic ? 'Hide' : 'Make Public',
                        style: TextStyle(fontSize: 11, color: isPublic ? const Color(0xFFD97706) : AppTheme.greenDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList()
          ..add(const SizedBox(height: 40)),
      );
    },
  );
}