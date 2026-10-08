import 'package:flutter/material.dart';

/// Solid palette (queues, counters, etc.).
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

/// Outline / accent swatches — solids plus multi-stop gradients (c-site style).
const sitePaletteSwatches = [
  ...sitePaletteColors,
  // Alien
  '#818CF8,#C084FC,#22D3EE',
  // Neon Tokyo
  '#FF2D6A,#00D4FF,#F5E642',
  // Sakura
  '#FFB7C5,#F4A4B8,#C084FC',
  // Nord
  '#88C0D0,#81A1C1,#5E81AC',
  // Sunset
  '#F59E0B,#EF4444,#EC4899',
  // Luxury
  '#D4AF37,#F5F0E8,#C9B896',
  // Zen
  '#8B9A7D,#C4B896,#E8E4DC',
  // Ocean
  '#0EA5E9,#06B6D4,#67E8F9',
  // Forest
  '#166534,#22C55E,#86EFAC',
  // Magma
  '#7F1D1D,#EF4444,#FBBF24',
  // Aurora
  '#22D3EE,#A78BFA,#F472B6',
  // Midnight
  '#1E3A8A,#6366F1,#C084FC',
  // Cotton candy
  '#F9A8D4,#C4B5FD,#93C5FD',
  // Citrus
  '#FDE047,#FB923C,#F43F5E',
  // Mint cocoa
  '#5EEAD4,#99F6E4,#78350F',
  // Ice
  '#E0F2FE,#7DD3FC,#38BDF8',
  // Ember
  '#FB923C,#F59E0B,#EF4444',
  // Violet haze
  '#4C1D95,#7C3AED,#E879F9',
  // Matcha
  '#365314,#84CC16,#D9F99D',
  // Rose gold
  '#FECDD3,#FDA4AF,#B45309',
  // Cyber
  '#00FF9F,#00D4FF,#FF00E5',
  // Monochrome
  '#F8FAFC,#94A3B8,#0F172A',
  // Twilight
  '#312E81,#7C3AED,#F472B6,#FBBF24',
  // Lagoon
  '#134E4A,#14B8A6,#67E8F9,#ECFDF5',
];

Color siteColorParse(String hex) {
  final raw = hex.replaceAll('#', '').trim();
  if (raw.length != 6) return const Color(0xFF6366F1);
  return Color(int.parse('FF$raw', radix: 16));
}

String siteColorFormat(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

/// Parses `#RRGGBB` or comma-separated stops `#A,#B,#C`.
List<Color> siteColorStopsParse(String value) {
  final parts = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return const [Color(0xFF6366F1)];
  return [for (final p in parts) siteColorParse(p)];
}

String siteColorStopsFormat(List<Color> colors) => colors.map(siteColorFormat).join(',');

String siteColorNormalize(String value) =>
    value.split(',').map((s) => s.trim().toUpperCase()).where((s) => s.isNotEmpty).join(',');

bool siteColorValueEq(String a, String b) => siteColorNormalize(a) == siteColorNormalize(b);

bool siteColorIsGradient(String value) => siteColorStopsParse(value).length > 1;

Gradient siteColorGradient(String value, {bool sweep = true}) {
  final stops = siteColorStopsParse(value);
  if (stops.length == 1) {
    return LinearGradient(colors: [stops.first, stops.first]);
  }
  if (sweep) {
    return SweepGradient(colors: [...stops, stops.first]);
  }
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: stops,
  );
}

String sitePaletteColorAt(int index) => sitePaletteColors[index % sitePaletteColors.length];
