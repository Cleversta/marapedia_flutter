import 'package:equatable/equatable.dart';

abstract class ArticleEvent extends Equatable {
  const ArticleEvent();
  @override
  List<Object?> get props => [];
}

class ArticleHomeLoadRequested extends ArticleEvent {
  const ArticleHomeLoadRequested();
}

class ArticleCategoryLoadRequested extends ArticleEvent {
  final String category;
  const ArticleCategoryLoadRequested(this.category);
  @override
  List<Object?> get props => [category];
}

class ArticleDetailLoadRequested extends ArticleEvent {
  final String slug;
  const ArticleDetailLoadRequested(this.slug);
  @override
  List<Object?> get props => [slug];
}

class ArticleSearchRequested extends ArticleEvent {
  final String query;
  const ArticleSearchRequested(this.query);
  @override
  List<Object?> get props => [query];
}

class ArticleMyListLoadRequested extends ArticleEvent {
  final String userId;
  const ArticleMyListLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ArticleAllLoadRequested extends ArticleEvent {
  const ArticleAllLoadRequested();
}

class ArticleDeleteRequested extends ArticleEvent {
  final String id;
  const ArticleDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ArticlePublishRequested extends ArticleEvent {
  final String id;
  final bool publish;
  const ArticlePublishRequested(this.id, this.publish);
  @override
  List<Object?> get props => [id, publish];
}

class ArticleFeatureToggleRequested extends ArticleEvent {
  final String id;
  final bool current;
  const ArticleFeatureToggleRequested(this.id, this.current);
  @override
  List<Object?> get props => [id, current];
}