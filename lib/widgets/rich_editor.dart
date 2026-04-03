import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Delta → HTML  (lightweight, no extra package)
// ─────────────────────────────────────────────────────────────────────────────
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
      if (text.isEmpty && la.isEmpty) return;
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
          buf.write('<p>${text.isEmpty ? '&nbsp;' : text}</p>');
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

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
abstract class _EditorTheme {
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color toolbarBg     = Color(0xFFFAFAFA);
  static const Color border        = Color(0xFFE8E8E8);
  static const Color borderFocused = Color(0xFF1A1A1A);
  static const Color divider       = Color(0xFFEEEEEE);
  static const Color inkPrimary    = Color(0xFF1A1A1A);
  static const Color inkMuted      = Color(0xFF8A8A8A);
  static const double radius       = 10.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// RichEditorWidget — flutter_quill ^11.5.0
//
// pubspec.yaml:
//   flutter_quill: ^11.5.0
//   flutter_quill_delta_from_html: ^2.0.0
//
// MaterialApp.localizationsDelegates:
//   FlutterQuillLocalizations.delegate,
//   GlobalMaterialLocalizations.delegate,
//   GlobalCupertinoLocalizations.delegate,
//   GlobalWidgetsLocalizations.delegate,
// ─────────────────────────────────────────────────────────────────────────────
class RichEditorWidget extends StatefulWidget {
  final String content;
  final ValueChanged<String> onChange;
  final String placeholder;
  final String? label;

  const RichEditorWidget({
    super.key,
    required this.content,
    required this.onChange,
    this.placeholder = 'Write here…',
    this.label,
  });

