import 'package:flutter/material.dart';

class UiImg extends StatelessWidget {
  const UiImg({super.key, required this.src, this.fit = BoxFit.cover, this.width, this.height, this.fallback});

  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final s = src.trim();
    if (s.isEmpty) return fallback ?? const SizedBox.shrink();
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return Image.network(s, fit: fit, width: width, height: height, errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink());
    }
    return fallback ?? const SizedBox.shrink();
  }
}
