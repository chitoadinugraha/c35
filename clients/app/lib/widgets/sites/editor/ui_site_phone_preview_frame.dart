import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logical viewport for guest site preview (iPhone-class).
const sitePhonePreviewLogicalW = 390.0;
const sitePhonePreviewLogicalH = 844.0;

/// CSA-style device bezel around live site preview.
class UiSitePhonePreviewFrame extends StatelessWidget {
  const UiSitePhonePreviewFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const bezel = 10.0;
          const outerRadius = 36.0;
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          if (maxW <= 0 || maxH <= 0) return const SizedBox.shrink();

          final innerW = sitePhonePreviewLogicalW;
          final innerH = sitePhonePreviewLogicalH;
          final scale = math.min(
            (maxW - bezel * 2) / innerW,
            (maxH - bezel * 2) / innerH,
          ).clamp(0.35, 1.0);
          final frameW = innerW * scale + bezel * 2;
          final frameH = innerH * scale + bezel * 2;

          return Center(
            child: SizedBox(
              width: frameW,
              height: frameH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(outerRadius * scale),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF52525B), Color(0xFF27272A), Color(0xFF3F3F46)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(bezel * scale),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular((outerRadius - 6) * scale),
                      border: Border.all(color: const Color(0xFF18181B), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular((outerRadius - 8) * scale),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            child: SizedBox(width: innerW, height: innerH, child: child),
                          ),
                          Positioned(
                            top: 10 * scale,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 96 * scale,
                                height: 26 * scale,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20 * scale),
                                  border: Border.all(color: const Color(0xFF27272A)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
