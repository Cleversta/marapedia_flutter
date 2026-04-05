import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/article_model.dart';
import '../../repositories/article_repository.dart';
import 'article_event.dart';
import 'article_state.dart';

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleRepository _repo;

  ArticleBloc(this._repo) : super(ArticleInitial()) {
    on<ArticleHomeLoadRequested>(_onHomeLoad);
    on<ArticleDetailLoadRequested>(_onDetailLoad);
    on<ArticleCategoryLoadRequested>(_onCategoryLoad);
    on<ArticleMyListLoadRequested>(_onMyListLoad);
    on<ArticleDeleteRequested>(_onDelete);
    on<ArticleSearchRequested>(_onSearch);
    on<ArticleAllLoadRequested>(_onAllLoad);         // new
    on<ArticlePublishRequested>(_onPublish);          // new
    on<ArticleFeatureToggleRequested>(_onFeatureToggle); // new
  }

  // ── Home ──────────────────────────────────────────────────────────────────

  Future<void> _onHomeLoad(
    ArticleHomeLoadRequested event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final data = await _repo.fetchHomeData();
      emit(_homeFromMap(data, isOffline: false));
    } catch (_) {
      final cached = _repo.getCachedHomeData();
      if (cached != null) {
        emit(_homeFromMap(cached, isOffline: true));
      } else {
        emit(ArticleError('No internet connection and no cached data.'));
      }
    }
  }

  ArticleHomeLoaded _homeFromMap(
    Map<String, dynamic> data, {
    required bool isOffline,
  }) {
    ArticleModel? featured;
    if (data['featured'] != null) {
      featured = ArticleModel.fromJson(
          Map<String, dynamic>.from(data['featured'] as Map));
    }
    final recent = (data['recent'] as List)
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    final mostViewed = (data['mostViewed'] as List)
        .map((j) => ArticleModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    return ArticleHomeLoaded(
      featured: featured,
      recent: recent,
      mostViewed: mostViewed,
      articleCount: data['articleCount'] as int? ?? 0,
      userCount: data['userCount'] as int? ?? 0,
      isOffline: isOffline,
    );
  }

  // ── Detail ────────────────────────────────────────────────────────────────

  Future<void> _onDetailLoad(
    ArticleDetailLoadRequested event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final article = await _repo.getBySlug(event.slug);
      if (article == null) {
        emit(ArticleError('Article not found.'));
        return;
      }
      _repo.incrementViewCount(article.id).ignore();
      emit(ArticleDetailLoaded(article));
    } catch (_) {
      final cached = _repo.getCachedBySlug(event.slug);
      if (cached != null) {
        emit(ArticleDetailLoaded(cached, isOffline: true));
      } else {
        emit(ArticleError(
            "You're offline and this article isn't cached yet. Open it online first."));
      }
    }
  }

  // ── Category ──────────────────────────────────────────────────────────────

  Future<void> _onCategoryLoad(
    ArticleCategoryLoadRequested event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _repo.getByCategory(event.category);
      emit(ArticleCategoryLoaded(articles));
    } catch (_) {
      final cached = _repo.getCachedByCategory(event.category);
      if (cached != null) {
        emit(ArticleCategoryLoaded(cached, isOffline: true));
      } else {
        emit(ArticleError('No internet connection and no cached data.'));
      }
    }
  }

  // ── My articles ───────────────────────────────────────────────────────────

  Future<void> _onMyListLoad(
    ArticleMyListLoadRequested event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _repo.getMyArticles(event.userId);
      emit(ArticleMyListLoaded(articles));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDelete(
    ArticleDeleteRequested event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _repo.deleteArticle(event.id);
      final current = state;
      if (current is ArticleMyListLoaded) {
        emit(ArticleMyListLoaded(
            current.articles.where((a) => a.id != event.id).toList()));
      } else if (current is ArticleAllLoaded) {
        emit(ArticleAllLoaded(
            current.articles.where((a) => a.id != event.id).toList()));
      }
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> _onSearch(
    ArticleSearchRequested event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _repo.search(event.query);
      emit(ArticleSearchLoaded(articles, event.query));
    } catch (_) {
      emit(ArticleError('Search requires an internet connection.'));
    }
  }

  // ── All articles (admin) ──────────────────────────────────────────────────

  Future<void> _onAllLoad(
    ArticleAllLoadRequested event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _repo.getAllArticles();
      emit(ArticleAllLoaded(articles));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  // ── Publish / Draft ───────────────────────────────────────────────────────

  Future<void> _onPublish(
    ArticlePublishRequested event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _repo.updateArticle(event.id, {
        'status': event.publish ? 'published' : 'draft',
      });
      final current = state;
      if (current is ArticleAllLoaded) {
        final updated = current.articles.map((a) {
          if (a.id != event.id) return a;
          return ArticleModel.fromJson({
            ...a.toSimpleMap(),
            'status': event.publish ? 'published' : 'draft',
          });
        }).toList();
        emit(ArticleAllLoaded(updated));
      } else if (current is ArticleMyListLoaded) {
        final updated = current.articles.map((a) {
          if (a.id != event.id) return a;
          return ArticleModel.fromJson({
            ...a.toSimpleMap(),
            'status': event.publish ? 'published' : 'draft',
          });
        }).toList();
        emit(ArticleMyListLoaded(updated));
      }
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  // ── Feature toggle ────────────────────────────────────────────────────────

  Future<void> _onFeatureToggle(
    ArticleFeatureToggleRequested event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _repo.updateArticle(event.id, {'featured': !event.current});
      final current = state;
      if (current is ArticleAllLoaded) {
        final updated = current.articles.map((a) {
          if (a.id != event.id) return a;
          return ArticleModel.fromJson({
            ...a.toSimpleMap(),
            'featured': !event.current,
          });
        }).toList();
        emit(ArticleAllLoaded(updated));
      }
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }
}