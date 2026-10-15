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

  /// Account menu nav row (Bots / Talk / Call tiles).
  static const HintChipTheme accountMenuNav = HintChipTheme(
    background: Color(0xFF27272A),
    border: Color(0xFF27272A),
    label: Color(0xFFF4F4F5),
    icon: Color(0xFFA1A1AA),
  );

  static HintChipTheme forKey(String theme) => switch (theme.trim()) {
        'live_call' => liveCall,
        _ => defaultTheme,
      };
}

/// Shared height for account-menu Talk mode + Live call chips.
const double homeTalkCallChipHeight = 36;

/// Compact nav tiles (Bots / Talk / Call) in the account menu.
const double accountMenuNavTileHeight = 32;

const EdgeInsets homeTalkCallChipContentPadding = EdgeInsets.symmetric(horizontal: 10);
