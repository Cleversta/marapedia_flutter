import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/article_model.dart';
import '../../repositories/article_repository.dart';
import '../../services/upload_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/song_editor.dart';
import '../../widgets/rich_editor.dart';

enum _EditorType { rich, song, poem }

_EditorType _editorType(String category) {
  if (category == 'songs') return _EditorType.song;
  if (category == 'poems') return _EditorType.poem;
  return _EditorType.rich;
}

class EditArticleScreen extends StatefulWidget {
  final String slug;
  const EditArticleScreen({super.key, required this.slug});
  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  ArticleModel? _article;
  bool _loading = true;
  bool _saving = false;
  String _error = '';
  String _success = '';

  String _currentLang = 'mara';
  String _articleType = '';
  bool _featured = false;

  final Map<String, TextEditingController> _titleCtrls = {};
  final Map<String, String> _contentMap = {};
  final TextEditingController _sourceUrlCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _existingImages = [];
  final List<File> _newImages = [];

  bool get _isSong => _article?.category == 'songs';

  @override

  void initState() {
    super.initState();
    for (final lang in ['mara', 'english', 'myanmar', 'mizo']) {
      _titleCtrls[lang] = TextEditingController();
      _contentMap[lang] = '';
    }
    _loadArticle();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _titleCtrls.values) c.dispose();
    _sourceUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadArticle() async {
    final repo = ArticleRepository();
    final article = await repo.getBySlug(widget.slug);
    if (article == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _article = article;
      _articleType = article.articleType ?? '';
      _featured = article.featured;
      _sourceUrlCtrl.text = article.sourceUrl ?? '';
      _existingImages = article.images
          .map((i) => {'url': i.url, 'caption': i.caption ?? ''})
          .toList();
      for (final t in article.translations) {
        _titleCtrls[t.language]?.text = t.title;
        _contentMap[t.language] = t.content;
      }
      _loading = false;
    });
  }

  bool _hasContent(String lang) =>
      (_titleCtrls[lang]?.text.trim().isNotEmpty ?? false) ||
      (_contentMap[lang]?.isNotEmpty ?? false);

  Map<String, dynamic> _parseSongMeta(String html) {
    final m = RegExp(r'<!--meta:(.*?)-->').firstMatch(html);
    if (m == null) return {};
    try {
      return jsonDecode(m.group(1)!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _save() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || _article == null) return;

    setState(() {
      _saving = true;
      _error = '';
      _success = '';
    });

    try {
      final repo = ArticleRepository();
      final allImages = List<Map<String, dynamic>>.from(_existingImages);
      for (final f in _newImages) {
        final url = await UploadService.uploadImage(f);
        allImages.add({'url': url, 'caption': ''});
      }

      String? singer;
      String? songwriter;
      if (_isSong) {
        for (final lang in ['mara', 'english', 'myanmar', 'mizo']) {
          final content = _contentMap[lang] ?? '';
          if (content.isEmpty) continue;
          final meta = _parseSongMeta(content);
          singer ??= (meta['singer'] as String?)?.isNotEmpty == true ? meta['singer'] as String : null;
          songwriter ??= (meta['writer'] as String?)?.isNotEmpty == true ? meta['writer'] as String : null;
        }
      }

      await repo.updateArticle(_article!.id, {
        'article_type': _articleType.isEmpty ? null : _articleType,
        'thumbnail_url': allImages.isNotEmpty ? allImages.first['url'] : null,
        'featured': _featured,
        'source_url': _sourceUrlCtrl.text.trim().isEmpty ? null : _sourceUrlCtrl.text.trim(),
        'singer': singer,
        'songwriter': songwriter,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await repo.insertImages(_article!.id, allImages, authState.userId);

      for (final lang in ['mara', 'english', 'myanmar', 'mizo']) {
        final title = _titleCtrls[lang]?.text.trim() ?? '';
        if (title.isEmpty) continue;
        final content = _contentMap[lang] ?? '';
        if (content.isEmpty) continue;
        await repo.upsertTranslation(
          articleId: _article!.id,
          language: lang,
          title: title,
          content: content,
          excerpt: Helpers.makeExcerpt(content),
          updatedBy: authState.userId,
          slug: _article!.slug,
        );
      }

      setState(() {
        _saving = false;
        _success = 'Saved!';
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) context.pop();
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_article == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('Article not found')),
      );
    }

    final typeOptions = AppConstants.articleTypes[_article!.category] ?? [];
    final edType = _editorType(_article!.category);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(edType),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
             bottom: keyboardHeight > 0 ? 70 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error.isNotEmpty) _errorBanner(),

              // ── Type (compact, inside meta card) ─────────────────────────
              _compactMeta(typeOptions),

              // ── Media row: image icon + source url ────────────────────────
              _mediaRow(keyboardHeight),

              // ── Featured toggle ───────────────────────────────────────────
              _featuredToggle(),

              // ── Language tabs + Title + Body (unified card) ───────────────
              _sectionLabel('CONTENT'),
              _contentCard(keyboardHeight, edType),

              // ── Language completion ───────────────────────────────────────
              _langCompletion(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(_EditorType edType) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF1A1A2E)),
        onPressed: () => context.pop(),
      ),
      title: Text(
        edType == _EditorType.song ? 'Edit Song' : 'Edit Article',
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.2),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE8E8EC)),
      ),
      actions: [
        if (_success.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              child: Text(_success,
                  style: const TextStyle(
                      color: AppTheme.greenPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.greenPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
              ),
              child: const Text('Save',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _errorBanner() => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child:
            Text(_error, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
      );

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1.2,
          ),
        ),
      );

  // ── Compact Type meta block (no category picker in edit) ──────────────────
  Widget _compactMeta(List<Map<String, String>> typeOptions) {
    if (typeOptions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8EC)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TYPE',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB0B7C3),
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: typeOptions
                    .map((t) => _miniChip(
                          label: t['label']!,
                          active: _articleType == t['value'],
                          onTap: () => setState(() => _articleType =
                              _articleType == t['value'] ? '' : t['value']!),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppTheme.greenPrimary : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppTheme.greenPrimary : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      );

  // ── Media row: image icon (left) + source URL (right) ─────────────────────
  Widget _mediaRow(double keyboardHeight) {
    final totalImages = _existingImages.length + _newImages.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8EC)),
        ),
        child: Row(
          children: [
            // Image icon button
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickMultiImage();
                setState(() =>
                    _newImages.addAll(picked.map((x) => File(x.path))));
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  border:
                      Border(right: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      totalImages == 0
                          ? Icons.add_photo_alternate_outlined
                          : Icons.photo_library_outlined,
                      size: 18,
                      color: totalImages == 0
                          ? const Color(0xFF9CA3AF)
                          : AppTheme.greenPrimary,
                    ),
                    if (totalImages > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.greenPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$totalImages',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Source URL field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: _sourceUrlCtrl,
                  keyboardType: TextInputType.url,
                  scrollPadding:
                      EdgeInsets.only(bottom: keyboardHeight + 80),
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF374151)),
                  decoration: const InputDecoration(
                    hintText: 'Source URL (optional)',
                    hintStyle: TextStyle(
                        fontSize: 12.5, color: Color(0xFFD1D5DB)),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            // Clear button
            ValueListenableBuilder(
              valueListenable: _sourceUrlCtrl,
              builder: (_, __, ___) => _sourceUrlCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () => setState(() => _sourceUrlCtrl.clear()),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.close,
                            size: 13, color: Color(0xFFD1D5DB)),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Featured toggle ────────────────────────────────────────────────────────
  Widget _featuredToggle() => Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8EC)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.star_outline,
                size: 15, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Featured article',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151)),
              ),
            ),
            Switch.adaptive(
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
              activeColor: AppTheme.greenPrimary,
            ),
          ],
        ),
      );

  // ── Unified content card: lang tabs + title + divider + editor ─────────────
  Widget _contentCard(double keyboardHeight, _EditorType edType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language tabs
            _langTabs(),

            // Title field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                controller: _titleCtrls[_currentLang],
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.3),
                scrollPadding:
                    EdgeInsets.only(bottom: keyboardHeight + 80),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: edType == _EditorType.song
                      ? 'Song title...'
                      : 'Article title...',
                  hintStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD1D5DB),
                      height: 1.3),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // Thin divider between title and body
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
            ),

            // Editor body
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: switch (edType) {
                _EditorType.song => Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: SongEditor(
                      key: ValueKey('song_$_currentLang'),
                      content: _contentMap[_currentLang] ?? '',
                      language: _currentLang,
                      onChange: (val) =>
                          setState(() => _contentMap[_currentLang] = val),
                    ),
                  ),
                _ => Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: RichEditorWidget(
                      pageScrollController: _scrollController,
                      key: ValueKey(
                          'rich_${edType.name}_$_currentLang'),
                      content: _contentMap[_currentLang] ?? '',
                      onChange: (html) => setState(
                          () => _contentMap[_currentLang] = html),
                      placeholder: edType == _EditorType.poem
                          ? 'Write poem here...'
                          : 'Write your content here...',
                    ),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Language tabs (inside the card, no outer border) ──────────────────────
  Widget _langTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      child: Row(
        children: ['mara', 'english', 'myanmar', 'mizo'].map((lang) {
          final isActive = _currentLang == lang;
          final hasCont = _hasContent(lang);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentLang = lang),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? AppTheme.greenPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasCont
                            ? AppTheme.greenPrimary
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppConstants.languageLabels[lang] ?? lang,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? AppTheme.greenPrimary
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Language completion ────────────────────────────────────────────────────
  Widget _langCompletion() => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8EC)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LANGUAGE COMPLETION',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              children:
                  ['mara', 'english', 'myanmar', 'mizo'].map((lang) {
                final done = _hasContent(lang);
                final isActive = _currentLang == lang;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentLang = lang),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: lang == 'mizo' ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: done
                            ? const Color(0xFFF0FDF4)
                            : Colors.white,
                        border: Border.all(
                          color: isActive
                              ? AppTheme.greenPrimary
                              : done
                                  ? const Color(0xFFBBF7D0)
                                  : const Color(0xFFE5E7EB),
                          width: isActive ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppConstants.languageLabels[lang] ?? lang,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: done
                                  ? AppTheme.greenDark
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            done ? '✓ Done' : 'Empty',
                            style: TextStyle(
                              fontSize: 9,
                              color: done
                                  ? AppTheme.greenPrimary
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
}