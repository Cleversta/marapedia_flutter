import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../widgets/article_card.dart';
import '../../widgets/shimmer_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
      // No add() here — router fires ArticleSearchRequested on BLoC creation
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search() {
    if (_ctrl.text.trim().isEmpty) return;
    context.read<ArticleBloc>().add(ArticleSearchRequested(_ctrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: widget.initialQuery == null,
          autofillHints: const [],
          enableIMEPersonalizedLearning: false,
          decoration: const InputDecoration(
            hintText: 'Search articles, songs, people...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: BlocBuilder<ArticleBloc, ArticleState>(
        builder: (context, state) {
          if (state is ArticleLoading)
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(),
            );

          if (state is ArticleSearchLoaded) {
            if (state.results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'No results for "${state.query}"',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${state.results.length} result${state.results.length != 1 ? 's' : ''} for "${state.query}"',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.results.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ArticleCard(article: state.results[i]),
                    ),
                  ),
                ),
              ],
            );
          }

          // Idle state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  'Search Mara history, songs, people, and more',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try: "Mara history", "Azao La", "Siaha"',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
