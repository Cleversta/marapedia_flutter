import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

// ── Delta → HTML ──────────────────────────────────────────────────────────────
class _DeltaToHtml {
  static String convert(Document doc) {
    final ops = doc.toDelta().toJson() as List<dynamic>;
    final buf = StringBuffer();
    final lineBuf = StringBuffer();
    Map<String, dynamic> lineAttrs = {};
    String? currentListType;

    void openList(String type) {
      if (currentListType != type) {
        if (currentListType != null) {
          buf.write(currentListType == 'bullet' ? '</ul>' : '</ol>');
        }
        buf.write(type == 'bullet' ? '<ul>' : '<ol>');
        currentListType = type;
      }
    }

    void closeList() {
      if (currentListType != null) {
        buf.write(currentListType == 'bullet' ? '</ul>' : '</ol>');
        currentListType = null;
      }
    }

    void flushLine() {
      final text = lineBuf.toString();
      lineBuf.clear();
      final la = Map<String, dynamic>.from(lineAttrs);
      lineAttrs = {};
      final listType = la['list'] as String?;
      if (listType != null) {
        openList(listType);
        buf.write('<li>$text</li>');
      } else {
        closeList();
        if (la['header'] == 1) {
          buf.write('<h1>$text</h1>');
        } else if (la['header'] == 2) {
          buf.write('<h2>$text</h2>');
        } else if (la['header'] == 3) {
          buf.write('<h3>$text</h3>');
        } else if (la['blockquote'] == true) {
          buf.write('<blockquote>$text</blockquote>');
        } else {
          buf.write('<p>${text.isEmpty ? '<br>' : text}</p>');
        }
      }
    }

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert is! String) continue;
      final attrs = (op['attributes'] as Map?)?.cast<String, dynamic>() ?? {};
      if (insert == '\n') {
        if (attrs.isNotEmpty) lineAttrs = attrs;
        flushLine();
        continue;
      }
      final parts = insert.split('\n');
      for (int i = 0; i < parts.length; i++) {
        if (i > 0) flushLine();
        final seg = parts[i];
        if (seg.isNotEmpty) lineBuf.write(_applyInline(seg, attrs));
      }
    }
    if (lineBuf.isNotEmpty) flushLine();
    closeList();
    return buf.toString();
  }

  static String _applyInline(String text, Map<String, dynamic> attrs) {
    String s = _encode(text);
    final color = attrs['color'] as String?;
    if (color != null) s = '<span style="color: $color">$s</span>';
    if (attrs['link'] != null) s = '<a href="${attrs['link']}">$s</a>';
    if (attrs['strike'] == true) s = '<s>$s</s>';
    if (attrs['italic'] == true) s = '<em>$s</em>';
    if (attrs['bold'] == true) s = '<strong>$s</strong>';
    return s;
  }

  static String _encode(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

abstract class _ET {
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE8E8E8);
  static const Color inkPrimary = Color(0xFF1A1A1A);
  static const double radius    = 10.0;
}

class RichEditorWidget extends StatefulWidget {
  final String content;
  final ValueChanged<String> onChange;
  final String placeholder;
  final String? label;
  final ScrollController? pageScrollController;

  const RichEditorWidget({
    super.key,
    required this.content,
    required this.onChange,
    this.placeholder = 'Write here…',
    this.label,
    this.pageScrollController,
  });

  @override
  State<RichEditorWidget> createState() => _RichEditorWidgetState();
}

