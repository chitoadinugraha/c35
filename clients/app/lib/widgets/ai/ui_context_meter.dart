import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiContextMeter extends StatelessWidget {
  const UiContextMeter({
    super.key,
    required this.tokensIn,
    required this.tokensOut,
    this.contextLimit = 128000,
    this.costUsd = 0.0,
  });

  final int tokensIn;
  final int tokensOut;
  final int contextLimit;
  final double costUsd;

  int get totalTokens => tokensIn + tokensOut;
  double get fraction => contextLimit > 0 ? (totalTokens / contextLimit).clamp(0.0, 1.0) : 0.0;

  String _formatK(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  String _formatComma(int n) {
    final s = n.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  Color _progressColor() {
    if (fraction >= 0.9) return const Color(0xFFEF4444); // red
    if (fraction >= 0.7) return const Color(0xFFF59E0B); // amber
    return const Color(0xFF06B6D4); // cyan
  }

  @override
  Widget build(BuildContext context) {
    if (totalTokens <= 0) return const SizedBox.shrink();

    final percent = (fraction * 100).toStringAsFixed(fraction >= 0.1 ? 0 : 1);
    final color = _progressColor();

    final tooltipText = 'Context Window:\n'
        '• Input: ${_formatComma(tokensIn)} tokens\n'
        '• Output: ${_formatComma(tokensOut)} tokens\n'
        '• Total: ${_formatComma(totalTokens)} / ${_formatComma(contextLimit)} ($percent%)\n'
        '${costUsd > 0 ? '• Est. Cost: \$${costUsd.toStringAsFixed(4)}' : ''}';

    return uiTooltip(
      message: tooltipText.trim(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 2,
                backgroundColor: const Color(0xFF27272A),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${_formatK(totalTokens)} ($percent%)',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Consolas',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
