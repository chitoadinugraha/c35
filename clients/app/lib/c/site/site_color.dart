import 'package:flutter/material.dart';

/// Solid palette for work-shift legend colors (CSA `site_color.dart` subset).
const sitePaletteColors = [
  '#6366F1',
  '#EC4899',
  '#F59E0B',
  '#10B981',
  '#3B82F6',
  '#8B5CF6',
  '#EF4444',
  '#14B8A6',
  '#F472B6',
  '#22D3EE',
  '#A3E635',
  '#FB923C',
  '#E2E8F0',
  '#1E293B',
];

Color siteColorParse(String hex) {
  final parts = hex.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
  final raw = (parts.isEmpty ? hex : parts.first).replaceAll('#', '').trim();
  if (raw.length != 6) return const Color(0xFF6366F1);
  return Color(int.parse('FF$raw', radix: 16));
}

String sitePaletteColorAt(int index) => sitePaletteColors[index % sitePaletteColors.length];