  @override
  State<RichEditorWidget> createState() => _RichEditorWidgetState();
}

class _RichEditorWidgetState extends State<RichEditorWidget>
    with SingleTickerProviderStateMixin {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _suppressCallback = false;
  bool _focused = false;
  int _charCount = 0;

  late final AnimationController _borderAnim;
  late final Animation<double> _borderProgress;

  @override
  void initState() {
    super.initState();

    _borderAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _borderProgress = CurvedAnimation(
      parent: _borderAnim,
      curve: Curves.easeOut,
    );

    _controller = QuillController(
      document: _fromHtml(widget.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _charCount = _controller.document.toPlainText().trim().length;
    _controller.addListener(_onChanged);

    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
      _focused ? _borderAnim.forward() : _borderAnim.reverse();
    });
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

  Document _fromHtml(String html) {
    if (html.trim().isEmpty) return Document();
    try {
      final delta = HtmlToDelta().convert(html);
      return Document.fromDelta(delta);
    } catch (_) {
      return Document();
    }
  }

  void _onChanged() {
    if (_suppressCallback) return;
    setState(() {
      _charCount = _controller.document.toPlainText().trim().length;
    });
    widget.onChange(_DeltaToHtml.convert(_controller.document));
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    _borderAnim.dispose();
    super.dispose();
  }

  // ── v11 toolbar config ───────────────────────────────────────────────────
  // QuillIconTheme in v11 uses iconButtonUnselectedData / iconButtonSelectedData
  // (type IconButtonData with a ButtonStyle). The old color-based properties
  // were removed in the v9→v10 breaking change.
  QuillSimpleToolbarConfig get _toolbarConfig => QuillSimpleToolbarConfig(
        multiRowsDisplay: false,
        buttonOptions: QuillSimpleToolbarButtonOptions(
          base: QuillToolbarBaseButtonOptions(
            iconSize: 18,
            iconButtonFactor: 1.2,
            iconTheme: QuillIconTheme(
              iconButtonUnselectedData: IconButtonData(
                style: IconButton.styleFrom(
                  foregroundColor: _EditorTheme.inkMuted,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              iconButtonSelectedData: IconButtonData(
                style: IconButton.styleFrom(
                  foregroundColor: _EditorTheme.inkPrimary,
                  backgroundColor: const Color(0xFFEEEEEE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        showBoldButton: true,
        showItalicButton: true,
        showStrikeThrough: true,
        showListBullets: true,
        showListNumbers: true,
        showQuote: true,
        showLink: true,
        showColorButton: true,
        showDividers: true,
        showUnderLineButton: false,
        showSmallButton: false,
        showInlineCode: false,
        showCodeBlock: false,
        showIndent: false,
        showBackgroundColorButton: false,
        showClearFormat: false,
        showAlignmentButtons: false,
        showSearchButton: false,
        showSubscript: false,
        showSuperscript: false,
        showUndo: false,
        showRedo: false,
        showFontFamily: false,
        showFontSize: false,
      );

  // ── Typography ───────────────────────────────────────────────────────────
  DefaultStyles _buildEditorStyles() {
    const baseText = TextStyle(
      fontSize: 15,
      height: 1.65,
      color: _EditorTheme.inkPrimary,
      letterSpacing: 0.1,
    );
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseText,
        HorizontalSpacing.zero,
        VerticalSpacing(4, 4),
        VerticalSpacing.zero,
        null,
      ),
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      h1: DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: _EditorTheme.inkPrimary,
          letterSpacing: -0.3,
        ),
        HorizontalSpacing.zero,
        VerticalSpacing(12, 4),
        VerticalSpacing.zero,
        null,
      ),
      h2: DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: _EditorTheme.inkPrimary,
          letterSpacing: -0.2,
        ),
        HorizontalSpacing.zero,
        VerticalSpacing(10, 4),
        VerticalSpacing.zero,
        null,
      ),
      h3: DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: _EditorTheme.inkPrimary,
        ),
        HorizontalSpacing.zero,
        VerticalSpacing(8, 4),
        VerticalSpacing.zero,
        null,
      ),
      quote: DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: Color(0xFF6B7280),
          height: 1.65,
        ),
        HorizontalSpacing(16, 0),
        VerticalSpacing(8, 8),
        VerticalSpacing.zero,
        const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xFFD1D5DB), width: 3),
          ),
        ),
      ),
      placeHolder: DefaultTextBlockStyle(
        const TextStyle(
          fontSize: 15,
          height: 1.65,
          color: Color(0xFFBBBBBB),
        ),
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _EditorTheme.inkPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedBuilder(
          animation: _borderProgress,
          builder: (context, child) {
            final borderColor = Color.lerp(
              _EditorTheme.border,
              _EditorTheme.borderFocused,
              _borderProgress.value,
            )!;
            return Container(
              decoration: BoxDecoration(
                color: _EditorTheme.surface,
                borderRadius: BorderRadius.circular(_EditorTheme.radius),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_EditorTheme.radius - 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildToolbar(),
                Container(height: 1, color: _EditorTheme.divider),
                _buildEditor(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() => Container(
        height: 44,
        color: _EditorTheme.toolbarBg,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: QuillSimpleToolbar(
                controller: _controller,
                config: _toolbarConfig,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                '$_charCount',
                style: TextStyle(
                  fontSize: 11,
                  color: _EditorTheme.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEditor() => Container(
        constraints: const BoxConstraints(minHeight: 180),
        color: _EditorTheme.surface,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated left accent bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 3,
                color: _focused
                    ? _EditorTheme.inkPrimary
                    : Colors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: QuillEditor.basic(
                    controller: _controller,
                    focusNode: _focusNode,
                    config: QuillEditorConfig(
                      placeholder: widget.placeholder,
                      padding: EdgeInsets.zero,
                      autoFocus: false,
                      expands: false,
                      scrollable: true,
                      customStyles: _buildEditorStyles(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFooter() => Container(
        height: 30,
        color: _EditorTheme.toolbarBg,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _focused
                    ? const Color(0xFF22C55E)
                    : _EditorTheme.border,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                color: _focused
                    ? const Color(0xFF16A34A)
                    : _EditorTheme.inkMuted,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w500,
              ),
              child: Text(_focused ? 'Editing' : 'Click to edit'),
            ),
            const Spacer(),
            Text(
              '$_charCount char${_charCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 10.5,
                color: _EditorTheme.inkMuted,
                letterSpacing: 0.3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}