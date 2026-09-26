import 'package:flutter/material.dart';

const siteCatalogMasterListW = 280.0;

Color siteCatalogMasterDividerColor(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF3F3F46) : cs.outlineVariant.withValues(alpha: 0.55);
}

Widget siteCatalogMasterDivider(BuildContext context) =>
    ColoredBox(color: siteCatalogMasterDividerColor(context), child: const SizedBox(width: 1));
