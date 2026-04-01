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
import '../../widgets/song_editor.dart'; // <-- import SongEditor

// ── Editor type detection (mirrors getEditorType() in Next.js EditArticlePage)
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

  // Plain title controllers per language
  final Map<String, TextEditingController> _titleCtrls = {};
  // Raw HTML content per language (for song/poem editors driven by callbacks)
  final Map<String, String> _contentMap = {};
  // Plain-text content controllers (only used for 'rich' editor)
  final Map<String, TextEditingController> _richCtrls = {};

  List<Map<String, dynamic>> _existingImages = [];
  final List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    for (final lang in ['mara', 'english', 'myanmar', 'mizo']) {
      _titleCtrls[lang] = TextEditingController();
      _richCtrls[lang] = TextEditingController();
      _contentMap[lang] = '';
    }
    _loadArticle();
  }

  @override
  void dispose() {
    for (final c in _titleCtrls.values) c.dispose();
    for (final c in _richCtrls.values) c.dispose();
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
      _existingImages = article.images
          .map((i) => {'url': i.url, 'caption': i.caption ?? ''})
          .toList();

      for (final t in article.translations) {
        _titleCtrls[t.language]?.text = t.title;
        _contentMap[t.language] = t.content;
        // Rich editor also gets the raw content (HTML stripped for plain editing)
        _richCtrls[t.language]?.text = _toPlain(t.content);
      }
      _loading = false;
    });
  }

  // Strip tags for the plain rich text textarea fallback
  String _toPlain(String html) {
    if (!html.contains('<') && !html.contains('<!--')) return html;
    return html
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<\/p>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  bool _hasContent(String lang) =>
      (_titleCtrls[lang]?.text.trim().isNotEmpty ?? false) ||
      (_contentMap[lang]?.isNotEmpty ?? false);

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

      await repo.updateArticle(_article!.id, {
        'article_type': _articleType.isEmpty ? null : _articleType,
        'thumbnail_url': allImages.isNotEmpty ? allImages.first['url'] : null,
        'featured': _featured,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await repo.insertImages(_article!.id, allImages, authState.userId);

      final type = _editorType(_article!.category);

      for (final lang in ['mara', 'english', 'myanmar', 'mizo']) {
        final title = _titleCtrls[lang]?.text.trim() ?? '';
        if (title.isEmpty) continue;

        final String content;
        if (type == _EditorType.song || type == _EditorType.poem) {
          content = _contentMap[lang] ?? '';
        } else {
          // Rich: wrap plain text in <p> tags
          final plain = _richCtrls[lang]?.text.trim() ?? '';
          content = plain
              .split('\n')
              .where((l) => l.isNotEmpty)
              .map((l) => '<p>$l</p>')
              .join('');
        }
        if (content.isEmpty) continue;

        await repo.upsertTranslation(
          articleId: _article!.id,
          language: lang,
          title: title,
          content: content,
          excerpt: Helpers.makeExcerpt(content),
          updatedBy: authState.userId,
        );
      }

      setState(() {
        _saving = false;
        _success = 'Saved!';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _success = '');
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          edType == _EditorType.song ? 'Edit Song' : 'Edit Article',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8E8EC)),
        ),
        actions: [
          if (_success.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  _success,
                  style: const TextStyle(
                    color: AppTheme.greenPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.greenPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error
            if (_error.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _error,
                  style: TextStyle(fontSize: 13, color: Colors.red[700]),
                ),
              ),

            // ── Article type ───────────────────────────────────────────────
            if (typeOptions.isNotEmpty) ...[
              _sectionLabel('Type'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: typeOptions.map((t) {
                    final isActive = _articleType == t['value'];
                    return GestureDetector(
                      onTap: () => setState(
                        () => _articleType = isActive ? '' : t['value']!,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.greenPrimary
                              : Colors.white,
                          border: Border.all(
                            color: isActive
                                ? AppTheme.greenPrimary
                                : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t['label']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isActive ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // ── Images ────────────────────────────────────────────────────
            _sectionLabel('Images'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._existingImages.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      e.value['url'],
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _existingImages.removeAt(e.key),
                                      ),
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ..._newImages.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      e.value,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _newImages.removeAt(e.key),
                                      ),
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    left: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      color: Colors.orange,
                                      child: const Text(
                                        'New',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickMultiImage();
                      setState(
                        () =>
                            _newImages.addAll(picked.map((x) => File(x.path))),
                      );
                    },
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 16,
                    ),
                    label: const Text('Add Images'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.greenPrimary,
                      side: const BorderSide(color: AppTheme.greenPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Featured ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Featured article',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Switch(
                    value: _featured,
                    onChanged: (v) => setState(() => _featured = v),
                    activeColor: AppTheme.greenPrimary,
                  ),
                ],
              ),
            ),

            // ── Language tabs ─────────────────────────────────────────────
            _sectionLabel('Content'),
            _langTabs(),

            // ── Title ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _titleCtrls[_currentLang],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: edType == _EditorType.song
                      ? 'Song title...'
                      : 'Article title...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
            const SizedBox(height: 8),

            // ── Editor area ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _buildEditor(edType),
            ),

            // ── Language completion strip ──────────────────────────────────
            _langCompletion(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Editor switcher (mirrors getEditorType logic in Next.js) ─────────────

  Widget _buildEditor(_EditorType type) {
    switch (type) {
      case _EditorType.song:
        return SongEditor(
          key: ValueKey('song_$_currentLang'),
          content: _contentMap[_currentLang] ?? '',
          language: _currentLang,
          onChange: (html) => setState(() => _contentMap[_currentLang] = html),
        );
      case _EditorType.poem:
      // Poem uses same plain textarea for now (PoemEditor can be swapped in)
      case _EditorType.rich:
        return TextField(
          controller: _richCtrls[_currentLang],
          maxLines: null,
          minLines: 15,
          style: const TextStyle(fontSize: 15, height: 1.8),
          decoration: const InputDecoration(
            hintText: 'Write your content here...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        );
    }
  }

  // ── Language tabs ─────────────────────────────────────────────────────────

  Widget _langTabs() => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
    ),
    child: Row(
      children: ['mara', 'english', 'myanmar', 'mizo'].map((lang) {
        final isActive = _currentLang == lang;
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
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasContent(lang)
                          ? AppTheme.greenPrimary
                          : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppConstants.languageLabels[lang] ?? lang,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppTheme.greenPrimary
                          : Colors.grey[500],
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

  // ── Language completion (mirrors Next.js bottom grid) ─────────────────────

  Widget _langCompletion() => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      border: Border.all(color: const Color(0xFFE5E7EB)),
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
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['mara', 'english', 'myanmar', 'mizo'].map((lang) {
            final done = _hasContent(lang);
            final isActive = _currentLang == lang;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentLang = lang),
                child: Container(
                  margin: EdgeInsets.only(right: lang == 'mizo' ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: done ? const Color(0xFFF0FDF4) : Colors.white,
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
                          color: done ? AppTheme.greenDark : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        done ? '✓ Done' : 'Empty',
                        style: TextStyle(
                          fontSize: 9,
                          color: done
                              ? AppTheme.greenPrimary
                              : Colors.grey[400],
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

  Widget _sectionLabel(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    ),
  );
}
