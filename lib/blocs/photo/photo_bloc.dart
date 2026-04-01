import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/photo_repository.dart';
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
    on<PhotoAlbumDeleteRequested>(_onDelete);
    on<PhotoTogglePublicRequested>(_onTogglePublic);
  }

  Future<void> _onAllLoad(PhotoAllLoadRequested e, Emitter<PhotoState> emit) async {
    emit(PhotoLoading());
    try {
      final albums = await _repo.getAllAlbums();
      emit(PhotoAllLoaded(albums));
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }

  Future<void> _onAlbumLoad(PhotoAlbumLoadRequested e, Emitter<PhotoState> emit) async {
    emit(PhotoLoading());
    try {
      final album = await _repo.getAlbum(e.id);
      if (album == null) { emit(const PhotoError('Album not found')); return; }
      emit(PhotoAlbumLoaded(album));
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }

  Future<void> _onMyLoad(PhotoMyAlbumsLoadRequested e, Emitter<PhotoState> emit) async {
    emit(PhotoLoading());
    try {
      final albums = await _repo.getMyAlbums(e.userId);
      emit(PhotoMyAlbumsLoaded(albums));
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }

  Future<void> _onUpload(PhotoUploadRequested e, Emitter<PhotoState> emit) async {
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

  Future<void> _onDelete(PhotoAlbumDeleteRequested e, Emitter<PhotoState> emit) async {
    try {
      await _repo.deleteAlbum(e.id);
      if (state is PhotoAllLoaded) {
        emit(PhotoAllLoaded((state as PhotoAllLoaded).albums.where((a) => a.id != e.id).toList()));
      } else if (state is PhotoMyAlbumsLoaded) {
        emit(PhotoMyAlbumsLoaded((state as PhotoMyAlbumsLoaded).albums.where((a) => a.id != e.id).toList()));
      }
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }

  Future<void> _onTogglePublic(PhotoTogglePublicRequested e, Emitter<PhotoState> emit) async {
    try {
      await _repo.togglePublic(e.id, e.current);
    } catch (err) {
      emit(PhotoError(err.toString()));
    }
  }
}
