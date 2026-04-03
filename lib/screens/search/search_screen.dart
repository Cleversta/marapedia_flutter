import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../widgets/article_card.dart';
import '../../widgets/shimmer_card.dart';

const _ink = Color(0xFF1C1812);
const _inkLight = Color(0xFF8C7E6A);
const _sage = Color(0xFF5A7A5C);
const _sageBg = Color(0xFFEBF1EB);
const _border = Color(0xFFDDD4C0);
const _parchment = Color(0xFFF7F3EC);
const _parchmentDk = Color(0xFFEDE5D4);

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search() {
    if (_ctrl.text.trim().isEmpty) return;
    _focus.unfocus();
    context.read<ArticleBloc>().add(ArticleSearchRequested(_ctrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parchment,
      appBar: AppBar(
        backgroundColor: _parchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: _ink),
        title: Text(
          'Search',
          style: GoogleFonts.lora(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: _inkLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      autofocus: widget.initialQuery == null,
                      autofillHints: const [],
                      enableIMEPersonalizedLearning: false,
                      style: TextStyle(fontSize: 14, color: _ink),
                      decoration: InputDecoration(
                        hintText: 'Search articles, songs, people...',
                        hintStyle: TextStyle(fontSize: 14, color: _inkLight),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  BlocBuilder<ArticleBloc, ArticleState>(
                    builder: (context, state) {
                      final hasQuery = _ctrl.text.isNotEmpty;
                      if (!hasQuery) return const SizedBox(width: 14);
                      return GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.close, color: _inkLight, size: 16),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _sage,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Search',
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(height: 1, color: _border.withOpacity(0.5)),

          // Body
          Expanded(
            child: BlocConsumer<ArticleBloc, ArticleState>(
              listener: (context, state) => setState(() {}),
              builder: (context, state) {
if (state is ArticleLoading) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: ShimmerList(count: 4),
  );
}

                if (state is ArticleSearchLoaded) {
                  if (state.results.isEmpty) {
                    return _buildEmpty(state.query);
                  }
                  return _buildResults(state);
                }

                return _buildIdle();
              },
            ),
          ),
        ],
      ),
    );
  }

Widget _buildIdle() {
  final suggestions = [
    ('Mara history', Icons.history_edu_outlined),
    ('Azao La', Icons.music_note_outlined),
    ('Siaha', Icons.location_on_outlined),
    ('Sawlakia', Icons.person_outline),
    ('Poems', Icons.auto_stories_outlined),
    ('Villages', Icons.cottage_outlined),
  ];

  return SingleChildScrollView(
    // ← key fix: keyboard pushes content up instead of overflowing
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try searching for',
          style: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _inkLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            return GestureDetector(
              onTap: () {
                _ctrl.text = s.$1;
                _search();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.$2, size: 14, color: _sage),
                    const SizedBox(width: 6),
                    Text(
                      s.$1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _sageBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_stories_outlined, color: _sage, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Marapedia',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Search across history, songs, poems, stories, people and places of the Mara.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _inkLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Extra padding so content clears keyboard
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
      ],
    ),
  );
}

  Widget _buildResults(ArticleSearchLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _sageBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  '${state.results.length} result${state.results.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _sage,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'for "${state.query}"',
                style: TextStyle(fontSize: 13, color: _inkLight),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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

  Widget _buildEmpty(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _parchmentDk,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: Icon(Icons.search_off_outlined, color: _inkLight, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nothing matched "$query".\nTry different keywords.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _inkLight, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                context.read<ArticleBloc>().add(ArticleSearchRequested(''));
                _focus.requestFocus();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Clear search',
                  style: TextStyle(
                    fontSize: 13,
                    color: _inkMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _inkMid = Color(0xFF4A4035);