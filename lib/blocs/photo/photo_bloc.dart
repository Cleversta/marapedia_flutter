import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/photo_model.dart';
import '../../repositories/photo_repository.dart';
import '../../services/cache_service.dart';
import '../../services/upload_service.dart';
import 'photo_event.dart';
import 'photo_state.dart';

class PhotoBloc extends Bloc<PhotoEvent, PhotoState> {
  final PhotoRepository _repo;

  PhotoBloc(this._repo) : super(PhotoInitial()) {
    on<PhotoAllLoadRequested>(_onAllLoad);
    on<PhotoAlbumLoadRequested>(_onAlbumLoad);
    on<PhotoMyAlbumsLoadRequested>(_onMyLoad);
    on<PhotoUploadRequested>(_onUpload);
    on<PhotoAlbumDeleteRequested>(_onDeleteAlbum);
    on<PhotoImageDeleteRequested>(_onDeleteImage);
    on<PhotoTogglePublicRequested>(_onTogglePublic);
  }

  // ── All albums ────────────────────────────────────────────────────────────

  Future<void> _onAllLoad(
    PhotoAllLoadRequested e,
    Emitter<PhotoState> emit,
  ) async {
    emit(PhotoLoading());
    try {
      final albums = await _repo.getAllAlbums();
      await CacheService.saveAllAlbums(albums.map((a) => a.toSimpleMap()).toList());
      emit(PhotoAllLoaded(albums));
    } catch (_) {
      final cached = CacheService.loadAllAlbums();
      if (cached != null) {
        final albums = cached.map((j) => PhotoAlbum.fromJson(j)).toList();
        emit(PhotoAllLoaded(albums, isOffline: true));
      } else {
        emit(const PhotoError('No internet connection and no cached data.'));
      }
    }
  }

  // ── Single album ──────────────────────────────────────────────────────────

  Future<void> _onAlbumLoad(
    PhotoAlbumLoadRequested e,
    Emitter<PhotoState> emit,
  ) async {
    emit(PhotoLoading());
    try {
      final album = await _repo.getAlbum(e.id);
      if (album == null) { emit(const PhotoError('Album not found')); return; }
      await CacheService.saveAlbum(e.id, album.toSimpleMap());
      emit(PhotoAlbumLoaded(album));
    } catch (_) {
      final cached = CacheService.loadAlbum(e.id);
      if (cached != null) {
        emit(PhotoAlbumLoaded(PhotoAlbum.fromJson(cached), isOffline: true));
      } else {
        emit(const PhotoError("You're offline and this album isn't cached yet."));
      }
    }
  }

  // ── My albums ─────────────────────────────────────────────────────────────

  Future<void> _onMyLoad(
    PhotoMyAlbumsLoadRequested e,
    Emitter<PhotoState> emit,
  ) async {
    emit(PhotoLoading());
    try {
      final albums = await _repo.getMyAlbums(e.userId);
      await CacheService.saveMyAlbums(e.userId, albums.map((a) => a.toSimpleMap()).toList());
      emit(PhotoMyAlbumsLoaded(albums));
    } catch (_) {
      final cached = CacheService.loadMyAlbums(e.userId);
      if (cached != null) {
        final albums = cached.map((j) => PhotoAlbum.fromJson(j)).toList();
        emit(PhotoMyAlbumsLoaded(albums, isOffline: true));
      } else {
        emit(const PhotoError('No internet connection and no cached data.'));
      }
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<void> _onUpload(
    PhotoUploadRequested e,
    Emitter<PhotoState> emit,
  ) async {
    emit(PhotoUploading(0, e.files.length));
    try {
      final urls = <String>[];
      for (int i = 0; i < e.files.length; i++) {
        final url = await UploadService.uploadImage(e.files[i]);
        urls.add(url);
        emit(PhotoUploading(i + 1, e.files.length));
      }
      final images = List.generate(urls.length, (i) => {
        'url': urls[i],
        'caption': i < e.captions.length ? e.captions[i] : '',
      });
      await _repo.createAlbum(
        title: e.title,
        authorId: e.authorId,
        thumbnailUrl: urls.first,
        images: images,
      );
      emit(PhotoUploadSuccess());
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }

  // ── Delete album ──────────────────────────────────────────────────────────

  Future<void> _onDeleteAlbum(
    PhotoAlbumDeleteRequested e,
    Emitter<PhotoState> emit,
  ) async {
    try {
      await _repo.deleteAlbum(e.id);
      await CacheService.deleteAlbum(e.id);
      final current = state;
      if (current is PhotoAllLoaded) {
        final updated = current.albums.where((a) => a.id != e.id).toList();
        await CacheService.saveAllAlbums(updated.map((a) => a.toSimpleMap()).toList());
        emit(PhotoAllLoaded(updated));
      } else if (current is PhotoMyAlbumsLoaded) {
        final updated = current.albums.where((a) => a.id != e.id).toList();
        emit(PhotoMyAlbumsLoaded(updated));
      }
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }

  // ── Delete single image ───────────────────────────────────────────────────

  Future<void> _onDeleteImage(
    PhotoImageDeleteRequested e,
    Emitter<PhotoState> emit,
  ) async {
    try {
      await _repo.deleteImage(e.imageId);
      final album = await _repo.getAlbum(e.albumId);
      if (album == null) { emit(const PhotoError('Album not found after image deletion')); return; }
      await CacheService.saveAlbum(e.albumId, album.toSimpleMap());
      emit(PhotoAlbumLoaded(album));
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }

  // ── Toggle public ─────────────────────────────────────────────────────────
  // FIX 1: was passing e.current instead of !e.current, so toggle was a no-op.
  // FIX 2: was calling repo but never updating local state, so UI didn't refresh.

  Future<void> _onTogglePublic(
    PhotoTogglePublicRequested e,
    Emitter<PhotoState> emit,
  ) async {
    try {
      await _repo.togglePublic(e.id, e.current);
      final current = state;
      if (current is PhotoAllLoaded) {
        final updated = current.albums.map((a) {
          if (a.id != e.id) return a;
          // FIX: use !e.current (the new toggled value), not e.current
          return PhotoAlbum.fromJson({...a.toSimpleMap(), 'is_public': !e.current});
        }).toList();
        emit(PhotoAllLoaded(updated));
      } else if (current is PhotoMyAlbumsLoaded) {
        final updated = current.albums.map((a) {
          if (a.id != e.id) return a;
          // FIX: use !e.current (the new toggled value), not e.current
          return PhotoAlbum.fromJson({...a.toSimpleMap(), 'is_public': !e.current});
        }).toList();
        emit(PhotoMyAlbumsLoaded(updated));
      }
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }
}