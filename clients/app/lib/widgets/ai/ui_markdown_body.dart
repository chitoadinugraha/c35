import 'package:alienai_c35/widgets/ai/ui_markdown_code_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

const uiMarkdownChatText = Color(0xFFF4F4F5);
const uiMarkdownChatCodeBg = Color(0xFF1A1A1D);

final uiMarkdownLatexBlockSyntaxes = <md.BlockSyntax>[LatexBlockSyntax()];
final uiMarkdownLatexInlineSyntaxes = <md.InlineSyntax>[LatexInlineSyntax()];

MarkdownStyleSheet uiMarkdownChatStyleSheet({
  TextStyle? p,
  TextStyle? code,
  TextStyle? h1,
  TextStyle? h2,
  TextStyle? h3,
}) =>
    MarkdownStyleSheet(
      p: p ?? const TextStyle(color: uiMarkdownChatText, fontSize: 15, height: 1.45),
      h1: h1 ?? const TextStyle(color: uiMarkdownChatText, fontSize: 20, fontWeight: FontWeight.bold),
      h2: h2 ?? const TextStyle(color: uiMarkdownChatText, fontSize: 17, fontWeight: FontWeight.bold),
      h3: h3 ?? const TextStyle(color: uiMarkdownChatText, fontSize: 15, fontWeight: FontWeight.w600),
      code: code ??
          const TextStyle(
            color: uiMarkdownChatText,
            fontSize: 13,
            fontFamily: 'Consolas',
            backgroundColor: uiMarkdownChatCodeBg,
          ),
      tableHead: const TextStyle(color: uiMarkdownChatText, fontWeight: FontWeight.w600),
      tableBody: const TextStyle(color: uiMarkdownChatText),
      tableBorder: TableBorder.all(color: Color(0xFF3F3F46)),
    );

class UiMarkdownLatexBuilder extends MarkdownElementBuilder {
  UiMarkdownLatexBuilder({this.textStyle, this.textScaleFactor});

  final TextStyle? textStyle;
  final double? textScaleFactor;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent;
    if (tex.isEmpty) return const SizedBox.shrink();

    final mathStyle = element.attributes['MathStyle'] == 'display' ? MathStyle.display : MathStyle.text;
    final style = textStyle ?? preferredStyle ?? parentStyle ?? const TextStyle(color: uiMarkdownChatText, fontSize: 15);

    final math = Math.tex(
      tex,
      textStyle: style,
      mathStyle: mathStyle,
      textScaleFactor: textScaleFactor,
      onErrorFallback: (_) => _latexFallback(tex, style),
    );

    if (mathStyle == MathStyle.display) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(alignment: Alignment.center, child: math),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.hardEdge,
      child: math,
    );
  }

  Widget _latexFallback(String tex, TextStyle style) => Text(
        tex,
        style: style.copyWith(
          fontFamily: 'Consolas',
          fontSize: (style.fontSize ?? 15) * 0.92,
          color: const Color(0xFFA1A1AA),
        ),
      );
}

/// GitHub-flavored markdown with LaTeX and custom code blocks.
class UiMarkdownBody extends StatelessWidget {
  const UiMarkdownBody({
    super.key,
    required this.data,
    this.selectable = false,
    this.styleSheet,
    this.onOpenInCanvas,
  });

  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;
  final void Function(String title, String code, String language)? onOpenInCanvas;

  @override
  Widget build(BuildContext context) {
    final sheet = styleSheet ?? uiMarkdownChatStyleSheet();
    final latexStyle = sheet.p;
    return MarkdownBody(
      data: data,
      selectable: selectable,
      blockSyntaxes: uiMarkdownLatexBlockSyntaxes,
      inlineSyntaxes: uiMarkdownLatexInlineSyntaxes,
      builders: {
        'latex': UiMarkdownLatexBuilder(textStyle: latexStyle),
        'code': UiMarkdownCodeBlockBuilder(onOpenInCanvas: onOpenInCanvas),
      },
      styleSheet: sheet,
    );
  }
}