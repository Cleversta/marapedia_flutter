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
  final TextEditingController _singerCtrl = TextEditingController();
  final TextEditingController _songwriterCtrl = TextEditingController();

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
    for (final c in _titleCtrls.values) c.dispose();
    _sourceUrlCtrl.dispose();
    _singerCtrl.dispose();
    _songwriterCtrl.dispose();
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
      _singerCtrl.text = article.singer ?? '';
      _songwriterCtrl.text = article.songwriter ?? '';
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
        'thumbnail_url':
            allImages.isNotEmpty ? allImages.first['url'] : null,
        'featured': _featured,
        'source_url': _sourceUrlCtrl.text.trim().isEmpty
            ? null
            : _sourceUrlCtrl.text.trim(),
        'singer': _isSong && _singerCtrl.text.trim().isNotEmpty
            ? _singerCtrl.text.trim()
            : null,
        'songwriter': _isSong && _songwriterCtrl.text.trim().isNotEmpty
            ? _songwriterCtrl.text.trim()
            : null,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_article == null) {
      return Scaffold(
        appBar:
            AppBar(leading: BackButton(onPressed: () => context.pop())),
        body: const Center(child: Text('Article not found')),
      );
    }

    final typeOptions =
        AppConstants.articleTypes[_article!.category] ?? [];
    final edType = _editorType(_article!.category);

    // FIX: read viewInsets here, at the top of build(), so it is always
    // fresh on every rebuild triggered by keyboard show/hide.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              size: 16, color: Color(0xFF1A1A2E)),
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
          child: Container(
              height: 1, color: const Color(0xFFE8E8EC)),
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
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          // FIX: Apply bottom padding equal to keyboard height + safe margin.
          // This is the primary fix — without this, content at the bottom
          // is hidden behind the keyboard and cannot be scrolled into view.
          padding: EdgeInsets.only(bottom: bottomInset + 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(_error,
                      style: TextStyle(
                          fontSize: 13, color: Colors.red[700])),
                ),

              // ── Article type ──────────────────────────────────────
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
                        onTap: () => setState(() =>
                            _articleType =
                                isActive ? '' : t['value']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
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
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // ── Singer / Songwriter (songs only) ──────────────────
              if (_isSong) ...[
                _sectionLabel('Song Info'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _textField(
                        controller: _singerCtrl,
                        hint: 'Singer / Artist name',
                        icon: Icons.mic_outlined,
                        bottomInset: bottomInset,
                      ),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _songwriterCtrl,
                        hint: 'Songwriter / Composer (optional)',
                        icon: Icons.edit_note_outlined,
                        bottomInset: bottomInset,
                      ),
                    ],
                  ),
                ),
              ],

              // ── Images ────────────────────────────────────────────
              _sectionLabel('Images'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_existingImages.isNotEmpty ||
                        _newImages.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._existingImages
                                .asMap()
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(
                                        right: 6),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            e.value['url'],
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        if (e.key == 0)
                                          Positioned(
                                            top: 2,
                                            left: 2,
                                            child: Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 4,
                                                  vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme
                                                    .greenPrimary,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(4),
                                              ),
                                              child: const Text('C',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.white,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold)),
                                            ),
                                          ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () => setState(() =>
                                                _existingImages
                                                    .removeAt(e.key)),
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration:
                                                  const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape
                                                          .circle),
                                              child: const Icon(
                                                  Icons.close,
                                                  size: 10,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ..._newImages.asMap().entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(
                                        right: 6),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(e.value,
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () => setState(() =>
                                                _newImages
                                                    .removeAt(e.key)),
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration:
                                                  const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape
                                                          .circle),
                                              child: const Icon(
                                                  Icons.close,
                                                  size: 10,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          left: 2,
                                          child: Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 4,
                                                    vertical: 2),
                                            color: Colors.orange,
                                            child: const Text('New',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8)),
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
                        setState(() => _newImages.addAll(
                            picked.map((x) => File(x.path))));
                      },
                      icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 16),
                      label: const Text('Add Images'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.greenPrimary,
                        side: const BorderSide(
                            color: AppTheme.greenPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Source URL ────────────────────────────────────────
              _sectionLabel('Source'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _textField(
                  controller: _sourceUrlCtrl,
                  hint: 'Source / related link (optional)  e.g. https://...',
                  icon: Icons.link,
                  keyboardType: TextInputType.url,
                  showClear: true,
                  bottomInset: bottomInset,
                ),
              ),

              // ── Featured ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Featured article',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Switch(
                      value: _featured,
                      onChanged: (v) =>
                          setState(() => _featured = v),
                      activeThumbColor: AppTheme.greenPrimary,
                    ),
                  ],
                ),
              ),

              // ── Language tabs ─────────────────────────────────────
              _sectionLabel('Content'),
              _langTabs(),

              // ── Title ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _titleCtrls[_currentLang],
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                  // FIX: ensure title field scrolls into view when
                  // keyboard appears — use fresh bottomInset value
                  scrollPadding: EdgeInsets.only(
                    bottom: bottomInset + 80,
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

              // ── Editor area ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _buildEditor(edType),
              ),

              // ── Language completion ───────────────────────────────
              _langCompletion(),

              // FIX: Extra bottom spacing so the last widget clears the
              // keyboard even on small screens. The SingleChildScrollView
              // padding already accounts for viewInsets.bottom, but this
              // gives visual breathing room after the last item.
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(_EditorType type) {
    switch (type) {
      case _EditorType.song:
        return SongEditor(
          key: ValueKey('song_$_currentLang'),
          content: _contentMap[_currentLang] ?? '',
          language: _currentLang,
          onChange: (html) =>
              setState(() => _contentMap[_currentLang] = html),
        );
      case _EditorType.poem:
      case _EditorType.rich:
        return RichEditorWidget(
          key: ValueKey('rich_${type.name}_$_currentLang'),
          content: _contentMap[_currentLang] ?? '',
          onChange: (html) =>
              setState(() => _contentMap[_currentLang] = html),
          placeholder: type == _EditorType.poem
              ? 'Write poem here...'
              : 'Write your content here...',
        );
    }
  }

  // FIX: added bottomInset parameter so every inner TextField can set
  // scrollPadding correctly without calling MediaQuery itself.
  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double bottomInset,
    TextInputType keyboardType = TextInputType.text,
    bool showClear = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFFD1D5DB)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              // FIX: tell Flutter to scroll this field into view above
              // the keyboard. Without this, tapping the field focuses it
              // but the keyboard covers it on physical devices.
              scrollPadding: EdgeInsets.only(bottom: bottomInset + 80),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF4B5563)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFFD1D5DB)),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (showClear)
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (_, __, ___) => controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () =>
                          setState(() => controller.clear()),
                      child: const Icon(Icons.close,
                          size: 14,
                          color: Color(0xFFD1D5DB)),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _langTabs() => Container(
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: ['mara', 'english', 'myanmar', 'mizo']
              .map((lang) {
            final isActive = _currentLang == lang;
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _currentLang = lang),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
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
                    mainAxisAlignment:
                        MainAxisAlignment.center,
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
                        AppConstants.languageLabels[lang] ??
                            lang,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
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
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['mara', 'english', 'myanmar', 'mizo']
                  .map((lang) {
                final done = _hasContent(lang);
                final isActive = _currentLang == lang;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _currentLang = lang),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: lang == 'mizo' ? 0 : 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
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
                            AppConstants.languageLabels[lang] ??
                                lang,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: done
                                  ? AppTheme.greenDark
                                  : Colors.grey[500],
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
              letterSpacing: 0.5),
        ),
      );
}