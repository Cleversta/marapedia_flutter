import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_state.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/article_card.dart';
import '../../widgets/marapedia_app_bar.dart';
import '../../widgets/shimmer_card.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  const CategoryScreen({super.key, required this.category});
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _activeType = 'all';

  @override
  Widget build(BuildContext context) {
    final cat = Helpers.getCategoryInfo(widget.category);
    return Scaffold(
      appBar: const MarapediaAppBar(),
      body: BlocBuilder<ArticleBloc, ArticleState>(
        builder: (context, state) {
          if (state is ArticleLoading) {
            return Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerCard(),
                ),
              ),
            );
          }

          if (state is ArticleCategoryLoaded) {
            final articles = state.articles;
            final typeOptions =
                AppConstants.articleTypes[widget.category] ?? [];
            final countByType = <String, int>{};
            for (final a in articles) {
              final t = a.articleType ?? 'other';
              countByType[t] = (countByType[t] ?? 0) + 1;
            }
            final typeTabs = typeOptions
                .where((t) => (countByType[t['value']] ?? 0) > 0)
                .toList();

            final filtered = _activeType == 'all'
                ? articles
                : articles.where((a) => a.articleType == _activeType).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat?['icon'] ?? '',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat?['label'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${articles.length} article${articles.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/articles/create?category=${widget.category}',
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Add',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Type tabs
                if (typeTabs.isNotEmpty)
                  Container(
                    height: 42,
                    color: Colors.white,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      children: [
                        _typeTab('all', 'All', articles.length),
                        ...typeTabs.map(
                          (t) => _typeTab(
                            t['value']!,
                            t['label']!,
                            countByType[t['value']] ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1),

                // Articles
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cat?['icon'] ?? '',
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No articles yet',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.push(
                                  '/articles/create?category=${widget.category}',
                                ),
                                child: const Text('Be the first to contribute'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ArticleCard(article: filtered[i]),
                          ),
                        ),
                ),
              ],
            );
          }

          return const Center(child: Text('Error loading articles'));
        },
      ),
    );
  }

  Widget _typeTab(String value, String label, int count) {
    final isActive = _activeType == value;
    return GestureDetector(
      onTap: () => setState(() => _activeType = value),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.greenPrimary : Colors.white,
          border: Border.all(
            color: isActive ? AppTheme.greenPrimary : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
