import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_router.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/article/article_bloc.dart';
import 'blocs/photo/photo_bloc.dart';
import 'repositories/auth_repository.dart';
import 'repositories/article_repository.dart';
import 'repositories/photo_repository.dart';
import 'services/cache_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await CacheService.init();

  runApp(const MarapediaApp());
}

class MarapediaApp extends StatelessWidget {
  const MarapediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => ArticleRepository()),
        RepositoryProvider(create: (_) => PhotoRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (ctx) =>
                AuthBloc(ctx.read<AuthRepository>())..add(AuthStarted()),
          ),
          BlocProvider<ArticleBloc>(
            create: (ctx) => ArticleBloc(ctx.read<ArticleRepository>()),
          ),
          BlocProvider<PhotoBloc>(
            create: (ctx) => PhotoBloc(ctx.read<PhotoRepository>()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Marapedia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          routerConfig: appRouter,
          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
        ),
      ),
    );
  }
}