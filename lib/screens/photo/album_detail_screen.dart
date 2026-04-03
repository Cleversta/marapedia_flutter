import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/photo/photo_bloc.dart';
import '../../blocs/photo/photo_event.dart';
import '../../blocs/photo/photo_state.dart';
import '../../models/photo_model.dart';
import '../../utils/helpers.dart';

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

  /*************  ✨ Windsurf Command ⭐  *************/
  /// Builds the widget tree for the album detail screen.
  ///
  /// If [state] is [PhotoLoading], shows a loading indicator.
  /// If [state] is [PhotoAlbumLoaded], shows the album detail.
  /// If [state] is neither of the above, shows a "not found" message.
  /// *****  6cdb3016-19f3-43ab-b528-2330bdb40f36  ******
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoBloc, PhotoState>(
      builder: (context, state) {
        if (state is PhotoLoading) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PhotoAlbumLoaded) return _buildAlbum(state.album);

        return Scaffold(
          appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
          body: const Center(child: Text('Album not found')),
        );
      },
    );
  }

  Widget _buildAlbum(PhotoAlbum album) {
    final images = album.images;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          album.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFFDCFCE7),
                      child: Text(
                        (album.profile?['username'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      album.profile?['username'] ?? 'Anonymous',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Text(' · ', style: TextStyle(color: Colors.grey)),
                    Text(
                      Helpers.formatDate(album.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    Text(
                      '${images.length} photo${images.length != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Grid
              Expanded(
                child: images.isEmpty
                    ? const Center(
                        child: Text(
                          'No photos in this album.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                        itemCount: images.length,
                        itemBuilder: (_, i) {
                          final img = images[i];
                          final isFirst = i == 0;
                          return GestureDetector(
                            onTap: () => setState(() => _lightboxIdx = i),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: img.url,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) =>
                                      Container(color: Colors.grey[200]),
                                ),
                                if (isFirst)
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF15803D),
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
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Lightbox
          if (_lightboxIdx != null) _buildLightbox(images),
        ],
      ),
    );
  }

  Widget _buildLightbox(List<PhotoImage> images) {
    return GestureDetector(
      onTap: () => setState(() => _lightboxIdx = null),
      child: Container(
        color: Colors.black.withOpacity(0.93),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: images[_lightboxIdx!].url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.72,
                      ),
                      if (images[_lightboxIdx!].caption != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          images[_lightboxIdx!].caption!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '${_lightboxIdx! + 1} / ${images.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => setState(() => _lightboxIdx = null),
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              if (_lightboxIdx! > 0)
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () =>
                          setState(() => _lightboxIdx = _lightboxIdx! - 1),
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_lightboxIdx! < images.length - 1)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () =>
                          setState(() => _lightboxIdx = _lightboxIdx! + 1),
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              // Dot indicators
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images
                      .asMap()
                      .entries
                      .map(
                        (e) => GestureDetector(
                          onTap: () => setState(() => _lightboxIdx = e.key),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: e.key == _lightboxIdx ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: e.key == _lightboxIdx
                                  ? Colors.white
                                  : Colors.white30,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