class _RichEditorWidgetState extends State<RichEditorWidget>
    with WidgetsBindingObserver {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _suppressCallback = false;
  bool _focused = false;
  OverlayEntry? _toolbarEntry;

  // Track last cursor line so we only scroll on actual line changes
  int _lastCursorLine = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = QuillController(
      document: _fromHtml(widget.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.addListener(_onChanged);
    // ← NEW: listen to selection changes for cursor-based auto-scroll
    _controller.addListener(_onSelectionChanged);
    _focusNode.addListener(_handleFocus);
  }

  // Fires when keyboard actually appears/disappears
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _toolbarEntry?.markNeedsBuild();
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollEditorIntoView();
      });
    }
  }

  // ── NEW: scroll when cursor moves to a new line (Enter key or arrow down) ──
  void _onSelectionChanged() {
    if (!_focusNode.hasFocus) return;
    final doc = _controller.document;
    final offset = _controller.selection.extentOffset;
    if (offset < 0) return;

    // Calculate which line the cursor is on by counting '\n' chars before it
    final plainText = doc.toPlainText();
    final safeOffset = offset.clamp(0, plainText.length);
    final textBefore = plainText.substring(0, safeOffset);
    final currentLine = '\n'.allMatches(textBefore).length;

    if (currentLine != _lastCursorLine) {
      _lastCursorLine = currentLine;
      // Defer so the editor has finished laying out the new line
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollEditorIntoView();
      });
    }
  }

  void _scrollEditorIntoView() {
    final sc = widget.pageScrollController;
    if (sc != null && sc.hasClients) {
      sc.animateTo(
        sc.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }
    // Fallback: ask the nearest Scrollable ancestor
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void didUpdateWidget(RichEditorWidget old) {
    super.didUpdateWidget(old);
    if (widget.content != old.content && !_focusNode.hasFocus) {
      _suppressCallback = true;
      _controller.document = _fromHtml(widget.content);
      _suppressCallback = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeToolbar();
    _controller.removeListener(_onChanged);
    _controller.removeListener(_onSelectionChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocus() {
    final hasFocus = _focusNode.hasFocus;
    setState(() => _focused = hasFocus);
    if (hasFocus) {
      _lastCursorLine = -1; // reset on focus
      WidgetsBinding.instance.addPostFrameCallback((_) => _insertToolbar());
    } else {
      _removeToolbar();
    }
  }

  void _insertToolbar() {
    if (!mounted || !_focusNode.hasFocus) return;
    _removeToolbar();
    _toolbarEntry = OverlayEntry(builder: _buildToolbarOverlay);
    Overlay.of(context).insert(_toolbarEntry!);
  }

  void _removeToolbar() {
    _toolbarEntry?.remove();
    _toolbarEntry = null;
  }

  Widget _buildToolbarOverlay(BuildContext ctx) {
    final bottom = MediaQuery.of(ctx).viewInsets.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _ET.surface,
            border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 46,
              child: Row(
                children: [
                  Expanded(
                    child: QuillSimpleToolbar(
                      controller: _controller,
                      config: _toolbarConfig,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _focusNode.unfocus(),
                    child: Container(
                      width: 44,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                            left: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: const Icon(Icons.keyboard_hide_outlined,
                          size: 19, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _toHexColor(String color) {
    final c = color.trim().toLowerCase();
    if (RegExp(r'^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$').hasMatch(c)) return c;
    final rgb = RegExp(r'^rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$').firstMatch(c);
    if (rgb != null) {
      final r = int.parse(rgb.group(1)!).clamp(0, 255);
      final g = int.parse(rgb.group(2)!).clamp(0, 255);
      final b = int.parse(rgb.group(3)!).clamp(0, 255);
      return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    }
    const named = {
      'black': '#000000', 'white': '#ffffff', 'red': '#ff0000',
      'green': '#008000', 'blue': '#0000ff', 'yellow': '#ffff00',
      'orange': '#ffa500', 'purple': '#800080',
    };
    return named[c] ?? '#000000';
  }

  Document _fromHtml(String html) {
    if (html.trim().isEmpty) return Document();
    try {
      return Document.fromDelta(_htmlToDelta(html));
    } catch (e) {
      debugPrint('_fromHtml error: $e');
      return Document();
    }
  }

  Delta _htmlToDelta(String html) {
    final delta = Delta();
    final blockPattern = RegExp(
      r'<(p|h1|h2|h3|blockquote|ul|ol)(.*?)>(.*?)<\/\1>|<li>(.*?)<\/li>',
      dotAll: true, caseSensitive: false,
    );
    final blocks = blockPattern.allMatches(html).toList();
    if (blocks.isEmpty) {
      final plain = _stripTags(html);
      if (plain.isNotEmpty) delta.insert('$plain\n');
      return delta;
    }
    String? currentList;
    void closeList() => currentList = null;
    for (final match in blocks) {
      final tag = (match.group(1) ?? 'li').toLowerCase();
      final inner = (match.group(3) ?? match.group(4) ?? '').trim();
      if (tag == 'ul' || tag == 'ol') {
        final listType = tag == 'ul' ? 'bullet' : 'ordered';
        for (final li in RegExp(r'<li>(.*?)<\/li>', dotAll: true, caseSensitive: false).allMatches(inner)) {
          _parseInline(li.group(1) ?? '', delta);
          delta.insert('\n', {'list': listType});
        }
        closeList();
        continue;
      }
      if (tag == 'li') {
        _parseInline(inner, delta);
        delta.insert('\n', {'list': currentList == 'ordered' ? 'ordered' : 'bullet'});
        continue;
      }
      closeList();
      _parseInline(inner, delta);
      switch (tag) {
        case 'h1': delta.insert('\n', {'header': 1}); break;
        case 'h2': delta.insert('\n', {'header': 2}); break;
        case 'h3': delta.insert('\n', {'header': 3}); break;
        case 'blockquote': delta.insert('\n', {'blockquote': true}); break;
        default: delta.insert('\n');
      }
    }
    return delta;
  }

  void _parseInline(String html, Delta delta) {
    if (html.trim().isEmpty || html == '&nbsp;' || html == '<br>' || html == ' ') {
      delta.insert(' ');
      return;
    }
    final inlinePattern = RegExp(
      r'<strong>(.*?)<\/strong>|<b>(.*?)<\/b>|<em>(.*?)<\/em>|<i>(.*?)<\/i>'
      r'|<s>(.*?)<\/s>|<a href="(.*?)">(.*?)<\/a>'
      r'|<span style="color:\s*(.*?)">(.*?)<\/span>|([^<]+)',
      dotAll: true, caseSensitive: false,
    );
    for (final m in inlinePattern.allMatches(html)) {
      if (m.group(1) != null || m.group(2) != null) {
        delta.insert(_decode(m.group(1) ?? m.group(2) ?? ''), {'bold': true});
      } else if (m.group(3) != null || m.group(4) != null) {
        delta.insert(_decode(m.group(3) ?? m.group(4) ?? ''), {'italic': true});
      } else if (m.group(5) != null) {
        delta.insert(_decode(m.group(5)!), {'strike': true});
      } else if (m.group(6) != null) {
        delta.insert(_decode(m.group(7) ?? ''), {'link': m.group(6)});
      } else if (m.group(8) != null) {
        delta.insert(_decode(m.group(9) ?? ''), {'color': _toHexColor(m.group(8)!.trim())});
      } else if (m.group(10) != null) {
        final text = _decode(m.group(10)!);
        if (text.isNotEmpty) delta.insert(text);
      }
    }
  }

  String _stripTags(String html) => html.replaceAll(RegExp(r'<[^>]+>'), '');
  String _decode(String s) => s
      .replaceAll('&amp;', '&').replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>').replaceAll('&nbsp;', ' ')
      .replaceAll('&#39;', "'").replaceAll('&quot;', '"');

  void _onChanged() {
    if (_suppressCallback) return;
    widget.onChange(_DeltaToHtml.convert(_controller.document));
  }

  QuillSimpleToolbarConfig get _toolbarConfig => QuillSimpleToolbarConfig(
        multiRowsDisplay: false,
        buttonOptions: QuillSimpleToolbarButtonOptions(
          base: QuillToolbarBaseButtonOptions(
            iconSize: 19,
            iconButtonFactor: 1.15,
            iconTheme: QuillIconTheme(
              iconButtonUnselectedData: IconButtonData(
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              iconButtonSelectedData: IconButtonData(
                style: IconButton.styleFrom(
                  foregroundColor: _ET.inkPrimary,
                  backgroundColor: const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ),
        ),
        showBoldButton: true, showItalicButton: true, showStrikeThrough: true,
        showListBullets: true, showListNumbers: true, showQuote: true,
        showLink: true, showColorButton: true, showDividers: true,
        showUnderLineButton: false, showSmallButton: false,
        showInlineCode: false, showCodeBlock: false, showIndent: false,
        showBackgroundColorButton: false, showClearFormat: false,
        showAlignmentButtons: false, showSearchButton: false,
        showSubscript: false, showSuperscript: false,
        showUndo: false, showRedo: false,
        showFontFamily: false, showFontSize: false,
      );

  DefaultStyles _buildEditorStyles() {
    const baseText = TextStyle(fontSize: 15, height: 1.7, color: _ET.inkPrimary, letterSpacing: 0.1);
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(baseText, HorizontalSpacing.zero, VerticalSpacing(4, 4), VerticalSpacing.zero, null),
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      h1: DefaultTextBlockStyle(
        const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3, color: _ET.inkPrimary, letterSpacing: -0.3),
        HorizontalSpacing.zero, VerticalSpacing(12, 4), VerticalSpacing.zero, null,
      ),
      h2: DefaultTextBlockStyle(
        const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.35, color: _ET.inkPrimary, letterSpacing: -0.2),
        HorizontalSpacing.zero, VerticalSpacing(10, 4), VerticalSpacing.zero, null,
      ),
      h3: DefaultTextBlockStyle(
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: _ET.inkPrimary),
        HorizontalSpacing.zero, VerticalSpacing(8, 4), VerticalSpacing.zero, null,
      ),
      quote: DefaultTextBlockStyle(
        const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Color(0xFF6B7280), height: 1.65),
        HorizontalSpacing(16, 0), VerticalSpacing(8, 8), VerticalSpacing.zero,
        const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFD1D5DB), width: 3))),
      ),
      placeHolder: DefaultTextBlockStyle(
        const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFFBBBBBB)),
        HorizontalSpacing.zero, VerticalSpacing.zero, VerticalSpacing.zero, null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.5)),
          const SizedBox(height: 6),
        ],
        Container(
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            color: _ET.surface,
            borderRadius: BorderRadius.circular(_ET.radius),
            border: Border.all(color: _ET.border, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_ET.radius - 1.5),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
                config: QuillEditorConfig(
                  placeholder: widget.placeholder,
                  padding: EdgeInsets.zero,
                  autoFocus: false,
                  expands: false,
                  scrollable: false,
                  customStyles: _buildEditorStyles(),
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: _focused
              ? Padding(
                  padding: const EdgeInsets.only(top: 4, right: 2),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (_, __) {
                        final count = _controller.document.toPlainText().trim().length;
                        return Text('$count chars',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFFBBBBBB)));
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}