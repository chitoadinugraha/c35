import 'package:flutter/material.dart';

/// Logical viewport for guest site preview (iPhone-class).
const sitePhonePreviewLogicalW = 390.0;
const sitePhonePreviewLogicalH = 844.0;

/// CSA-style device bezel around live site preview (fixed size for floorplan stage).
class UiSitePhonePreviewFrame extends StatelessWidget {
  const UiSitePhonePreviewFrame({super.key, required this.child, this.scale = 1});

  static const phoneW = sitePhonePreviewLogicalW;
  static const phoneH = sitePhonePreviewLogicalH;

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Transform.scale(
      scale: scale,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: phoneW,
        height: phoneH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? const Color(0xFF3F3F46) : const Color(0xFF27272A), width: 6),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 12))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: ColoredBox(color: Colors.black, child: child),
          ),
        ),
      ),
    );
  }
}
