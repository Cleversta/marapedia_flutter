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

  const ArticleHomeLoaded({
    this.featured,
    required this.recent,
    required this.mostViewed,
    required this.articleCount,
    required this.userCount,
    this.isOffline = false,
  });

  @override
  List<Object?> get props =>
      [featured, recent, mostViewed, articleCount, userCount, isOffline];
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

  const ArticleDetailLoaded(this.article, {this.isOffline = false});

  @override
  List<Object?> get props => [article, isOffline];
}

class ArticleSearchLoaded extends ArticleState {
  final List<ArticleModel> results; // ← back to results
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

class ArticleError extends ArticleState {
  final String message;

  const ArticleError(this.message);

  @override
  List<Object?> get props => [message];
}