import 'package:equatable/equatable.dart';
import '../../models/photo_model.dart';

abstract class PhotoState extends Equatable {
  const PhotoState();
  @override List<Object?> get props => [];
}

class PhotoInitial extends PhotoState {}
class PhotoLoading extends PhotoState {}
class PhotoUploading extends PhotoState {
  final int progress;
  final int total;
  const PhotoUploading(this.progress, this.total);
  @override List<Object?> get props => [progress, total];
}
class PhotoAllLoaded extends PhotoState {
  final List<PhotoAlbum> albums;
  const PhotoAllLoaded(this.albums);
  @override List<Object?> get props => [albums];
}
class PhotoAlbumLoaded extends PhotoState {
  final PhotoAlbum album;
  const PhotoAlbumLoaded(this.album);
  @override List<Object?> get props => [album];
}
class PhotoMyAlbumsLoaded extends PhotoState {
  final List<PhotoAlbum> albums;
  const PhotoMyAlbumsLoaded(this.albums);
  @override List<Object?> get props => [albums];
}
class PhotoUploadSuccess extends PhotoState {}
class PhotoError extends PhotoState {
  final String message;
  const PhotoError(this.message);
  @override List<Object?> get props => [message];
}
