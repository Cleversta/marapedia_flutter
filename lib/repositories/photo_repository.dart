import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_model.dart';

class PhotoRepository {
  final _db = Supabase.instance.client;

  Future<List<PhotoAlbum>> getAllAlbums() async {
    final res = await _db
        .from('photo_groups')
        .select(
            '*, profiles(username, avatar_url), photo_images(id, url, caption, sort_order)')
        .order('created_at', ascending: false);
    return (res as List)
        .map((j) => PhotoAlbum.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<PhotoAlbum?> getAlbum(String id) async {
    final res = await _db
        .from('photo_groups')
        .select(
            '*, profiles(username, avatar_url), photo_images(id, url, caption, sort_order)')
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return PhotoAlbum.fromJson(Map<String, dynamic>.from(res));
  }

  Future<List<PhotoAlbum>> getMyAlbums(String userId) async {
    final res = await _db
        .from('photo_groups')
        .select('*, photo_images(id, url, caption, sort_order)')
        .eq('author_id', userId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((j) => PhotoAlbum.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<PhotoAlbum> createAlbum({
    required String title,
    required String authorId,
    required String thumbnailUrl,
    required List<Map<String, dynamic>> images,
  }) async {
    final group = await _db
        .from('photo_groups')
        .insert({
          'title': title,
          'author_id': authorId,
          'thumbnail_url': thumbnailUrl,
        })
        .select()
        .single();

    await _db.from('photo_images').insert(
          images
              .mapIndexed(
                (i, img) => {
                  'group_id': group['id'],
                  'url': img['url'],
                  'caption': img['caption'],
                  'sort_order': i,
                  'uploaded_by': authorId,
                },
              )
              .toList(),
        );

    return PhotoAlbum.fromJson(Map<String, dynamic>.from(group));
  }

  Future<void> deleteAlbum(String id) async {
    await _db.from('photo_groups').delete().eq('id', id);
  }

  /// Delete a single photo image by its id
  Future<void> deleteImage(String imageId) async {
    await _db.from('photo_images').delete().eq('id', imageId);
  }

  Future<void> updateAlbumTitle(String id, String title) async {
    await _db.from('photo_groups').update({'title': title}).eq('id', id);
  }

/*************  ✨ Windsurf Command ⭐  *************/
  /// Toggle the is_public field of a photo album by its id.
  ///

/*******  9efb8e6b-099d-48d4-a9e6-a88f325e17be  *******/
  Future<void> togglePublic(String id, bool current) async {
    await _db
        .from('photo_groups')
        .update({'is_public': !current})
        .eq('id', id);
  }
}

extension _Indexed<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int, T) fn) =>
      asMap().entries.map((e) => fn(e.key, e.value)).toList();
}