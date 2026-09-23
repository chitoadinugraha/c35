import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

class UiMarkdownCodeBlock extends StatefulWidget {
  const UiMarkdownCodeBlock({
    super.key,
    required this.code,
    required this.language,
    this.onOpenInCanvas,
  });

  final String code;
  final String language;
  final void Function(String title, String code, String language)? onOpenInCanvas;

  @override
  State<UiMarkdownCodeBlock> createState() => _UiMarkdownCodeBlockState();
}

class _UiMarkdownCodeBlockState extends State<UiMarkdownCodeBlock> {
  static const _bg = Color(0xFF121215);
  static const _headerBg = Color(0xFF18181C);
  static const _border = Color(0xFF27272A);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFF71717A);
  static const _accent = Color(0xFF06B6D4);

  var _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  void _openInCanvas() {
    final lang = widget.language.trim().toLowerCase();
    final ext = lang.isEmpty || lang == 'text' ? 'txt' : lang;
    final title = 'snippet.$ext';
    widget.onOpenInCanvas?.call(title, widget.code, widget.language);
  }

  @override
  Widget build(BuildContext context) {
    final displayLang = widget.language.isNotEmpty ? widget.language.toUpperCase() : 'CODE';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: _headerBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Text(
                  displayLang,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (widget.onOpenInCanvas != null) ...[
                  InkWell(
                    onTap: _openInCanvas,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.view_sidebar_rounded, size: 13, color: _accent),
                          SizedBox(width: 4),
                          Text(
                            'Open in Canvas',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                uiIconButton(
                  tooltip: _copied ? 'Copied!' : 'Copy code',
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    color: _copied ? _accent : _muted,
                    size: 14,
                  ),
                  onPressed: _copy,
                ),
              ],
            ),
          ),
          // Code Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                widget.code,
                style: const TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontFamily: 'Consolas',
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UiMarkdownCodeBlockBuilder extends MarkdownElementBuilder {
  UiMarkdownCodeBlockBuilder({this.onOpenInCanvas});

  final void Function(String title, String code, String language)? onOpenInCanvas;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    final isBlock = text.contains('\n') || element.attributes.containsKey('class');

    if (!isBlock) {
      // Inline code chip
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFF4F4F5),
            fontSize: 13,
            fontFamily: 'Consolas',
          ),
        ),
      );
    }

    final rawClass = element.attributes['class'] ?? '';
    final lang = rawClass.startsWith('language-') ? rawClass.substring(9) : '';
    final code = text.endsWith('\n') ? text.substring(0, text.length - 1) : text;

    return UiMarkdownCodeBlock(
      code: code,
      language: lang,
      onOpenInCanvas: onOpenInCanvas,
    );
  }
}
