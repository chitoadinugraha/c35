import 'dart:math' as math;

import 'package:alienai_c35/c/media/media_types.dart';
import 'package:flutter/material.dart';

const double _kTileHeight = 56.0;
const double _kTileRadius = 12.0;
const Color _kTileBg = Color(0xFF18181B);
const Color _kTileBorder = Color(0xFF27272A);

class InMedia extends StatelessWidget {
  const InMedia({super.key, required this.items, required this.onRemove, this.enabled = true, this.compact = false});
  final List<StagedMedia> items;
  final ValueChanged<int> onRemove;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: compact ? null : double.infinity,
      padding: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10, left: 4, right: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _InMediaItem(item: items[i], enabled: enabled, onRemove: () => onRemove(i)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InMediaItem extends StatelessWidget {
  const _InMediaItem({required this.item, required this.enabled, required this.onRemove});
  final StagedMedia item;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => item.isImage
      ? _InMediaImageTile(item: item, enabled: enabled, onRemove: onRemove)
      : _InMediaDocumentTile(item: item, enabled: enabled, onRemove: onRemove);
}

class _InMediaImageTile extends StatefulWidget {
  const _InMediaImageTile({required this.item, required this.enabled, required this.onRemove});
  final StagedMedia item;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  State<_InMediaImageTile> createState() => _InMediaImageTileState();
}

class _InMediaImageTileState extends State<_InMediaImageTile> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.item.isUploading) _anim.repeat();
  }

  @override
  void didUpdateWidget(covariant _InMediaImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.isUploading && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!widget.item.isUploading && _anim.isAnimating) {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final imageContent = item.bytes.isNotEmpty
        ? Image.memory(item.bytes, fit: BoxFit.cover, width: _kTileHeight, height: _kTileHeight, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, color: Color(0xFF71717A), size: 22))
        : const Icon(Icons.image_outlined, color: Color(0xFF71717A), size: 22);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) => CustomPaint(
            foregroundPainter: _OutlineProgressPainter(progress: item.uploadProgress, isUploading: item.isUploading, sweepPhase: _anim.value, borderRadius: _kTileRadius, strokeWidth: item.isUploading ? 2.0 : 1.0, baseColor: _kTileBorder, activeColor: const Color(0xFF38BDF8)),
            child: child,
          ),
          child: Container(
            width: _kTileHeight,
            height: _kTileHeight,
            decoration: BoxDecoration(color: _kTileBg, borderRadius: BorderRadius.circular(_kTileRadius), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 2))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(_kTileRadius - 1), child: imageContent),
          ),
        ),
        if (widget.enabled) Positioned(top: -5, right: -5, child: _RemoveButton(onTap: widget.onRemove)),
      ],
    );
  }
}

class _InMediaDocumentTile extends StatefulWidget {
  const _InMediaDocumentTile({required this.item, required this.enabled, required this.onRemove});
  final StagedMedia item;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  State<_InMediaDocumentTile> createState() => _InMediaDocumentTileState();
}

class _InMediaDocumentTileState extends State<_InMediaDocumentTile> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.item.isUploading) _anim.repeat();
  }

  @override
  void didUpdateWidget(covariant _InMediaDocumentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.isUploading && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!widget.item.isUploading && _anim.isAnimating) {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  IconData _iconForDoc() {
    final lower = widget.item.name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return Icons.description_rounded;
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.csv')) return Icons.table_chart_rounded;
    if (lower.endsWith('.zip')) return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPdf = item.name.toLowerCase().endsWith('.pdf');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) => CustomPaint(
            foregroundPainter: _OutlineProgressPainter(progress: item.uploadProgress, isUploading: item.isUploading, sweepPhase: _anim.value, borderRadius: _kTileRadius, strokeWidth: item.isUploading ? 2.0 : 1.0, baseColor: _kTileBorder, activeColor: const Color(0xFF38BDF8)),
            child: child,
          ),
          child: Container(
            height: _kTileHeight,
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 230),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: _kTileBg, borderRadius: BorderRadius.circular(_kTileRadius), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: isPdf ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF27272A), borderRadius: BorderRadius.circular(9)),
                  child: Icon(_iconForDoc(), size: 20, color: isPdf ? const Color(0xFFEF4444) : const Color(0xFFA1A1AA)),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 13, fontWeight: FontWeight.w500, height: 1.2)),
                      const SizedBox(height: 3),
                      Text(
                        item.isUploading ? 'Uploading ${math.max(5, ((item.uploadProgress ?? 0) * 100).toInt())}%…' : (item.formattedSize.isNotEmpty ? item.formattedSize : 'Attached'),
                        maxLines: 1,
                        style: TextStyle(color: item.isUploading ? const Color(0xFF38BDF8) : const Color(0xFF71717A), fontSize: 11, height: 1.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.enabled) Positioned(top: -5, right: -5, child: _RemoveButton(onTap: widget.onRemove)),
      ],
    );
  }
}

class _OutlineProgressPainter extends CustomPainter {
  const _OutlineProgressPainter({required this.progress, required this.isUploading, required this.sweepPhase, required this.borderRadius, required this.strokeWidth, required this.baseColor, required this.activeColor});
  final double? progress;
  final bool isUploading;
  final double sweepPhase;
  final double borderRadius;
  final double strokeWidth;
  final Color baseColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius((Offset.zero & size).deflate(strokeWidth / 2), Radius.circular(borderRadius));
    final bgPaint = Paint()..color = isUploading ? baseColor.withValues(alpha: 0.3) : baseColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, bgPaint);
    if (!isUploading && (progress == null || progress! <= 0 || progress! >= 1.0)) return;
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final totalLen = metric.length;
    final activePaint = Paint()..color = activeColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    if (isUploading) {
      final segmentLen = totalLen * 0.35;
      final start = (sweepPhase * totalLen) % totalLen;
      final end = start + segmentLen;
      if (end <= totalLen) {
        canvas.drawPath(metric.extractPath(start, end), activePaint);
      } else {
        canvas.drawPath(metric.extractPath(start, totalLen), activePaint);
        canvas.drawPath(metric.extractPath(0, end - totalLen), activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OutlineProgressPainter old) => old.progress != progress || old.isUploading != isUploading || old.sweepPhase != sweepPhase;
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF27272A),
        shape: const CircleBorder(side: BorderSide(color: Color(0xFF3F3F46), width: 1.2)),
        elevation: 4,
        child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.close_rounded, size: 13, color: Color(0xFFF4F4F5)))),
      );
}
