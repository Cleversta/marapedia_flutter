import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../utils/app_theme.dart';

// ── YouTube helper ─────────────────────────────────────────────────────────────
String? extractYouTubeId(String url) {
  final patterns = [
    RegExp(r'youtube\.com/watch\?(?:.*&)?v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(url);
    if (m != null) return m.group(1);
  }
  return null;
}

// ── Models ────────────────────────────────────────────────────────────────────
class SongSection {
  final String id;
  final String type;
  String label;
  String content;
  String chords;

  SongSection({
    required this.id,
    required this.type,
    required this.label,
    this.content = '',
    this.chords = '',
  });
}

class SongMeta {
  String key;
  String writer;
  String singer;
  String reference;
  String timeSignature;
  String songNumber;
  String youtubeUrl;

  SongMeta({
    this.key = '',
    this.writer = '',
    this.singer = '',
    this.reference = '',
    this.timeSignature = '',
    this.songNumber = '',
    this.youtubeUrl = '',
  });

  factory SongMeta.fromJson(Map<String, dynamic> j) => SongMeta(
        key: j['key'] ?? '',
        writer: j['writer'] ?? '',
        singer: j['singer'] ?? '',
        reference: j['reference'] ?? '',
        timeSignature: j['timeSignature'] ?? '',
        songNumber: j['songNumber'] ?? '',
        youtubeUrl: j['youtubeUrl'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'writer': writer,
        'singer': singer,
        'reference': reference,
        'timeSignature': timeSignature,
        'songNumber': songNumber,
        'youtubeUrl': youtubeUrl,
      };

  bool get hasAny =>
      key.isNotEmpty ||
      writer.isNotEmpty ||
      songNumber.isNotEmpty ||
      youtubeUrl.isNotEmpty;
}

// ── Section config ─────────────────────────────────────────────────────────────
class _SCfg {
  final String type;
  final String label;
  final Color accent;
  final Color bg;
  final Color fg;
  const _SCfg(this.type, this.label, this.accent, this.bg, this.fg);
}

const _sectionTypes = [
  _SCfg('verse',      'Verse',      Color(0xFF3B82F6), Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
  _SCfg('chorus',     'Chorus',     Color(0xFF16A34A), Color(0xFFF0FDF4), Color(0xFF15803D)),
  _SCfg('bridge',     'Bridge',     Color(0xFF9333EA), Color(0xFFFAF5FF), Color(0xFF7E22CE)),
  _SCfg('intro',      'Intro',      Color(0xFFD97706), Color(0xFFFFFBEB), Color(0xFF92400E)),
  _SCfg('outro',      'Outro',      Color(0xFFEA580C), Color(0xFFFFF7ED), Color(0xFF9A3412)),
  _SCfg('pre-chorus', 'Pre-Chorus', Color(0xFF0D9488), Color(0xFFF0FDFA), Color(0xFF0F766E)),
  _SCfg('custom',     'Custom',     Color(0xFFDB2777), Color(0xFFFDF2F8), Color(0xFF9D174D)),
];

_SCfg _cfgFor(String type) => _sectionTypes.firstWhere(
      (s) => s.type == type,
      orElse: () => _sectionTypes.first,
    );

const _musicalKeys = [
  'C', 'C#', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
];
const _timeSignatures = ['4/4', '3/4', '6/8', '2/4', '12/8'];

// ── Serialization ──────────────────────────────────────────────────────────────
String serializeSong(List<SongSection> sections, SongMeta meta) {
  final metaComment = '<!--meta:${jsonEncode(meta.toJson())}-->';
  final body = sections.map((s) {
    final lines = s.content
        .split('\n')
        .map((l) => '<p>${l.isEmpty ? '&nbsp;' : l}</p>')
        .join('');
    return '<div class="song-section" data-type="${s.type}" '
        'data-label="${s.label}" data-chords="${s.chords}">'
        '<h4>[${s.label}]</h4>$lines</div>';
  }).join('\n');
  return '$metaComment\n$body';
}

List<SongSection> _parseSections(String html) {
  if (html.isEmpty || html == '<p></p>') return [];
  final result = <SongSection>[];
  final divRx = RegExp(
    r'<div[^>]*class="song-section"[^>]*>([\s\S]*?)<\/div>',
    multiLine: true,
  );
  int i = 0;
  for (final m in divRx.allMatches(html)) {
    final tag = m.group(0)!;
    final inner = m.group(1) ?? '';
    final type = RegExp(r'data-type="([^"]*)"').firstMatch(tag)?.group(1) ?? 'verse';
    final label = RegExp(r'data-label="([^"]*)"').firstMatch(tag)?.group(1) ?? 'Verse';
    final chords = RegExp(r'data-chords="([^"]*)"').firstMatch(tag)?.group(1) ?? '';
    final body = inner.replaceAll(RegExp(r'<h4[^>]*>[\s\S]*?<\/h4>'), '');
    final lines = <String>[];
    for (final p in RegExp(r'<p>([\s\S]*?)<\/p>').allMatches(body)) {
      var t = p.group(1) ?? '';
      t = t
          .replaceAll('&nbsp;', '\u00A0')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
      lines.add(t == '\u00A0' ? '' : t);
    }
    result.add(SongSection(
        id: '${i++}', type: type, label: label, content: lines.join('\n'), chords: chords));
  }
  return result;
}

SongMeta _parseMeta(String html) {
  final m = RegExp(r'<!--meta:(.*?)-->').firstMatch(html);
  if (m == null) return SongMeta();
  try {
    return SongMeta.fromJson(jsonDecode(m.group(1)!) as Map<String, dynamic>);
  } catch (_) {
    return SongMeta();
  }
}

String _makeLabel(List<SongSection> sections, String type) {
  if (type == 'custom') return 'Custom';
  final base = _cfgFor(type).label;
  if (['chorus', 'bridge', 'intro', 'outro'].contains(type)) return base;
  final count = sections.where((s) => s.type == type).length;
  return count == 0 ? base : '$base ${count + 1}';
}

int _idCounter = 0;
String _makeId() => '${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

// ── SongEditor widget ──────────────────────────────────────────────────────────
class SongEditor extends StatefulWidget {
  final String content;
  final String language;
  final ValueChanged<String> onChange;

  const SongEditor({
    super.key,
    required this.content,
    required this.onChange,
    this.language = 'mara',
  });

  @override
  State<SongEditor> createState() => _SongEditorState();
}

class _SongEditorState extends State<SongEditor> {
  late List<SongSection> _sections;
  late SongMeta _meta;
  bool _showMeta = false;
  bool _showChords = false;
  bool _showAddMenu = false;
  final Set<String> _expanded = {};
  final Map<String, TextEditingController> _ctrls = {};
  late TextEditingController _songNumberCtrl;
  late TextEditingController _writerCtrl;
  late TextEditingController _singerCtrl;
  late TextEditingController _referenceCtrl;
  late TextEditingController _youtubeUrlCtrl;
  final Set<String> _editingLabel = {};

  // ── YouTube live preview ───────────────────────────────────────────────────
  YoutubePlayerController? _ytController;
  String? _currentVideoId;
  String? _lastEmitted;

  @override
  void initState() {
    super.initState();
    _boot(widget.content);
  }

  void _boot(String html) {
    _sections = _parseSections(html);
    _meta = _parseMeta(html);
    if (_sections.isEmpty) {
      _sections = [
        SongSection(id: _makeId(), type: 'verse', label: 'Verse 1'),
        SongSection(id: _makeId(), type: 'chorus', label: 'Chorus'),
      ];
    }
    _expanded.clear();
    for (final s in _sections) {
      _expanded.add(s.id);
      _ctrls['${s.id}_c'] = TextEditingController(text: s.content);
      _ctrls['${s.id}_h'] = TextEditingController(text: s.chords);
      if (s.type == 'custom') {
        _ctrls['${s.id}_l'] = TextEditingController(text: s.label);
      }
    }
    _songNumberCtrl = TextEditingController(text: _meta.songNumber);
    _writerCtrl = TextEditingController(text: _meta.writer);
    _singerCtrl = TextEditingController(text: _meta.singer);
    _referenceCtrl = TextEditingController(text: _meta.reference);
    _youtubeUrlCtrl = TextEditingController(text: _meta.youtubeUrl);
    _syncYtPreview(_meta.youtubeUrl);
  }

  void _teardown() {
    for (final c in _ctrls.values) c.dispose();
    _ctrls.clear();
    _songNumberCtrl.dispose();
    _writerCtrl.dispose();
    _singerCtrl.dispose();
    _referenceCtrl.dispose();
    _youtubeUrlCtrl.dispose();
    _ytController?.dispose();
    _ytController = null;
    _currentVideoId = null;
  }

  void _syncYtPreview(String url) {
    final id = extractYouTubeId(url);
    if (id == _currentVideoId) return;
    _currentVideoId = id;
    _ytController?.dispose();
    if (id != null && id.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
          forceHD: false,
        ),
      );
    } else {
      _ytController = null;
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(SongEditor old) {
    super.didUpdateWidget(old);
    if (widget.content != old.content && widget.content != _lastEmitted) {
      _teardown();
      setState(() => _boot(widget.content));
    }
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  void _emit() {
    for (final s in _sections) {
      s.content = _ctrls['${s.id}_c']?.text ?? s.content;
      s.chords = _ctrls['${s.id}_h']?.text ?? s.chords;
      if (s.type == 'custom') {
        final labelText = _ctrls['${s.id}_l']?.text.trim() ?? '';
        if (labelText.isNotEmpty) s.label = labelText;
      }
    }
    _meta.songNumber = _songNumberCtrl.text;
    _meta.writer = _writerCtrl.text;
    _meta.singer = _singerCtrl.text;
    _meta.reference = _referenceCtrl.text;
    _meta.youtubeUrl = _youtubeUrlCtrl.text;
    final html = serializeSong(_sections, _meta);
      print('=== EMITTING HTML (first 300 chars) ===');
  print(html.substring(0, html.length.clamp(0, 300)));
    _lastEmitted = html;
    widget.onChange(html);
  }

  void _toggle(String id) => setState(
        () => _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id),
      );

  void _addSection(String type) {
    final label = _makeLabel(_sections, type);
    final id = _makeId();
    _ctrls['${id}_c'] = TextEditingController();
    _ctrls['${id}_h'] = TextEditingController();
    if (type == 'custom') {
      _ctrls['${id}_l'] = TextEditingController(text: 'Custom');
      _editingLabel.add(id);
    }
    setState(() {
      _sections.add(SongSection(id: id, type: type, label: label));
      _expanded.add(id);
      _showAddMenu = false;
    });
    _emit();
  }

  void _removeSection(String id) {
    _ctrls.remove('${id}_c')?.dispose();
    _ctrls.remove('${id}_h')?.dispose();
    _ctrls.remove('${id}_l')?.dispose();
    _editingLabel.remove(id);
    setState(() => _sections.removeWhere((s) => s.id == id));
    _emit();
  }

  void _move(String id, int dir) {
    final idx = _sections.indexWhere((s) => s.id == id);
    final newIdx = idx + dir;
    if (newIdx < 0 || newIdx >= _sections.length) return;
    setState(() {
      final tmp = _sections[idx];
      _sections[idx] = _sections[newIdx];
      _sections[newIdx] = tmp;
    });
    _emit();
  }

  int get _totalLines => _sections.fold(0, (sum, s) {
        final t = _ctrls['${s.id}_c']?.text ?? s.content;
        return sum + t.split('\n').where((l) => l.trim().isNotEmpty).length;
      });

  bool get _hasChords => _sections.any(
        (s) => (_ctrls['${s.id}_h']?.text ?? s.chords).trim().isNotEmpty,
      );

  String get _placeholder {
    const m = {
      'english': 'Write your lyrics here...',
      'myanmar': 'သီချင်းသားများ ရေးပါ...',
    };
    return m[widget.language] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(),
          if (_showMeta) ...[const SizedBox(height: 8), _metaPanel(bottomInset)],
          const SizedBox(height: 8),
          ..._sections.asMap().entries.map((e) => _sectionCard(e.value, e.key, bottomInset)),
          _addButton(),
          const SizedBox(height: 8),
          _footer(),
        ],
      ),
    );
  }

  // ── Toolbar ────────────────────────────────────────────────────────────────
  Widget _toolbar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Text('🎵', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            const Text('Song Editor',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(width: 6),
            Container(width: 1, height: 14, color: const Color(0xFFD1D5DB)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${_sections.length} sections · $_totalLines lines',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _tbBtn(
              label: _showChords ? 'Chords on' : 'Chords off',
              icon: Icons.music_note_outlined,
              active: _showChords,
              aColor: const Color(0xFFD97706),
              aBg: const Color(0xFFFFFBEB),
              aBorder: const Color(0xFFFDE68A),
              onTap: () => setState(() => _showChords = !_showChords),
            ),
            const SizedBox(width: 6),
            _tbBtn(
              label: 'Song details',
              icon: Icons.info_outline,
              active: _showMeta,
              aColor: const Color(0xFF1D4ED8),
              aBg: const Color(0xFFEFF6FF),
              aBorder: const Color(0xFFBFDBFE),
              trailing: _meta.hasAny
                  ? Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6), shape: BoxShape.circle))
                  : null,
              onTap: () => setState(() => _showMeta = !_showMeta),
            ),
          ],
        ),
      );

  Widget _tbBtn({
    required String label,
    required IconData icon,
    required bool active,
    required Color aColor,
    required Color aBg,
    required Color aBorder,
    required VoidCallback onTap,
    Widget? trailing,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: active ? aBg : Colors.white,
            border: Border.all(color: active ? aBorder : const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: active ? aColor : const Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: active ? aColor : const Color(0xFF6B7280))),
              if (trailing != null) ...[const SizedBox(width: 4), trailing],
            ],
          ),
        ),
      );

  // ── Meta panel ─────────────────────────────────────────────────────────────
  Widget _metaPanel(double bottomInset) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFBFDBFE)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)]),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Color(0xFFDFEAFF))),
              ),
              child: const Row(children: [
                Text('🎼', style: TextStyle(fontSize: 13)),
                SizedBox(width: 6),
                Text('Song Information',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(builder: (ctx, bc) {
                final w = (bc.maxWidth - 12) / 2;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _mField('🔢', 'Song No.', _songNumberCtrl, 'e.g. 541', w, bottomInset),
                        _mDrop('🎹', 'Key (Doh is...)', _meta.key, _musicalKeys, (v) {
                          setState(() => _meta.key = v);
                          _emit();
                        }, w),
                        _mDrop('⏱️', 'Time', _meta.timeSignature, _timeSignatures, (v) {
                          setState(() => _meta.timeSignature = v);
                          _emit();
                        }, w),
                        _mField('✍️', 'Written by', _writerCtrl, 'Songwriter name', w, bottomInset),
                        _mField('🎤', 'Sung by', _singerCtrl, 'Artist or group', w, bottomInset),
                        _mField('📖', 'Reference', _referenceCtrl, 'e.g. Psalm 23:1', w, bottomInset),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _youtubeField(bottomInset),
                  ],
                );
              }),
            ),
          ],
        ),
      );

  Widget _youtubeField(double bottomInset) {
    final hasValidId = _currentVideoId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.play_circle_outline_rounded,
                size: 13, color: hasValidId ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(
              'YOUTUBE / VIDEO URL',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: hasValidId ? const Color(0xFF991B1B) : const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _youtubeUrlCtrl,
                scrollPhysics: const NeverScrollableScrollPhysics(),
                scrollPadding: EdgeInsets.only(bottom: bottomInset + 80),
                keyboardType: TextInputType.url,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                  filled: true,
                  fillColor: hasValidId ? const Color(0xFFFFF5F5) : const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: hasValidId ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: hasValidId ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
                  suffixIcon: _youtubeUrlCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _youtubeUrlCtrl.clear();
                            _syncYtPreview('');
                            _emit();
                          },
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
                        )
                      : null,
                ),
                onChanged: (val) {
                  _syncYtPreview(val);
                  _emit();
                },
              ),
            ),
            if (hasValidId) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 13, color: Color(0xFFDC2626)),
                    SizedBox(width: 4),
                    Text('Player will show',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Paste a YouTube link — a player will appear at the top for readers.',
          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),

        // ── Live preview ───────────────────────────────────────────────────
        if (_ytController != null) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: const Color(0xFFFEF2F2),
                  child: const Row(
                    children: [
                      Icon(Icons.play_circle_fill_rounded,
                          size: 14, color: Color(0xFFEF4444)),
                      SizedBox(width: 6),
                      Text('Live preview',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF991B1B))),
                    ],
                  ),
                ),
                YoutubePlayer(
                  controller: _ytController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: const Color(0xFFEF4444),
                  progressColors: const ProgressBarColors(
                    playedColor: Color(0xFFEF4444),
                    handleColor: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _mField(String emoji, String label, TextEditingController ctrl,
          String hint, double w, double bottomInset) =>
      SizedBox(
        width: w,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 5),
          TextField(
            controller: ctrl,
            onChanged: (_) => _emit(),
            style: const TextStyle(fontSize: 13),
            scrollPhysics: const NeverScrollableScrollPhysics(),
            scrollPadding: EdgeInsets.only(bottom: bottomInset + 80),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
            ),
          ),
        ]),
      );

  Widget _mDrop(String emoji, String label, String value, List<String> opts,
          ValueChanged<String> onChanged, double w) =>
      SizedBox(
        width: w,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Expanded(
                child: Text(label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 5),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.isEmpty ? null : value,
                hint: const Text('Select',
                    style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                items: opts
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ]),
      );

  // ── Section card ───────────────────────────────────────────────────────────
  Widget _sectionCard(SongSection s, int idx, double bottomInset) {
    final cfg = _cfgFor(s.type);
    final isExpanded = _expanded.contains(s.id);
    final hasChords = (_ctrls['${s.id}_h']?.text ?? s.chords).trim().isNotEmpty;
    final isCustom = s.type == 'custom';
    final isEditingLbl = _editingLabel.contains(s.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: cfg.accent),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (isCustom) {
                                setState(() => isEditingLbl
                                    ? _editingLabel.remove(s.id)
                                    : _editingLabel.add(s.id));
                              } else {
                                _toggle(s.id);
                              }
                            },
                            child: isCustom && isEditingLbl
                                ? _customLabelField(s, cfg, bottomInset)
                                : _labelBadge(s, cfg, isCustom, hasChords),
                          ),
                          const Spacer(),
                          GestureDetector(onTap: () => _toggle(s.id), child: _chevron(isExpanded)),
                          const SizedBox(width: 2),
                          _arrowBtn(Icons.arrow_upward, idx == 0, () => _move(s.id, -1)),
                          _arrowBtn(Icons.arrow_downward, idx == _sections.length - 1,
                              () => _move(s.id, 1)),
                          const SizedBox(width: 2),
                          GestureDetector(
                            onTap: () => _removeSection(s.id),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 14, color: Color(0xFFD1D5DB)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded) ...[
                      if (_showChords) _chordsRow(s, bottomInset),
                      _lyricsRow(s, bottomInset),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelBadge(SongSection s, _SCfg cfg, bool isCustom, bool hasChords) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: cfg.bg, borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg.fg)),
              if (isCustom) ...[
                const SizedBox(width: 4),
                Icon(Icons.edit_outlined, size: 11, color: cfg.fg.withOpacity(0.6)),
              ],
            ],
          ),
        ),
        if (hasChords && _showChords) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
            child: const Text('chords',
                style: TextStyle(
                    fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w500)),
          ),
        ],
      ],
    );
  }

  Widget _customLabelField(SongSection s, _SCfg cfg, double bottomInset) {
    final ctrl = _ctrls['${s.id}_l']!;
    return Container(
      width: 140,
      height: 30,
      decoration: BoxDecoration(
        color: cfg.bg,
        border: Border.all(color: cfg.accent.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: ctrl,
              autofocus: true,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              scrollPadding: EdgeInsets.only(bottom: bottomInset + 80),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cfg.fg),
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (v) {
                if (v.trim().isNotEmpty) setState(() => s.label = v.trim());
                _emit();
              },
              onSubmitted: (_) {
                setState(() => _editingLabel.remove(s.id));
                _emit();
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _editingLabel.remove(s.id));
              _emit();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.check, size: 13, color: cfg.fg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chevron(bool isExpanded) => AnimatedRotation(
        turns: isExpanded ? 0 : -0.25,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.expand_more, size: 18, color: Color(0xFF9CA3AF)),
      );

  Widget _chordsRow(SongSection s, double bottomInset) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF0),
          border: Border(top: BorderSide(color: Color(0xFFFDE68A))),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              const Text('CHORDS',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                      letterSpacing: 1.5)),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: const Color(0xFFFDE68A))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: TextField(
              controller: _ctrls['${s.id}_h'],
              onChanged: (_) => _emit(),
              maxLines: 2,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              scrollPadding: EdgeInsets.only(bottom: bottomInset + 80),
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                  fontFamily: 'monospace',
                  letterSpacing: 0.8),
