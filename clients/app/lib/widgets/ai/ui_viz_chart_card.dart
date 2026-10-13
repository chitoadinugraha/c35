import 'package:alienai_c35/c/viz/viz_chart_data.dart';
import 'package:flutter/material.dart';

class UiVizChartCard extends StatelessWidget {
  const UiVizChartCard({super.key, required this.data});

  final VizChartData data;

  static const _palette = [
    Color(0xFF06B6D4),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.title.isNotEmpty)
                Text(data.title, style: Theme.of(context).textTheme.titleMedium),
              if (data.series.length > 1) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < data.series.length; i++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _palette[i % _palette.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(data.series[i].name, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: data.chartType == 'pie' ? 200 : 220,
                width: double.infinity,
                child: CustomPaint(
                  painter: _VizChartPainter(data: data, palette: _palette),
                ),
              ),
              if (data.xLabel.isNotEmpty || data.yLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    [if (data.yLabel.isNotEmpty) data.yLabel, if (data.xLabel.isNotEmpty) data.xLabel]
                        .join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VizChartPainter extends CustomPainter {
  _VizChartPainter({required this.data, required this.palette});

  final VizChartData data;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    switch (data.chartType) {
      case 'pie':
        _paintPie(canvas, size);
      case 'line':
        _paintLine(canvas, size);
      default:
        _paintBar(canvas, size);
    }
  }

  void _paintBar(Canvas canvas, Size size) {
    final series = data.series.first;
    final maxV = series.values.fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxV <= 0 ? 1.0 : maxV * 1.1;
    final bottomPad = 28.0;
    final chartH = size.height - bottomPad;
    final n = data.labels.length;
    if (n == 0) return;
    final groupW = size.width / n;
    final barW = groupW * 0.55;
    for (var i = 0; i < n; i++) {
      final v = series.values[i];
      final h = (v / top) * chartH;
      final x = i * groupW + (groupW - barW) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartH - h, barW, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = palette[0]);
      _drawLabel(canvas, data.labels[i], Offset(x + barW / 2, chartH + 4), size.width / n);
    }
  }

  void _paintLine(Canvas canvas, Size size) {
    final bottomPad = 28.0;
    final chartH = size.height - bottomPad;
    final n = data.labels.length;
    if (n < 2) return;
    var maxV = 0.0;
    for (final s in data.series) {
      for (final v in s.values) {
        if (v > maxV) maxV = v;
      }
    }
    final top = maxV <= 0 ? 1.0 : maxV * 1.1;
    final stepX = size.width / (n - 1);
    for (var si = 0; si < data.series.length; si++) {
      final s = data.series[si];
      final path = Path();
      for (var i = 0; i < n; i++) {
        final x = i * stepX;
        final y = chartH - (s.values[i] / top) * chartH;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = palette[si % palette.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    for (var i = 0; i < n; i++) {
      _drawLabel(canvas, data.labels[i], Offset(i * stepX, chartH + 4), stepX);
    }
  }

  void _paintPie(Canvas canvas, Size size) {
    final s = data.series.first;
    final total = s.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    var start = -3.1415926535 / 2;
    for (var i = 0; i < s.values.length; i++) {
      final sweep = (s.values[i] / total) * 3.1415926535 * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = palette[i % palette.length],
      );
      start += sweep;
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset anchor, double maxW) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: Color(0xFFA1A1AA)),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    tp.paint(canvas, Offset(anchor.dx - tp.width / 2, anchor.dy));
  }

  @override
  bool shouldRepaint(covariant _VizChartPainter oldDelegate) => oldDelegate.data != data;
}
