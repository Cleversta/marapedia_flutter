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
      final baseTitle = _titleCtrls['english']?.text.trim().isNotEmpty == true
          ? _titleCtrls['english']!.text.trim()
          : _titleCtrls[filledLangs.first]!.text.trim();

      final slug = slugify(baseTitle);
      final repo = ArticleRepository();

      // Upload images
      String? thumbnailUrl;
      final uploadedImages = <Map<String, dynamic>>[];
      for (int i = 0; i < _images.length; i++) {
        final url = await UploadService.uploadImage(_images[i]);
        if (i == 0) thumbnailUrl = url;
        uploadedImages.add({
          'url': url,
          'caption': i < _captions.length ? _captions[i] : '',
        });
      }

      // Create article
      final article = await repo.createArticle(
        slug: slug,
        category: _category,
        status: status,
        authorId: authState.userId,
        thumbnailUrl: thumbnailUrl,
        articleType: _articleType.isEmpty ? null : _articleType,
        sourceUrl: _sourceUrlCtrl.text.trim().isEmpty ? null : _sourceUrlCtrl.text.trim(),
      );

      // Insert images
      if (uploadedImages.isNotEmpty) {
        await repo.insertImages(article.id, uploadedImages, authState.userId);
      }

      // Insert translations
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

  @override
  Widget build(BuildContext context) {
    final canPublish =
        context.read<AuthBloc>().state is AuthAuthenticated &&
        (context.read<AuthBloc>().state as AuthAuthenticated).profile.isEditor;

    final typeOptions = AppConstants.articleTypes[_category] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Article', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: () => _save(canPublish ? 'published' : 'draft'),
              child: Text(
                canPublish ? 'Publish' : 'Submit',
                style: const TextStyle(color: AppTheme.greenPrimary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!canPublish)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFFBEB),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your article will be reviewed by an editor before publishing.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
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
                      child: Text(_error, style: TextStyle(fontSize: 13, color: Colors.red[700])),
                    ),

                  // ── Category ──────────────────────────────────────────────
                  _sectionTitle('Category'),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: AppConstants.categories
                          .where((c) => c['value'] != 'photos')
                          .map((c) => _categoryChip(c['value']!, '${c['icon']} ${c['label']!}'))
                          .toList(),
                    ),
                  ),

                  // ── Article type ──────────────────────────────────────────
                  if (typeOptions.isNotEmpty) ...[
                    _sectionTitle('Type'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: typeOptions
                            .map((t) => _typeChip(t['value']!, t['label']!))
                            .toList(),
                      ),
                    ),
                  ],

                  // ── Images ────────────────────────────────────────────────
                  _sectionTitle('Images'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_images.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_images[i], width: 72, height: 72, fit: BoxFit.cover),
                                  ),
                                  if (i == 0)
                                    Positioned(
                                      top: 2,
                                      left: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.greenPrimary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('C', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _images.removeAt(i);
                                        _captions.removeAt(i);
                                      }),
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 10, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                          label: Text(_images.isEmpty ? 'Add Images' : '${_images.length} images · Add more'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.greenPrimary,
                            side: const BorderSide(color: AppTheme.greenPrimary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Source URL ────────────────────────────────────────────
                  _sectionTitle('Source'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 15, color: Color(0xFFD1D5DB)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _sourceUrlCtrl,
                              keyboardType: TextInputType.url,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                              decoration: const InputDecoration(
                                hintText: 'Source / related link (optional)  e.g. https://...',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: _sourceUrlCtrl,
                            builder: (_, __, ___) => _sourceUrlCtrl.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => setState(() => _sourceUrlCtrl.clear()),
                                    child: const Icon(Icons.close, size: 14, color: Color(0xFFD1D5DB)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Language tabs ─────────────────────────────────────────
                  _sectionTitle('Content'),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
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
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasCont ? AppTheme.greenPrimary : Colors.grey[300],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppConstants.languageLabels[lang] ?? lang,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                      color: isActive ? AppTheme.greenPrimary : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Title ─────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TextField(
                      controller: _titleCtrls[_currentLang],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: 'Article title...',
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

                  // ── Content editor ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _category == 'songs'
                        ? SongEditor(
                            key: ValueKey('song_$_currentLang'),
                            content: _contentMap[_currentLang]!,
                            language: _currentLang,
                            onChange: (val) => setState(() => _contentMap[_currentLang] = val),
                          )
                        : RichEditorWidget(
                            key: ValueKey('rich_${_category}_$_currentLang'),
                            content: _contentMap[_currentLang]!,
                            onChange: (html) => setState(() => _contentMap[_currentLang] = html),
                            placeholder: _category == 'poems'
                                ? 'Write poem here...'
                                : 'Write your content here...',
                          ),
                  ),

                  // ── Bottom buttons ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => _save('draft'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : () => _save(canPublish ? 'published' : 'draft'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(canPublish ? 'Publish' : 'Submit for Review'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5),
    ),
  );

  Widget _categoryChip(String value, String label) {
    final isActive = _category == value;
    return GestureDetector(
      onTap: () => setState(() {
        _category = value;
        _articleType = '';
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.greenPrimary : Colors.white,
          border: Border.all(
            color: isActive ? AppTheme.greenPrimary : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final isActive = _articleType == value;
    return GestureDetector(
      onTap: () => setState(() => _articleType = isActive ? '' : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.greenPrimary : Colors.white,
          border: Border.all(
            color: isActive ? AppTheme.greenPrimary : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}