decoration: const InputDecoration(
  hintText: 'Am  G  C  F  |  G  Em  Am...',
  hintStyle: TextStyle(fontSize: 12, color: Color(0xFFFBD38D)),
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  filled: false,
  contentPadding: EdgeInsets.zero,
),
            ),
          ),
        ]),
      );


  Widget _lyricsRow(SongSection s, double bottomInset) => Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              const Text('LYRICS',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1.5)),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: const Color(0xFFF3F4F6))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: TextField(
              controller: _ctrls['${s.id}_c'],
              onChanged: (_) => _emit(),
              maxLines: null,
              minLines: 5,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              scrollPadding: EdgeInsets.only(bottom: bottomInset + 80),
              style: const TextStyle(
                  fontSize: 14, height: 1.9, fontFamily: 'monospace', color: Color(0xFF374151)),
decoration: InputDecoration(
  hintText: _placeholder,
  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  filled: false,
  contentPadding: EdgeInsets.zero,
),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _ctrls['${s.id}_c']!,
                builder: (_, val, __) => Text(
                  '${val.text.split('\n').where((l) => l.trim().isNotEmpty).length} lines',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFD1D5DB)),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _arrowBtn(IconData icon, bool disabled, VoidCallback onTap) =>
      GestureDetector(
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon,
              size: 13,
              color: disabled ? const Color(0xFFE5E7EB) : const Color(0xFF9CA3AF)),
        ),
      );

  // ── Add button ─────────────────────────────────────────────────────────────
  Widget _addButton() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showAddMenu = !_showAddMenu),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _showAddMenu ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _showAddMenu ? const Color(0xFFF0FDF4) : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add,
                      size: 18,
                      color: _showAddMenu ? AppTheme.greenPrimary : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Text('Add section',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _showAddMenu ? AppTheme.greenPrimary : const Color(0xFF9CA3AF))),
                ],
              ),
            ),
          ),
          if (_showAddMenu) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CHOOSE SECTION TYPE',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sectionTypes
                      .map((t) => GestureDetector(
                            onTap: () => _addSection(t.type),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: t.bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: t.accent.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(t.label,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: t.fg)),
                                  if (t.type == 'custom') ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit_outlined,
                                        size: 11, color: t.fg.withOpacity(0.6)),
                                  ],
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ]),
            ),
          ],
        ],
      );

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer() => Row(
        children: [
          Text('${_sections.length} section${_sections.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          Text('$_totalLines lines',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          if (_meta.key.isNotEmpty) ...[
            const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            Text('Key of ${_meta.key}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
          ],
          if (_meta.timeSignature.isNotEmpty) ...[
            const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            Text(_meta.timeSignature,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
          const Spacer(),
          if (_hasChords)
            const Text('♪ chords', style: TextStyle(fontSize: 11, color: Color(0xFFD97706))),
          if (_currentVideoId != null) ...[
            if (_hasChords)
              const Text(' · ', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            const Icon(Icons.play_circle_outline_rounded, size: 13, color: Color(0xFFEF4444)),
            const SizedBox(width: 3),
            const Text('video linked', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
          ],
        ],
      );
}