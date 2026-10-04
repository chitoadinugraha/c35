import 'package:flutter/material.dart';

class SlideTheme {
  final String id;
  final String label;
  final Color cardBg;
  final Color canvasBg;
  final Color border;
  final Color accent;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;
  final LinearGradient slideGradient;
  final Color bulletCardBg;

  const SlideTheme({
    required this.id,
    required this.label,
    required this.cardBg,
    required this.canvasBg,
    required this.border,
    required this.accent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.slideGradient,
    required this.bulletCardBg,
  });

  static Color colorFromHex(String? raw, Color fallback) {
    final hex = (raw ?? '').trim();
    if (hex.isEmpty) return fallback;
    final s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length == 6) {
      final v = int.tryParse(s, radix: 16);
      if (v == null) return fallback;
      return Color(0xFF000000 | v);
    }
    if (s.length == 8) {
      final v = int.tryParse(s, radix: 16);
      if (v == null) return fallback;
      return Color(v);
    }
    return fallback;
  }

  static SlideTheme fromTokens({required String id, required String label, required Map<String, dynamic> raw}) {
    final gradientFrom = colorFromHex(raw['gradient_from']?.toString(), const Color(0xFF1A1A22));
    final gradientTo = colorFromHex(raw['gradient_to']?.toString(), const Color(0xFF0E0E12));
    return SlideTheme(
      id: id,
      label: label,
      cardBg: colorFromHex(raw['card_bg']?.toString(), const Color(0xFF141418)),
      canvasBg: colorFromHex(raw['canvas_bg']?.toString(), const Color(0xFF0D0D11)),
      border: colorFromHex(raw['border']?.toString(), const Color(0xFF26262C)),
      accent: colorFromHex(raw['accent']?.toString(), const Color(0xFFF97316)),
      secondaryAccent: colorFromHex(raw['accent2']?.toString(), const Color(0xFF06B6D4)),
      textPrimary: colorFromHex(raw['text']?.toString(), const Color(0xFFF4F4F5)),
      textSecondary: colorFromHex(raw['subtext']?.toString(), const Color(0xFFA1A1AA)),
      slideGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientFrom, gradientTo],
      ),
      bulletCardBg: colorFromHex(raw['bullet_card_bg']?.toString(), const Color(0x14FFFFFF)),
    );
  }
}
