import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

const effectStartDelay = Duration(milliseconds: 100);

/// True when overlay param maps differ (identity or values).
bool effectParamsChanged(Map<String, Object?> a, Map<String, Object?> b) => !mapEquals(a, b);

double effectRand01(double seed) {
  final x = math.sin(seed * 12989.0) * 43758.5453;
  return x - x.floor();
}

Color effectParseColor(String hex, {Color fallback = const Color(0xFFFFFFFF)}) {
  final s = hex.trim().replaceFirst('#', '');
  if (s.length != 6) return fallback;
  final value = int.tryParse(s, radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}

String effectColorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

void effectSimResize({
  required Size current,
  required Size next,
  required void Function(Size size) onSize,
  required void Function() respawn,
}) {
  if (next.width <= 0 || next.height <= 0) return;
  if (current == next) return;
  final dimensionChanged = current == Size.zero ||
      (next.width - current.width).abs() > 1 ||
      (next.height - current.height).abs() > 1;
  onSize(next);
  if (dimensionChanged) respawn();
}
