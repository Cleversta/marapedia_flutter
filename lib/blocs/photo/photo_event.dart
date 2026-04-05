import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class PhotoEvent extends Equatable {
  const PhotoEvent();
  @override
  List<Object?> get props => [];
}

class PhotoAllLoadRequested extends PhotoEvent {
  const PhotoAllLoadRequested();
}

class PhotoAlbumLoadRequested extends PhotoEvent {
  final String id;
  const PhotoAlbumLoadRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class PhotoMyAlbumsLoadRequested extends PhotoEvent {
  final String userId;
  const PhotoMyAlbumsLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class PhotoUploadRequested extends PhotoEvent {
  final String title;
  final String authorId;
  final List<File> files;
  final List<String> captions;
  const PhotoUploadRequested({
    required this.title,
    required this.authorId,
    required this.files,
    required this.captions,
  });
  @override
  List<Object?> get props => [title, authorId];
}

class PhotoAlbumDeleteRequested extends PhotoEvent {
  final String id;
  const PhotoAlbumDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

/// Delete a single photo image from an album
class PhotoImageDeleteRequested extends PhotoEvent {
  final String imageId;
  final String albumId;
  const PhotoImageDeleteRequested({required this.imageId, required this.albumId});
  @override
  List<Object?> get props => [imageId, albumId];
}

class PhotoTogglePublicRequested extends PhotoEvent {
  final String id;
  final bool current;
  const PhotoTogglePublicRequested(this.id, this.current);
  @override
  List<Object?> get props => [id, current];
}