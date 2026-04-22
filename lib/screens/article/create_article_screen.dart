import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/slug.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../repositories/article_repository.dart';
import '../../services/upload_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/song_editor.dart';
import '../../widgets/rich_editor.dart';

class CreateArticleScreen extends StatefulWidget {
  final String? category;
  const CreateArticleScreen({super.key, this.category});
  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  String _category = 'history';
  String _articleType = '';
  String _currentLang = 'mara';
  bool _saving = false;
  String _error = '';

  final Map<String, TextEditingController> _titleCtrls = {};
  final Map<String, String> _contentMap = {
    'mara': '',
    'english': '',
    'myanmar': '',
    'mizo': '',
  };

  final TextEditingController _sourceUrlCtrl = TextEditingController();
  final List<File> _images = [];
  final List<String> _captions = [];
  final ScrollController _scrollController = ScrollController();

  bool get _isSong => _category == 'songs';

  @override
  void initState() {
    super.initState();
    _category = widget.category ?? 'history';
    for (final lang in ['mara', 'english', 'myanmar', 'mizo']) {
      _titleCtrls[lang] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _titleCtrls.values) c.dispose();
    _sourceUrlCtrl.dispose();
    super.dispose();
  }

  bool _hasContent(String lang) =>
      (_titleCtrls[lang]?.text.trim().isNotEmpty ?? false) ||
      (_contentMap[lang]?.isNotEmpty ?? false);

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: 10);
    if (picked.isEmpty) return;
    setState(() {
      for (final x in picked) {
        if (_images.length < 10) {
          _images.add(File(x.path));
          _captions.add('');
        }
      }
    });
  }

  Map<String, dynamic> _parseSongMeta(String html) {
    final m = RegExp(r'<!--meta:(.*?)-->').firstMatch(html);
    if (m == null) return {};
    try {
      return jsonDecode(m.group(1)!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _buildBaseSlug() {
    for (final lang in ['english', 'mara', 'mizo', 'myanmar']) {
      final title = _titleCtrls[lang]?.text.trim() ?? '';
      if (title.isNotEmpty) {
        final s = slugify(title);
        if (s.isNotEmpty) return s;
      }
    }
    return 'article-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _resolveUniqueSlug(ArticleRepository repo, String baseSlug) async {
    String candidate = baseSlug;
    int attempt = 1;
    while (true) {
      final exists = await repo.slugExists(candidate);
      if (!exists) return candidate;
      attempt++;
      candidate = '$baseSlug-$attempt';
    }
  }

  Future<void> _save(String status) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final filledLangs = ['mara', 'english', 'myanmar', 'mizo'].where((l) {
      final hasTitle = _titleCtrls[l]?.text.trim().isNotEmpty ?? false;
      final hasContent = _contentMap[l]?.isNotEmpty ?? false;
      return hasTitle && hasContent;
    }).toList();

    if (filledLangs.isEmpty) {
      setState(() => _error = 'Please write at least one language version with title and content.');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      final repo = ArticleRepository();
      final baseSlug = _buildBaseSlug();
      final slug = await _resolveUniqueSlug(repo, baseSlug);

      String? thumbnailUrl;
      final uploadedImages = <Map<String, dynamic>>[];
      for (int i = 0; i < _images.length; i++) {
        final url = await UploadService.uploadImage(_images[i]);
        if (i == 0) thumbnailUrl = url;
        uploadedImages.add({'url': url, 'caption': i < _captions.length ? _captions[i] : ''});
      }

      String? singer;
      String? songwriter;
      if (_isSong) {
        for (final lang in filledLangs) {
          final meta = _parseSongMeta(_contentMap[lang]!);
          singer ??= (meta['singer'] as String?)?.isNotEmpty == true ? meta['singer'] as String : null;
          songwriter ??= (meta['writer'] as String?)?.isNotEmpty == true ? meta['writer'] as String : null;
        }
      }

      final article = await repo.createArticle(
        slug: slug,
        category: _category,
        status: status,
        authorId: authState.userId,
        thumbnailUrl: thumbnailUrl,
        articleType: _articleType.isEmpty ? null : _articleType,
        sourceUrl: _sourceUrlCtrl.text.trim().isEmpty ? null : _sourceUrlCtrl.text.trim(),
        singer: singer,
        songwriter: songwriter,
      );

      if (uploadedImages.isNotEmpty) {
        await repo.insertImages(article.id, uploadedImages, authState.userId);
      }

      for (final lang in filledLangs) {
        final content = _contentMap[lang]!;
        await repo.upsertTranslation(
          articleId: article.id,
          language: lang,
          title: _titleCtrls[lang]!.text.trim(),
          content: content,
          excerpt: Helpers.makeExcerpt(content),
          updatedBy: authState.userId,
        );
      }

      if (mounted) context.pushReplacement('/articles/$slug');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canPublish = context.read<AuthBloc>().state is AuthAuthenticated &&
        (context.read<AuthBloc>().state as AuthAuthenticated).profile.isEditor;
    final typeOptions = AppConstants.articleTypes[_category] ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(canPublish),
      body: Column(
        children: [
          if (!canPublish) _draftBanner(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController, 
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: bottomInset > 0 ? 70 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error.isNotEmpty) _errorBanner(),

                  // ── Category + Type (compact, same row area) ──────────────
                  _compactMeta(typeOptions),

                  // ── Media row: image icon + source url ───────────────────
                  _mediaRow(bottomInset),

                  // ── Language tabs + Title + Body (unified card) ───────────
                  _sectionLabel('CONTENT'),
                  _contentCard(bottomInset),

                  // ── Action buttons ────────────────────────────────────────
                  _actionButtons(canPublish),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool canPublish) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF1A1A2E)),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'New Article',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), letterSpacing: -0.2),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE8E8EC)),
      ),
      actions: [
        if (_saving)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => _save(canPublish ? 'published' : 'draft'),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.greenPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
              ),
              child: Text(
                canPublish ? 'Publish' : 'Submit',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _draftBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: const Color(0xFFFFFBEB),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 13, color: Color(0xFFD97706)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Your article will be reviewed by an editor before publishing.',
                style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
              ),
            ),
          ],
        ),
      );

  Widget _errorBanner() => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(_error, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
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

  // ── Compact Category + Type meta block ────────────────────────────────────
  Widget _compactMeta(List<Map<String, String>> typeOptions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CATEGORY',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFB0B7C3), letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 28,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: AppConstants.categories
                          .where((c) => c['value'] != 'photos')
                          .map((c) => _miniChip(
                                label: '${c['icon']} ${c['label']!}',
                                active: _category == c['value'],
                                onTap: () => setState(() {
                                  _category = c['value']!;
                                  _articleType = '';
                                }),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Type row — only shown if options exist
            if (typeOptions.isNotEmpty) ...[
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TYPE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFB0B7C3), letterSpacing: 1.1),
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
                                  onTap: () => setState(() =>
                                      _articleType = _articleType == t['value'] ? '' : t['value']!),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  Widget _mediaRow(double bottomInset) {
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
              onTap: _pickImages,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _images.isEmpty
                          ? Icons.add_photo_alternate_outlined
                          : Icons.photo_library_outlined,
                      size: 18,
                      color: _images.isEmpty
                          ? const Color(0xFF9CA3AF)
                          : AppTheme.greenPrimary,
                    ),
                    // Badge showing count
                    if (_images.isNotEmpty)
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
                              '${_images.length}',
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
                  scrollPadding: EdgeInsets.only(bottom: bottomInset + 80),
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151)),
                  decoration: const InputDecoration(
                    hintText: 'Source URL (optional)',
                    hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFFD1D5DB)),
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
                        child: Icon(Icons.close, size: 13, color: Color(0xFFD1D5DB)),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Unified content card: lang tabs + title + divider + editor ─────────────
  Widget _contentCard(double bottomInset) {
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
                scrollPadding: EdgeInsets.only(bottom: bottomInset + 80),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: _isSong ? 'Song title...' : 'Article title...',
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
              child: _isSong
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: SongEditor(
                        key: ValueKey('song_$_currentLang'),
                        content: _contentMap[_currentLang]!,
                        language: _currentLang,
                        onChange: (val) => setState(() => _contentMap[_currentLang] = val),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: RichEditorWidget(
                        pageScrollController: _scrollController, 
                        key: ValueKey('rich_${_category}_$_currentLang'),
                        content: _contentMap[_currentLang]!,
                        onChange: (html) =>
                            setState(() => _contentMap[_currentLang] = html),
                        placeholder: _category == 'poems'
                            ? 'Write poem here...'
                            : 'Write your content here...',
                      ),
                    ),
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
                      color: isActive ? AppTheme.greenPrimary : Colors.transparent,
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
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
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

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _actionButtons(bool canPublish) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => _save('draft'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  foregroundColor: const Color(0xFF6B7280),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Draft',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _saving ? null : () => _save(canPublish ? 'published' : 'draft'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  backgroundColor: AppTheme.greenPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  canPublish ? 'Publish' : 'Submit for Review',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
}