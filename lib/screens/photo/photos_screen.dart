import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/photo/photo_bloc.dart';
import '../../blocs/photo/photo_event.dart';
import '../../blocs/photo/photo_state.dart';
import '../../models/photo_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/offline_banner.dart';

// ── Theme tokens (match HomeScreen) ──────────────────────────────────────────
const _parchment   = Color(0xFFF7F3EC);
const _parchmentDk = Color(0xFFEDE5D4);
const _border      = Color(0xFFDDD4C0);
const _ink         = Color(0xFF1C1812);
const _inkMid      = Color(0xFF4A4035);
const _inkLight    = Color(0xFF8C7E6A);
const _sage        = Color(0xFF5A7A5C);
const _sageBg      = Color(0xFFEBF1EB);
const _sageLight   = Color(0xFFD4E4D4);

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PhotoBloc>().add(const PhotoAllLoadRequested());
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
    ).then((_) {
      // After upload sheet closes, always reload to show new album
      if (mounted) {
        context.read<PhotoBloc>().add(const PhotoAllLoadRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parchment,
      appBar: AppBar(
        backgroundColor: _parchment,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: _ink),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text('📷', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Photo Gallery',
              style: GoogleFonts.lora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<PhotoBloc, PhotoState>(
        builder: (context, state) {
          if (state is PhotoLoading) return _buildShimmer();

          if (state is PhotoAllLoaded) {
            return Column(
              children: [
                if (state.isOffline) const OfflineBanner(),
                Expanded(
                  child: state.albums.isEmpty
                      ? _buildEmpty(context)
                      : RefreshIndicator(
                          color: _sage,
                          onRefresh: () async => context
                              .read<PhotoBloc>()
                              .add(const PhotoAllLoadRequested()),
                          child: CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, i) =>
                                        _AlbumCard(album: state.albums[i]),
                                    childCount: state.albums.length,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.72,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          }

          if (state is PhotoError) {
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
                    Text('Could not load photos',
                        style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _ink)),
                    const SizedBox(height: 6),
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 13, color: _inkLight)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context
                          .read<PhotoBloc>()
                          .add(const PhotoAllLoadRequested()),
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

          return _buildShimmer();
        },
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (_, authState) {
          if (authState is AuthAuthenticated) {
            return FloatingActionButton.extended(
              onPressed: () => _showUploadModal(authState.userId),
              backgroundColor: _sage,
              elevation: 2,
              icon: const Icon(Icons.add_photo_alternate_outlined,
                  color: Colors.white, size: 18),
              label: Text(
                'Upload',
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

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _parchmentDk,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.photo_library_outlined,
                  size: 36, color: _inkLight),
            ),
            const SizedBox(height: 16),
            Text('No photos yet',
                style: GoogleFonts.lora(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 8),
            const Text(
              'Be the first to share photos of Mara life',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _inkLight, height: 1.5),
            ),
            const SizedBox(height: 24),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, authState) {
                if (authState is AuthAuthenticated) {
                  return ElevatedButton.icon(
                    onPressed: () => _showUploadModal(authState.userId),
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Upload First Photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sage,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
                return ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sage,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Login to Upload'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: _parchmentDk,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
      ),
    );
  }
}

// ── Album card ────────────────────────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              child: Stack(
                children: [
                  cover != null
                      ? Hero(
                          tag: 'album-cover-${album.id}',
                          child: CachedNetworkImage(
                            imageUrl: cover.url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: _parchmentDk),
                            errorWidget: (_, __, ___) =>
                                Container(color: _parchmentDk),
                          ),
                        )
                      : Container(
                          color: _parchmentDk,
                          child: const Center(
                            child: Icon(Icons.photo_library_outlined,
                                size: 36, color: _inkLight),
                          ),
                        ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Photo count badge
                  if (album.images.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_outlined,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '${album.images.length}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _sageBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _sageLight),
                        ),
                        child: Center(
                          child: Text(
                            (album.profile?['username'] ?? 'A')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: _sage),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          album.profile?['username'] ?? 'Anonymous',
                          style:
                              const TextStyle(fontSize: 10, color: _inkLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Helpers.timeAgo(album.createdAt),
                        style:
                            const TextStyle(fontSize: 10, color: _inkLight),
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
    context.read<PhotoBloc>().add(PhotoUploadRequested(
          title: _titleCtrl.text.trim(),
          authorId: widget.userId,
          files: _files,
          captions: _captions,
        ));
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
            color: _parchment,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Text('Upload Photos',
                        style: GoogleFonts.lora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: _inkMid),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(_error,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red[700])),
                        ),

                      // Title
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: TextField(
                          controller: _titleCtrl,
                          style: GoogleFonts.lora(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _ink),
                          decoration: const InputDecoration(
                            hintText: 'Album title...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Preview strip
                      if (_files.isNotEmpty) ...[
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _files.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(_files[i],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover),
                                ),
                                if (i == 0)
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _sage,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Cover',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _files.removeAt(i);
                                      _captions.removeAt(i);
                                    }),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close,
                                          size: 11, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add photos button
                      if (_files.length < 10)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _sageBg,
                              border:
                                  Border.all(color: _sageLight, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: _sage,
                                    size: 26),
                                const SizedBox(height: 4),
                                Text(
                                  _files.isEmpty
                                      ? 'Tap to add photos'
                                      : 'Add more photos',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _sage,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${10 - _files.length} remaining · max 10MB each',
                                  style: const TextStyle(
                                      fontSize: 10, color: _inkLight),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Progress
                      if (uploading) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: state.progress / state.total,
                            backgroundColor: _border,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_sage),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Uploading ${state.progress} of ${state.total}...',
                          style: const TextStyle(
                              fontSize: 11, color: _inkLight),
                        ),
                      ],

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: uploading ? null : _publish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _sage,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: uploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('Publish Album',
                                  style: GoogleFonts.lora(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
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