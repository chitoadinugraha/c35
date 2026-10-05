import 'package:flutter/material.dart';

/// Visual style for home hint / action chips (`HintItem.theme` or live-call chip).
class HintChipTheme {
  const HintChipTheme({
    required this.background,
    required this.border,
    required this.label,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color label;
  final Color icon;

  static const HintChipTheme defaultTheme = HintChipTheme(
    background: Color(0xFF18181B),
    border: Color(0xFF27272A),
    label: Color(0xFFE4E4E7),
    icon: Color(0xFF71717A),
  );

  /// Live voice call entry — distinct from plain hints; no cyan accent.
  static const HintChipTheme liveCall = HintChipTheme(
    background: Color(0xFF27272A),
    border: Color(0xFF52525B),
    label: Color(0xFFFAFAFA),
    icon: Color(0xFFFAFAFA),
  );

  static HintChipTheme forKey(String theme) => switch (theme.trim()) {
        'live_call' => liveCall,
        _ => defaultTheme,
      };
}
