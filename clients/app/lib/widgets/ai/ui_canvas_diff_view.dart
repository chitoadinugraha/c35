import 'package:alienai_c35/c/canvas/canvas_diff.dart';
import 'package:flutter/material.dart';

class UiCanvasDiffView extends StatelessWidget {
  const UiCanvasDiffView({
    super.key,
    required this.oldTitle,
    required this.newTitle,
    required this.diffLines,
  });

  final String oldTitle;
  final String newTitle;
  final List<CanvasDiffLine> diffLines;

  static const _bg = Color(0xFF0C0C0E);
  static const _headerBg = Color(0xFF141418);
  static const _border = Color(0xFF27272A);
  static const _gutterColor = Color(0xFF4A4A52);
  static const _addedBg = Color(0x1822C55E);
  static const _addedText = Color(0xFF4ADE80);
  static const _removedBg = Color(0x18EF4444);
  static const _removedText = Color(0xFFF87171);
  static const _unchangedText = Color(0xFFD4D4D8);

  @override
  Widget build(BuildContext context) {
    final addedCount = diffLines.where((l) => l.type == DiffLineType.added).length;
    final removedCount = diffLines.where((l) => l.type == DiffLineType.removed).length;

    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Diff Subheader
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: _headerBg,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows_rounded, size: 15, color: Color(0xFF06B6D4)),
                const SizedBox(width: 8),
                Text(
                  'Comparing $oldTitle ➔ $newTitle',
                  style: const TextStyle(
                    color: Color(0xFFF4F4F5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _addedBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+$addedCount',
                    style: const TextStyle(
                      color: _addedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _removedBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-$removedCount',
                    style: const TextStyle(
                      color: _removedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Diff Lines
          Expanded(
            child: diffLines.isEmpty
                ? const Center(
                    child: Text(
                      'No differences detected',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final line in diffLines) _diffLineRow(line),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _diffLineRow(CanvasDiffLine line) {
    Color bg = Colors.transparent;
    Color textColor = _unchangedText;
    String sign = ' ';

    if (line.type == DiffLineType.added) {
      bg = _addedBg;
      textColor = _addedText;
      sign = '+';
    } else if (line.type == DiffLineType.removed) {
      bg = _removedBg;
      textColor = _removedText;
      sign = '-';
    }

    final oldNum = line.oldLine != null ? '${line.oldLine}' : '';
    final newNum = line.newLine != null ? '${line.newLine}' : '';

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Old line gutter
          SizedBox(
            width: 28,
            child: Text(
              oldNum,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: _gutterColor,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // New line gutter
          SizedBox(
            width: 28,
            child: Text(
              newNum,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: _gutterColor,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sign
          SizedBox(
            width: 14,
            child: Text(
              sign,
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Content
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                line.text,
                style: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 13,
                  color: textColor,
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
