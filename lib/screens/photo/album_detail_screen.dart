import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

const _parchment   = Color(0xFFF7F3EC);
const _parchmentDk = Color(0xFFEDE5D4);
const _border      = Color(0xFFDDD4C0);
const _ink         = Color(0xFF1C1812);
const _inkMid      = Color(0xFF4A4035);
const _inkLight    = Color(0xFF8C7E6A);
const _sage        = Color(0xFF5A7A5C);
const _sageBg      = Color(0xFFEBF1EB);
const _sageLight   = Color(0xFFD4E4D4);

class AlbumDetailScreen extends StatefulWidget {
  final String id;
  const AlbumDetailScreen({super.key, required this.id});
  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  int? _lightboxIdx;

  @override
  void initState() {
    super.initState();
    context.read<PhotoBloc>().add(PhotoAlbumLoadRequested(widget.id));
  }

  void _confirmDeleteAlbum(BuildContext context, String albumId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Album',
            style: GoogleFonts.lora(
                fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        content: const Text(
          'Are you sure you want to delete this entire album? All photos will be permanently removed.',
          style: TextStyle(fontSize: 13, color: _inkMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _inkLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<PhotoBloc>()
                  .add(PhotoAlbumDeleteRequested(albumId));
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Album'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteImage(
      BuildContext context, String imageId, String albumId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Photo',
            style: GoogleFonts.lora(
                fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        content: const Text(
          'Remove this photo from the album?',
          style: TextStyle(fontSize: 13, color: _inkMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _inkLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _lightboxIdx = null);
              context.read<PhotoBloc>().add(PhotoImageDeleteRequested(
                    imageId: imageId,
                    albumId: albumId,
                  ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete Photo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoBloc, PhotoState>(
      builder: (context, state) {
        if (state is PhotoLoading) {
          return Scaffold(
            backgroundColor: _parchment,
            appBar: AppBar(
              backgroundColor: _parchment,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16, color: _ink),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: _sage),
            ),
          );
        }

        if (state is PhotoAlbumLoaded) {
          return _buildAlbum(context, state.album,
              isOffline: state.isOffline);
        }

        if (state is PhotoError) {
          return Scaffold(
            backgroundColor: _parchment,
            appBar: AppBar(
              backgroundColor: _parchment,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16, color: _ink),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Text(state.message,
                  style: const TextStyle(color: _inkLight)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _parchment,
          appBar: AppBar(
            backgroundColor: _parchment,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16, color: _ink),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator(color: _sage)),
        );
      },
    );
  }

  Widget _buildAlbum(BuildContext context, PhotoAlbum album,
      {bool isOffline = false}) {
    final images = album.images;
    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated &&
        authState.userId == album.authorId;
    final isAdmin = authState is AuthAuthenticated &&
        authState.profile.isAdmin;
    final canManage = isOwner || isAdmin;

    return Scaffold(
      backgroundColor: _parchment,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: _parchment.withOpacity(0.95),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      size: 16, color: _ink),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  album.title,
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                actions: [
                  if (canManage)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: _inkMid),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: _parchment,
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                size: 16, color: Colors.red[400]),
                            const SizedBox(width: 8),
                            Text('Delete Album',
                                style:
                                    TextStyle(color: Colors.red[400])),
                          ]),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'delete') {
                          _confirmDeleteAlbum(context, album.id);
                        }
                      },
                    ),
                ],
              ),

              // ── Offline banner ───────────────────────────────────────────
              if (isOffline)
                const SliverToBoxAdapter(child: OfflineBanner()),

              // ── Author row ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _sageBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _sageLight),
                        ),
                        child: Center(
                          child: Text(
                            (album.profile?['username'] ?? 'U')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _sage,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.profile?['username'] ?? 'Anonymous',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _inkMid),
                            ),
                            Text(
                              Helpers.formatDate(album.createdAt),
                              style: const TextStyle(
                                  fontSize: 11, color: _inkLight),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _sageBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _sageLight),
                        ),
                        child: Text(
                          '${images.length} photo${images.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: _sage,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Photo grid ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: images.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.photo_outlined,
                                    size: 48, color: _inkLight),
                                const SizedBox(height: 12),
                                const Text('No photos in this album.',
                                    style: TextStyle(color: _inkLight)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final img = images[i];
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _lightboxIdx = i),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Hero(
                                      tag: 'photo-${img.id}',
                                      child: CachedNetworkImage(
                                        imageUrl: img.url,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                            color: _parchmentDk),
                                        errorWidget: (_, __, ___) =>
                                            Container(color: _parchmentDk),
                                      ),
                                    ),
                                    if (i == 0)
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _sage,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text('Cover',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                      ),
                                    // Delete button on photo (owner only)
                                    if (canManage)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _confirmDeleteImage(
                                              context, img.id, album.id),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                size: 13,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: images.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                      ),
              ),
            ],
          ),

          // ── Lightbox ───────────────────────────────────────────────────
          if (_lightboxIdx != null && images.isNotEmpty)
            _Lightbox(
              images: images,
              initialIndex: _lightboxIdx!,
              albumId: album.id,
              canDelete: canManage,
              onClose: () => setState(() => _lightboxIdx = null),
              onIndexChanged: (i) => setState(() => _lightboxIdx = i),
              onDeleteImage: (imageId) =>
                  _confirmDeleteImage(context, imageId, album.id),
            ),
        ],
      ),
    );
  }
}

