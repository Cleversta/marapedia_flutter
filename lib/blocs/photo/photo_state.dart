import 'package:equatable/equatable.dart';
import '../../models/photo_model.dart';

abstract class PhotoState extends Equatable {
  const PhotoState();
  @override
  List<Object?> get props => [];
}

class PhotoInitial extends PhotoState {}

class PhotoLoading extends PhotoState {}

class PhotoUploading extends PhotoState {
  final int progress;
  final int total;
  const PhotoUploading(this.progress, this.total);
  @override
  List<Object?> get props => [progress, total];
}

class PhotoAllLoaded extends PhotoState {
  final List<PhotoAlbum> albums;
  final bool isOffline;
  const PhotoAllLoaded(this.albums, {this.isOffline = false});
  @override
  List<Object?> get props => [albums, isOffline];
}

class PhotoAlbumLoaded extends PhotoState {
  final PhotoAlbum album;
  final bool isOffline;
  const PhotoAlbumLoaded(this.album, {this.isOffline = false});
  @override
  List<Object?> get props => [album, isOffline];
}

class PhotoMyAlbumsLoaded extends PhotoState {
  final List<PhotoAlbum> albums;
  final bool isOffline;
  const PhotoMyAlbumsLoaded(this.albums, {this.isOffline = false});
  @override
  List<Object?> get props => [albums, isOffline];
}

class PhotoUploadSuccess extends PhotoState {}

class PhotoAlbumDeleted extends PhotoState {}

class PhotoError extends PhotoState {
  final String message;
  const PhotoError(this.message);
  @override
  List<Object?> get props => [message];
}