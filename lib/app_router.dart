import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'blocs/article/article_bloc.dart';
import 'blocs/article/article_event.dart';
import 'repositories/article_repository.dart';
// Note: ArticleRepository() is instantiated directly in route builders
// because appRouter is a top-level variable — its builder closures run
// with GoRouter's navigator context, not the widget tree context, so
// context.read<ArticleRepository>() would throw ProviderNotFoundException.
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/category_screen.dart';
import 'screens/article/article_detail_screen.dart';
import 'screens/article/create_article_screen.dart';
import 'screens/article/edit_article_screen.dart';
import 'screens/photo/photos_screen.dart';
import 'screens/photo/album_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/editor/editor_screen.dart';
import 'screens/admin/admin_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    GoRoute(
      path: '/category/:name',
      builder: (_, state) {
        final category = state.pathParameters['name']!;
        return BlocProvider(
          create: (_) =>
              ArticleBloc(ArticleRepository())
                ..add(ArticleCategoryLoadRequested(category)),
          child: CategoryScreen(category: category),
        );
      },
    ),

    // /articles/create MUST come before /articles/:slug
    GoRoute(
      path: '/articles/create',
      builder: (_, state) =>
          CreateArticleScreen(category: state.uri.queryParameters['category']),
    ),

    GoRoute(
      path: '/articles/edit/:slug',
      // EditArticleScreen uses ArticleRepository directly, no BLoC needed
      builder: (_, state) =>
          EditArticleScreen(slug: state.pathParameters['slug']!),
    ),

    GoRoute(
      path: '/articles/:slug',
      builder: (_, state) {
        final slug = state.pathParameters['slug']!;
        return BlocProvider(
          create: (_) =>
              ArticleBloc(ArticleRepository())
                ..add(ArticleDetailLoadRequested(slug)),
          child: ArticleDetailScreen(slug: slug),
        );
      },
    ),

    GoRoute(
      path: '/search',
      builder: (_, state) {
        final query = state.uri.queryParameters['q'];
        final bloc = ArticleBloc(ArticleRepository());
        if (query != null && query.isNotEmpty) {
          bloc.add(ArticleSearchRequested(query));
        }
        return BlocProvider(
          create: (_) => bloc,
          child: SearchScreen(initialQuery: query),
        );
      },
    ),

    GoRoute(path: '/photos', builder: (_, __) => const PhotosScreen()),
    GoRoute(
      path: '/photos/:id',
      builder: (_, state) => AlbumDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/my-articles', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/editor', builder: (_, __) => const EditorScreen()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
  ],
);