// ── Lightbox with pinch-to-zoom, swipe, hero ─────────────────────────────────

class _Lightbox extends StatefulWidget {
  final List<PhotoImage> images;
  final int initialIndex;
  final String albumId;
  final bool canDelete;
  final VoidCallback onClose;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<String> onDeleteImage;

  const _Lightbox({
    required this.images,
    required this.initialIndex,
    required this.albumId,
    required this.canDelete,
    required this.onClose,
    required this.onIndexChanged,
    required this.onDeleteImage,
  });

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late PageController _pageCtrl;
  late int _current;
  late TransformationController _transformCtrl;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _current);
    _transformCtrl = TransformationController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
    setState(() => _zoomed = false);
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.images[_current];
    return GestureDetector(
      onTap: _zoomed ? _resetZoom : widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Page view with pinch-to-zoom ──────────────────────────
              PageView.builder(
                controller: _pageCtrl,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: widget.images.length,
                onPageChanged: (i) {
                  _resetZoom();
                  setState(() => _current = i);
                  widget.onIndexChanged(i);
                },
                itemBuilder: (_, i) {
                  final image = widget.images[i];
                  return GestureDetector(
                    onTap: () {}, // prevent close when tapping image
                    child: Center(
                      child: InteractiveViewer(
                        transformationController:
                            i == _current ? _transformCtrl : null,
                        minScale: 1.0,
                        maxScale: 4.0,
                        onInteractionUpdate: (details) {
                          if (i == _current) {
                            final scale =
                                _transformCtrl.value.getMaxScaleOnAxis();
                            setState(() => _zoomed = scale > 1.05);
                          }
                        },
                        onInteractionEnd: (_) {
                          if (i == _current) {
                            final scale =
                                _transformCtrl.value.getMaxScaleOnAxis();
                            setState(() => _zoomed = scale > 1.05);
                          }
                        },
                        child: Hero(
                          tag: 'photo-${image.id}',
                          child: CachedNetworkImage(
                            imageUrl: image.url,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height:
                                MediaQuery.of(context).size.height * 0.75,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                  color: _sage, strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.white54, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── Top bar ───────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 17),
                        ),
                      ),
                      const Spacer(),
                      // Counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_current + 1} / ${widget.images.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      if (widget.canDelete) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              widget.onDeleteImage(img.id),
                          icon: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white, size: 17),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Caption + dot indicators ──────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      if (img.caption != null &&
                          img.caption!.isNotEmpty) ...[
                        Text(
                          img.caption!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Dot indicators
                      if (widget.images.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.images
                              .asMap()
                              .entries
                              .map(
                                (e) => GestureDetector(
                                  onTap: () {
                                    _pageCtrl.animateToPage(
                                      e.key,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width:
                                        e.key == _current ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: e.key == _current
                                          ? Colors.white
                                          : Colors.white38,
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Prev / Next arrows ────────────────────────────────────
              if (_current > 0 && !_zoomed)
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () => _pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      ),
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              if (_current < widget.images.length - 1 && !_zoomed)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () => _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      ),
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),

              // ── Zoom hint ─────────────────────────────────────────────
              if (_zoomed)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _resetZoom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Tap to reset zoom',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
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