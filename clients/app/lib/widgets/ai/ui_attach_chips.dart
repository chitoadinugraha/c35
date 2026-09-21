import 'dart:async';

import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/widgets/ai/ui_staged_shot.dart';
import 'package:flutter/material.dart';

class UiAttachChips extends StatelessWidget {
  const UiAttachChips({super.key, required this.attachments, this.alignEnd = false});
  final List<MsgAttachment> attachments;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final images = attachments.where((a) => a.isImage && (a.hasRemote || a.hasLocalPreview)).toList();
    final files = attachments.where((a) => !a.isImage || (!a.hasRemote && !a.hasLocalPreview)).toList();
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (images.isNotEmpty) _ImageGrid(images: images),
        if (files.isNotEmpty) ...[
          if (images.isNotEmpty) const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
            children: [
              for (final a in files)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFFA1A1AA)),
                  label: Text(a.name.isEmpty ? a.hash : a.name, style: const TextStyle(fontSize: 11, color: Color(0xFFE4E4E7))),
                  backgroundColor: const Color(0xFF18181B),
                  side: const BorderSide(color: Color(0xFF27272A)),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images});
  final List<MsgAttachment> images;

  @override
  Widget build(BuildContext context) {
    final n = images.length;
    if (n == 1) return _thumb(context, images.first, width: 220, height: 180);
    final size = n <= 4 ? 132.0 : 100.0;
    return Wrap(spacing: 4, runSpacing: 4, children: [for (final a in images) _thumb(context, a, width: size, height: size)]);
  }

  void _openPreview(BuildContext context, MsgAttachment a) {
    if (a.hasLocalPreview) {
      unawaited(stagedShotPreview(context, bytes: a.localBytes!, name: a.name, editable: false));
      return;
    }
    if (a.hasRemote) unawaited(stagedShotPreview(context, servePath: a.servePath, name: a.name, editable: false));
  }

  Widget _thumb(BuildContext context, MsgAttachment a, {required double width, required double height}) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: const Color(0xFF141416),
          child: UiShotThumb(
            bytes: a.hasLocalPreview ? a.localBytes : null,
            servePath: a.hasRemote ? a.servePath : '',
            width: width,
            height: height,
            onTap: () => _openPreview(context, a),
          ),
        ),
      );
}
