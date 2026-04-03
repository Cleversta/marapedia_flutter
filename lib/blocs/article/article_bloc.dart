import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marapedia_flutter/models/article_model.dart';
import '../../repositories/article_repository.dart';
import 'article_event.dart';
import 'article_state.dart';

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleRepository _repo;

  ArticleBloc(this._repo) : super(ArticleInitial()) {
    on<ArticleHomeLoadRequested>(_onHomeLoad);
    on<ArticleCategoryLoadRequested>(_onCategoryLoad);
    on<ArticleDetailLoadRequested>(_onDetailLoad);
    on<ArticleSearchRequested>(_onSearch);
    on<ArticleMyListLoadRequested>(_onMyList);
    on<ArticleAllLoadRequested>(_onAllLoad);
    on<ArticleDeleteRequested>(_onDelete);
    on<ArticlePublishRequested>(_onPublish);
    on<ArticleFeatureToggleRequested>(_onFeatureToggle);
  }

  Future<void> _onHomeLoad(
    ArticleHomeLoadRequested e,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final results = await Future.wait([
        _repo.getFeatured(),
        _repo.getRecentArticles(limit: 6),
        _repo.getMostViewed(limit: 6),
        _repo.getStats(),
      ]);
      emit(
        ArticleHomeLoaded(
          featured: results[0] as dynamic,
          recent: results[1] as dynamic,
          mostViewed: results[2] as dynamic,
          articleCount: (results[3] as Map)['articles'] as int,
          userCount: (results[3] as Map)['users'] as int,
        ),
      );
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onCategoryLoad(
    ArticleCategoryLoadRequested e,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _repo.getByCategory(e.category);
      emit(ArticleCategoryLoaded(articles, e.category));
    } catch (err) {
      emit(ArticleError(err.toString()));
    }
  }

  Future<void> _onDetailLoad(
    ArticleDetailLoadRequested e,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final article = await _repo.getBySlug(e.slug);
      if (article == null) {
        emit(const ArticleError('Article not found'));
        return;
      }
      await _repo.incrementViewCount(article.id);
      emit(ArticleDetailLoaded(article));
    } catch (err) {
      emit(ArticleError(err.toString()));
    }
  }

  Future<void> _onSearch(
    ArticleSearchRequested e,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final results = await _repo.search(e.query);
      emit(ArticleSearchLoaded(results, e.query));
    } catch (err) {
      emit(ArticleError(err.toString()));
    }
  }

  Future<void> _onMyList(
    ArticleMyListLoadRequested e,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _repo.getMyArticles(e.userId);
      emit(ArticleMyListLoaded(articles));
    } catch (err) {
      emit(ArticleError(err.toString()));
    }
  }

  Future<void> _onAllLoad(
    ArticleAllLoadRequested e,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _repo.getAllArticles();
      emit(ArticleAllLoaded(articles));
    } catch (err) {
      emit(ArticleError(err.toString()));
    }
  }

  Future<void> _onDelete(
    ArticleDeleteRequested e,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _repo.deleteArticle(e.id);
      if (state is ArticleMyListLoaded) {
        final current = (state as ArticleMyListLoaded).articles
            .where((a) => a.id != e.id)
            .toList();
        emit(ArticleMyListLoaded(current));
      } else if (state is ArticleAllLoaded) {
        final current = (state as ArticleAllLoaded).articles
            .where((a) => a.id != e.id)
            .toList();
        emit(ArticleAllLoaded(current));
      }
    } catch (err) {
      emit(ArticleError(err.toString()));
    }
  }

  Future<void> _onPublish(
    ArticlePublishRequested e,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _repo.updateArticle(e.id, {
        'status': e.publish ? 'published' : 'draft',
      });
      if (state is ArticleAllLoaded) {
        final updated = (state as ArticleAllLoaded).articles
            .map(
              (a) => a.id == e.id
                  ? ArticleModel.fromJson({
                      ...a.toSimpleMap(),
                      'status': e.publish ? 'published' : 'draft',
                    })
                  : a,
            )
            .toList();
        emit(ArticleAllLoaded(updated));
      }
    } catch (err) {
      emit(ArticleError(err.toString()));
    }
  }

  Future<void> _onFeatureToggle(
    ArticleFeatureToggleRequested e,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _repo.updateArticle(e.id, {'featured': !e.current});
    } catch (err) {
      emit(ArticleError(err.toString()));
    }
  }
}
