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

class EditArticleScreen extends StatefulWidget {
  final String slug;
  const EditArticleScreen({super.key, required this.slug});
  @override State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  ArticleModel? _article;
  bool _loading = true;
  bool _saving  = false;
  String _error = '';
  String _success = '';

  String _currentLang = 'mara';
  String _articleType = '';
  bool _featured = false;

  final Map<String, Map<String, TextEditingController>> _ctrls = {};
  List<Map<String, dynamic>> _existingImages = [];
  final List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    for (final lang in ['mara', 'english', 'myanmar', 'mizo']) {
      _ctrls[lang] = {'title': TextEditingController(), 'content': TextEditingController()};
    }
    _loadArticle();
  }

  @override
  void dispose() {
    for (final m in _ctrls.values) { m['title']?.dispose(); m['content']?.dispose(); }
    super.dispose();
  }

  Future<void> _loadArticle() async {
    final repo = ArticleRepository();
    final article = await repo.getBySlug(widget.slug);
    if (article == null) { setState(() => _loading = false); return; }

    setState(() {
      _article = article;
      _articleType = article.articleType ?? '';
      _featured = article.featured;
      _existingImages = article.images.map((i) => {'url': i.url, 'caption': i.caption ?? ''}).toList();
      for (final t in article.translations) {
        _ctrls[t.language]?['title']?.text = t.title;
        _ctrls[t.language]?['content']?.text = t.content;
      }
      _loading = false;
    });
  }

  bool _hasContent(String lang) =>
    (_ctrls[lang]?['title']?.text.trim().isNotEmpty ?? false) ||
    (_ctrls[lang]?['content']?.text.trim().isNotEmpty ?? false);

  Future<void> _save() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || _article == null) return;

    setState(() { _saving = true; _error = ''; _success = ''; });
    try {
      final repo = ArticleRepository();

      // Upload new images
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

      final filledLangs = ['mara', 'english', 'myanmar', 'mizo']
        .where((l) => _ctrls[l]?['title']?.text.trim().isNotEmpty == true && _ctrls[l]?['content']?.text.trim().isNotEmpty == true)
        .toList();

      for (final lang in filledLangs) {
        final content = _ctrls[lang]!['content']!.text;
        await repo.upsertTranslation(
          articleId: _article!.id, language: lang,
          title: _ctrls[lang]!['title']!.text.trim(),
          content: content,
          excerpt: Helpers.makeExcerpt(content),
          updatedBy: authState.userId,
        );
      }

      setState(() { _saving = false; _success = 'Article saved!'; });
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _success = ''); });
    } catch (e) {
      setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_article == null) return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: const Center(child: Text('Article not found')),
    );

    final typeOptions = AppConstants.articleTypes[_article!.category] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Article', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16), onPressed: () => context.pop()),
        actions: [
          if (_success.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(_success, style: const TextStyle(color: AppTheme.greenPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
            ),
          if (_saving)
            const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppTheme.greenPrimary, fontWeight: FontWeight.w700))),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red[200]!)),
              child: Text(_error, style: TextStyle(fontSize: 13, color: Colors.red[700])),
            ),

          // Article Type
          if (typeOptions.isNotEmpty) ...[
            _sectionTitle('Type'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 6, runSpacing: 6,
                children: typeOptions.map((t) {
                  final isActive = _articleType == t['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _articleType = isActive ? '' : t['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.greenPrimary : Colors.white,
                        border: Border.all(color: isActive ? AppTheme.greenPrimary : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t['label']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? Colors.white : Colors.grey[600])),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Images
          _sectionTitle('Images'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    ..._existingImages.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(8),
                          child: Image.network(e.value['url'], width: 72, height: 72, fit: BoxFit.cover)),
                        Positioned(top: 2, right: 2, child: GestureDetector(
                          onTap: () => setState(() => _existingImages.removeAt(e.key)),
                          child: Container(width: 18, height: 18,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 10, color: Colors.white)),
                        )),
                      ]),
                    )),
                    ..._newImages.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(8),
                          child: Image.file(e.value, width: 72, height: 72, fit: BoxFit.cover)),
                        Positioned(top: 2, right: 2, child: GestureDetector(
                          onTap: () => setState(() => _newImages.removeAt(e.key)),
                          child: Container(width: 18, height: 18,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 10, color: Colors.white)),
                        )),
                        Positioned(top: 2, left: 2, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: Colors.orange,
                          child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 8)),
                        )),
                      ]),
                    )),
                  ]),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickMultiImage();
                  setState(() => _newImages.addAll(picked.map((x) => File(x.path))));
                },
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: const Text('Add Images'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.greenPrimary, side: const BorderSide(color: AppTheme.greenPrimary)),
              ),
            ]),
          ),

          // Featured toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Text('Featured article', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(value: _featured, onChanged: (v) => setState(() => _featured = v), activeColor: AppTheme.greenPrimary),
            ]),
          ),

          // Language tabs
          _sectionTitle('Content'),
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
            child: Row(
              children: ['mara', 'english', 'myanmar', 'mizo'].map((lang) {
                final isActive = _currentLang == lang;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _currentLang = lang),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(
                      color: isActive ? AppTheme.greenPrimary : Colors.transparent, width: 2,
                    ))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(
                        shape: BoxShape.circle, color: _hasContent(lang) ? AppTheme.greenPrimary : Colors.grey[300],
                      )),
                      const SizedBox(width: 4),
                      Text(AppConstants.languageLabels[lang] ?? lang,
                        style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? AppTheme.greenPrimary : Colors.grey[500])),
                    ]),
                  ),
                ));
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                controller: _ctrls[_currentLang]!['title'],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: 'Article title...', border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrls[_currentLang]!['content'],
                maxLines: null,
                minLines: 15,
                style: const TextStyle(fontSize: 15, height: 1.8),
                decoration: const InputDecoration(hintText: 'Write your content here...', border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5)),
  );
}
