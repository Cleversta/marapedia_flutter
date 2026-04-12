import 'package:equatable/equatable.dart';
import '../../models/article_model.dart';

abstract class ArticleState extends Equatable {
  const ArticleState();
  @override
  List<Object?> get props => [];
}

class ArticleInitial extends ArticleState {}

class ArticleLoading extends ArticleState {}

class ArticleHomeLoaded extends ArticleState {
  final ArticleModel? featured;
  final List<ArticleModel> recent;
  final List<ArticleModel> mostViewed;
  final int articleCount;
  final int userCount;
  final bool isOffline;
  final Map<String, int> categoryCounts; // ← added

  const ArticleHomeLoaded({
    this.featured,
    required this.recent,
    required this.mostViewed,
    required this.articleCount,
    required this.userCount,
    this.isOffline = false,
    this.categoryCounts = const {}, // ← added
  });

  @override
  List<Object?> get props =>
      [featured, recent, mostViewed, articleCount, userCount, isOffline, categoryCounts];
}

class ArticleCategoryLoaded extends ArticleState {
  final List<ArticleModel> articles;
  final bool isOffline;

  const ArticleCategoryLoaded(this.articles, {this.isOffline = false});

  @override
  List<Object?> get props => [articles, isOffline];
}

class ArticleDetailLoaded extends ArticleState {
  final ArticleModel article;
  final bool isOffline;
  final bool isFavorited;

  const ArticleDetailLoaded(
    this.article, {
    this.isOffline = false,
    this.isFavorited = false,
  });

  ArticleDetailLoaded copyWith({bool? isFavorited, bool? isOffline}) =>
      ArticleDetailLoaded(
        article,
        isOffline: isOffline ?? this.isOffline,
        isFavorited: isFavorited ?? this.isFavorited,
      );

  @override
  List<Object?> get props => [article, isOffline, isFavorited];
}

class ArticleSearchLoaded extends ArticleState {
  final List<ArticleModel> results;
  final String query;

  const ArticleSearchLoaded(this.results, this.query);

  @override
  List<Object?> get props => [results, query];
}

class ArticleMyListLoaded extends ArticleState {
  final List<ArticleModel> articles;

  const ArticleMyListLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}

class ArticleAllLoaded extends ArticleState {
  final List<ArticleModel> articles;

  const ArticleAllLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}

class ArticleFavoritesLoaded extends ArticleState {
  final List<ArticleModel> articles;

  const ArticleFavoritesLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}

class ArticleError extends ArticleState {
  final String message;

  const ArticleError(this.message);

  @override
  List<Object?> get props => [message];
}