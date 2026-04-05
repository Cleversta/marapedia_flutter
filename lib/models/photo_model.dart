class PhotoImage {
  final String id;
  final String url;
  final String? caption;
  final int sortOrder;

  const PhotoImage({
    required this.id,
    required this.url,
    this.caption,
    required this.sortOrder,
  });

  factory PhotoImage.fromJson(Map<String, dynamic> json) => PhotoImage(
        id: json['id'] ?? '',
        url: json['url'] ?? '',
        caption: json['caption'],
        sortOrder: json['sort_order'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'caption': caption,
        'sort_order': sortOrder,
      };
}

class PhotoAlbum {
  final String id;
  final String title;
  final String authorId;
  final bool isPublic;
  final String createdAt;
  final String? thumbnailUrl;
  final List<PhotoImage> images;
  final Map<String, String>? profile;

  const PhotoAlbum({
    required this.id,
    required this.title,
    required this.authorId,
    required this.isPublic,
    required this.createdAt,
    this.thumbnailUrl,
    required this.images,
    this.profile,
  });

  factory PhotoAlbum.fromJson(Map<String, dynamic> json) {
    final rawImages = json['photo_images'];
    final images = rawImages is List
        ? (rawImages
                .map((i) =>
                    PhotoImage.fromJson(Map<String, dynamic>.from(i)))
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        : <PhotoImage>[];

    Map<String, String>? profile;
    if (json['profiles'] is Map) {
      profile = Map<String, String>.from(
        (json['profiles'] as Map)
            .map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
      );
    }

    return PhotoAlbum(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      authorId: json['author_id'] ?? '',
      isPublic: json['is_public'] == true,
      createdAt: json['created_at'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      images: images,
      profile: profile,
    );
  }

  /// Serialise to a plain map for Hive caching
  Map<String, dynamic> toSimpleMap() => {
        'id': id,
        'title': title,
        'author_id': authorId,
        'is_public': isPublic,
        'created_at': createdAt,
        'thumbnail_url': thumbnailUrl,
        'profiles': profile,
        'photo_images': images.map((i) => i.toJson()).toList(),
      };
}