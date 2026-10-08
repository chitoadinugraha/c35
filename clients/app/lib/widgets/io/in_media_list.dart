import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// Horizontal list of image paths with add / remove (upload handled by parent).
class InMediaList extends StatelessWidget {
  const InMediaList({
    super.key,
    required this.paths,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    this.thumbSize = 72,
    this.maxCount = 12,
  });

  final List<String> paths;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final double thumbSize;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final canAdd = enabled && paths.length < maxCount;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < paths.length; i++)
          _MediaThumb(
            path: paths[i],
            size: thumbSize,
            enabled: enabled,
            onRemove: () => onRemove(i),
          ),
        if (canAdd) _AddThumb(size: thumbSize, onTap: onAdd),
      ],
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({required this.path, required this.size, required this.enabled, required this.onRemove});

  final String path;
  final double size;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: UiImg(
              src: path,
              width: size,
              height: size,
              fit: BoxFit.cover,
              fallback: const Icon(Icons.broken_image_outlined, color: _muted),
            ),
          ),
          if (enabled)
            Positioned(
              top: -6,
              right: -6,
              child: Material(
                color: const Color(0xFF27272A),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: siteEditorFormText),
                  ),
                ),
              ),
            ),
        ],
      );
}

class _AddThumb extends StatelessWidget {
  const _AddThumb({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: siteEditorFieldFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: siteEditorFieldBorder.withValues(alpha: 0.9)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: const Icon(Icons.add_photo_alternate_outlined, color: _muted, size: 26),
          ),
        ),
      );
}
