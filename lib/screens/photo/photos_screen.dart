import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/photo/photo_bloc.dart';
import '../../blocs/photo/photo_event.dart';
import '../../blocs/photo/photo_state.dart';
import '../../models/photo_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PhotoBloc>().add(PhotoAllLoadRequested());
  }

  void _showUploadModal(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PhotoBloc>(),
        child: _UploadSheet(userId: userId),
      ),
    ).then((_) => context.read<PhotoBloc>().add(PhotoAllLoadRequested()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📷 Photos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<PhotoBloc, PhotoState>(
        builder: (context, state) {
          if (state is PhotoLoading)
            return const Center(child: CircularProgressIndicator());

          if (state is PhotoAllLoaded) {
            if (state.albums.isEmpty)
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📷', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    const Text(
                      'No photos yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Be the first to share photos of Mara life',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (ctx, authState) {
                        if (authState is AuthAuthenticated) {
                          return ElevatedButton.icon(
                            onPressed: () => _showUploadModal(authState.userId),
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload First Photos'),
                          );
                        }
                        return ElevatedButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('Login to Upload'),
                        );
                      },
                    ),
                  ],
                ),
              );

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<PhotoBloc>().add(PhotoAllLoadRequested()),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: state.albums.length,
                itemBuilder: (_, i) => _AlbumCard(album: state.albums[i]),
              ),
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (_, authState) {
          if (authState is AuthAuthenticated) {
            return FloatingActionButton.extended(
              onPressed: () => _showUploadModal(authState.userId),
              backgroundColor: AppTheme.greenPrimary,
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text(
                'Upload',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final PhotoAlbum album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final cover = album.images.isNotEmpty ? album.images.first : null;
    return GestureDetector(
      onTap: () => context.push('/photos/${album.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  cover != null
                      ? CachedNetworkImage(
                          imageUrl: cover.url,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(
                              Icons.photo_library_outlined,
                              size: 36,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  if (album.images.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${album.images.length} photos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        album.profile?['username'] ?? 'Anonymous',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        Helpers.timeAgo(album.createdAt),
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
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

// ── Upload bottom sheet ───────────────────────────────────────────────────────
class _UploadSheet extends StatefulWidget {
  final String userId;
  const _UploadSheet({required this.userId});
  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _titleCtrl = TextEditingController();
  final List<File> _files = [];
  final List<String> _captions = [];
  String _error = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: 10 - _files.length);
    setState(() {
      for (final x in picked) {
        if (_files.length < 10) {
          _files.add(File(x.path));
          _captions.add('');
        }
      }
    });
  }

  void _publish() {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please add a title.');
      return;
    }
    if (_files.isEmpty) {
      setState(() => _error = 'Please add at least one image.');
      return;
    }
    context.read<PhotoBloc>().add(
      PhotoUploadRequested(
        title: _titleCtrl.text.trim(),
        authorId: widget.userId,
        files: _files,
        captions: _captions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PhotoBloc, PhotoState>(
      listener: (context, state) {
        if (state is PhotoUploadSuccess) Navigator.pop(context);
        if (state is PhotoError) setState(() => _error = state.message);
      },
      builder: (context, state) {
        final uploading = state is PhotoUploading;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      'Upload Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ),

                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Album title...',
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      if (_files.isNotEmpty) ...[
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _files.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (_, i) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _files[i],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (i == 0)
                                  Positioned(
                                    top: 2,
                                    left: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.greenPrimary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Cover',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _files.removeAt(i);
                                      _captions.removeAt(i);
                                    }),
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (_files.length < 10)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.greenPrimary,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: AppTheme.greenBg,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppTheme.greenPrimary,
                                  size: 28,
                                ),
                                Text(
                                  _files.isEmpty
                                      ? 'Tap to add photos'
                                      : 'Add more photos',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.greenPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${10 - _files.length} remaining · max 10MB each',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (uploading) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (state).progress / state.total,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.greenPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uploading ${(state).progress} of ${state.total}...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: uploading ? null : _publish,
                          child: uploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Publish Album',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
