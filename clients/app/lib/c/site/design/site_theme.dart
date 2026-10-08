import 'package:flutter/material.dart';

class SiteThemeTokens {
  const SiteThemeTokens({
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.outline,
    required this.isDark,
  });

  final Color background;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surface;
  final Color primary;
  final Color outline;
  final bool isDark;
}

class SiteThemeEntry {
  const SiteThemeEntry({
    required this.id,
    required this.baseId,
    required this.name,
    required this.isDark,
    required this.tokens,
  });

  final String id;
  final String baseId;
  final String name;
  final bool isDark;
  final SiteThemeTokens tokens;
}

class SiteThemeGroup {
  const SiteThemeGroup({
    required this.id,
    required this.name,
    required this.hasLight,
    required this.hasDark,
  });

  final String id;
  final String name;
  final bool hasLight;
  final bool hasDark;
}

const _siteThemes = <SiteThemeEntry>[
  SiteThemeEntry(
    id: 'monochrome-light',
    baseId: 'monochrome',
    name: 'Mono Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFF8F9FA),
      onBackground: Color(0xFF1A1A1A),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A1A),
      onSurfaceVariant: Color(0xFF444746),
      primary: Color(0xFF000000),
      outline: Color(0xFFC4C7C5),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'monochrome-dark',
    baseId: 'monochrome',
    name: 'Mono Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF0F1012),
      onBackground: Color(0xFFE2E2E6),
      surface: Color(0xFF17181C),
      onSurface: Color(0xFFE2E2E6),
      onSurfaceVariant: Color(0xFFC7C6CB),
      primary: Color(0xFFFFFFFF),
      outline: Color(0xFF44474E),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'violet-light',
    baseId: 'violet',
    name: 'Violet Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFF5F3FF),
      onBackground: Color(0xFF1E1B4B),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1E1B4B),
      onSurfaceVariant: Color(0xFF4F46E5),
      primary: Color(0xFF6D28D9),
      outline: Color(0xFFDDD6FE),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'violet-dark',
    baseId: 'violet',
    name: 'Violet Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF0D0A1A),
      onBackground: Color(0xFFE0E0FF),
      surface: Color(0xFF15112E),
      onSurface: Color(0xFFE0E0FF),
      onSurfaceVariant: Color(0xFFC084FC),
      primary: Color(0xFFC084FC),
      outline: Color(0xFF3C2C77),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'sunset-light',
    baseId: 'sunset',
    name: 'Sunset Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFFFF7ED),
      onBackground: Color(0xFF431407),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF431407),
      onSurfaceVariant: Color(0xFFEA580C),
      primary: Color(0xFFEA580C),
      outline: Color(0xFFFED7AA),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'sunset-dark',
    baseId: 'sunset',
    name: 'Sunset Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF180F0A),
      onBackground: Color(0xFFFDE8E3),
      surface: Color(0xFF27170F),
      onSurface: Color(0xFFFDE8E3),
      onSurfaceVariant: Color(0xFFFB923C),
      primary: Color(0xFFFB923C),
      outline: Color(0xFF563321),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'forest-light',
    baseId: 'forest',
    name: 'Forest Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFF0FDF4),
      onBackground: Color(0xFF052E16),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF052E16),
      onSurfaceVariant: Color(0xFF16A34A),
      primary: Color(0xFF15803D),
      outline: Color(0xFFBBF7D0),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'forest-dark',
    baseId: 'forest',
    name: 'Forest Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF071510),
      onBackground: Color(0xFFE2F5EA),
      surface: Color(0xFF0F2218),
      onSurface: Color(0xFFE2F5EA),
      onSurfaceVariant: Color(0xFF4ADE80),
      primary: Color(0xFF4ADE80),
      outline: Color(0xFF1F4030),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'cyberpunk',
    baseId: 'cyberpunk',
    name: 'Cyberpunk Neon',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF05060B),
      onBackground: Color(0xFF00F0FF),
      surface: Color(0xFF0B0D19),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFFFF007F),
      primary: Color(0xFF00F0FF),
      outline: Color(0xFF00F0FF),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'retro',
    baseId: 'retro',
    name: 'Retro Craft',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFECE3CA),
      onBackground: Color(0xFF2E282A),
      surface: Color(0xFFF4ECCF),
      onSurface: Color(0xFF2E282A),
      onSurfaceVariant: Color(0xFFA4CBB4),
      primary: Color(0xFFEF9995),
      outline: Color(0xFFD97706),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'synthwave',
    baseId: 'synthwave',
    name: 'Synthwave',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF1A103C),
      onBackground: Color(0xFFFFFFFF),
      surface: Color(0xFF241854),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFF58C7F3),
      primary: Color(0xFFE779C1),
      outline: Color(0xFFE779C1),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'aqua',
    baseId: 'aqua',
    name: 'Aqua Sea',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF0B2545),
      onBackground: Color(0xFFFFFFFF),
      surface: Color(0xFF134074),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFFFFE066),
      primary: Color(0xFF09BECD),
      outline: Color(0xFF09BECD),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'coffee',
    baseId: 'coffee',
    name: 'Coffee Cafe',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF201615),
      onBackground: Color(0xFFF2E8DF),
      surface: Color(0xFF2D1E1C),
      onSurface: Color(0xFFF2E8DF),
      onSurfaceVariant: Color(0xFFAB7A5F),
      primary: Color(0xFFAB7A5F),
      outline: Color(0xFFAB7A5F),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'nord-light',
    baseId: 'nord',
    name: 'Nord Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFECEFF4),
      onBackground: Color(0xFF2E3440),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF2E3440),
      onSurfaceVariant: Color(0xFF434C5E),
      primary: Color(0xFF88C0D0),
      outline: Color(0xFF88C0D0),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'nord-dark',
    baseId: 'nord',
    name: 'Nord Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF2E3440),
      onBackground: Color(0xFFECEFF4),
      surface: Color(0xFF3B4252),
      onSurface: Color(0xFFECEFF4),
      onSurfaceVariant: Color(0xFFD8DEE9),
      primary: Color(0xFF88C0D0),
      outline: Color(0xFF88C0D0),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'luxury',
    baseId: 'luxury',
    name: 'Luxury Gold',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF09090B),
      onBackground: Color(0xFFFFFFFF),
      surface: Color(0xFF18181B),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFFF59E0B),
      primary: Color(0xFFFFFFFF),
      outline: Color(0xFFF59E0B),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'sakura-light',
    baseId: 'sakura',
    name: 'Sakura Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFFFF1F2),
      onBackground: Color(0xFF4C0519),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF4C0519),
      onSurfaceVariant: Color(0xFFBE123C),
      primary: Color(0xFFEC4899),
      outline: Color(0xFFF43F5E),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'sakura-dark',
    baseId: 'sakura',
    name: 'Sakura Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF0F0A0C),
      onBackground: Color(0xFFFFE4E6),
      surface: Color(0xFF1C1216),
      onSurface: Color(0xFFFFE4E6),
      onSurfaceVariant: Color(0xFFF472B6),
      primary: Color(0xFFF472B6),
      outline: Color(0xFFEC4899),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'dracula',
    baseId: 'dracula',
    name: 'Dracula',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF1E1F29),
      onBackground: Color(0xFFF8F8F2),
      surface: Color(0xFF282A36),
      onSurface: Color(0xFFF8F8F2),
      onSurfaceVariant: Color(0xFF8BE9FD),
      primary: Color(0xFFFF79C6),
      outline: Color(0xFFBD93F9),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'mint-light',
    baseId: 'mint',
    name: 'Mint Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFF4FBF7),
      onBackground: Color(0xFF062E1B),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF062E1B),
      onSurfaceVariant: Color(0xFF059669),
      primary: Color(0xFF059669),
      outline: Color(0xFF10B981),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'mint-dark',
    baseId: 'mint',
    name: 'Mint Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF05100B),
      onBackground: Color(0xFFE6F7ED),
      surface: Color(0xFF0D2218),
      onSurface: Color(0xFFE6F7ED),
      onSurfaceVariant: Color(0xFF34D399),
      primary: Color(0xFF34D399),
      outline: Color(0xFF10B981),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'lavender-light',
    baseId: 'lavender',
    name: 'Lavender Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFFAF5FF),
      onBackground: Color(0xFF2E1065),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF2E1065),
      onSurfaceVariant: Color(0xFF7C3AED),
      primary: Color(0xFF7C3AED),
      outline: Color(0xFF8B5CF6),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'lavender-dark',
    baseId: 'lavender',
    name: 'Lavender Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF0F0A1A),
      onBackground: Color(0xFFF3E8FF),
      surface: Color(0xFF1A112E),
      onSurface: Color(0xFFF3E8FF),
      onSurfaceVariant: Color(0xFFA78BFA),
      primary: Color(0xFFC084FC),
      outline: Color(0xFF8B5CF6),
      isDark: true,
    ),
  ),
  SiteThemeEntry(
    id: 'rosegold-light',
    baseId: 'rosegold',
    name: 'Rose Gold Light',
    isDark: false,
    tokens: SiteThemeTokens(
      background: Color(0xFFFFF5F5),
      onBackground: Color(0xFF4A1525),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF4A1525),
      onSurfaceVariant: Color(0xFFC2185B),
      primary: Color(0xFFB78494),
      outline: Color(0xFFEC407A),
      isDark: false,
    ),
  ),
  SiteThemeEntry(
    id: 'rosegold-dark',
    baseId: 'rosegold',
    name: 'Rose Gold Dark',
    isDark: true,
    tokens: SiteThemeTokens(
      background: Color(0xFF1A0F13),
      onBackground: Color(0xFFFFF5F5),
      surface: Color(0xFF29181E),
      onSurface: Color(0xFFFFF5F5),
      onSurfaceVariant: Color(0xFFF48FB1),
      primary: Color(0xFFE5A9B8),
      outline: Color(0xFFB78494),
      isDark: true,
    ),
  ),
];

final siteThemeGroups = () {
  final seen = <String>{};
  final groups = <SiteThemeGroup>[];
  for (final t in _siteThemes) {
    if (seen.contains(t.baseId)) continue;
    seen.add(t.baseId);
    final light = _siteThemes.any((x) => x.baseId == t.baseId && !x.isDark);
    final dark = _siteThemes.any((x) => x.baseId == t.baseId && x.isDark);
    final name = t.name.replaceAll(RegExp(r' (Light|Dark)$'), '');
    groups.add(SiteThemeGroup(id: t.baseId, name: name, hasLight: light, hasDark: dark));
  }
  return groups;
}();

SiteThemeEntry siteThemeResolve(String baseId, bool preferDark) {
  final dark = _siteThemes.where((t) => t.baseId == baseId && t.isDark).firstOrNull;
  final light = _siteThemes.where((t) => t.baseId == baseId && !t.isDark).firstOrNull;
  final solo = _siteThemes.where((t) => t.id == baseId).firstOrNull;
  if (preferDark && dark != null) return dark;
  if (!preferDark && light != null) return light;
  return dark ?? light ?? solo ?? _siteThemes.first;
}

SiteThemeGroup siteThemeGroupGet(String baseId) =>
    siteThemeGroups.firstWhere((g) => g.id == baseId, orElse: () => siteThemeGroups.first);

Gradient siteThemeSwatchGradient(String baseId, bool preferDark) {
  final theme = siteThemeResolve(baseId, preferDark);
  final t = theme.tokens;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [t.primary, t.onSurfaceVariant, t.background],
    stops: const [0, 0.55, 1],
  );
}

String siteThemeGroupName(String baseId) => siteThemeGroupGet(baseId).name;

/// Flutter [ThemeData] for in-app guest hub / editor preview (Material sheets, buttons, scaffolds).
ThemeData siteThemeMaterial(SiteThemeTokens t) {
  final brightness = t.isDark ? Brightness.dark : Brightness.light;
  final onPrimary = t.primary.computeLuminance() > 0.4 ? const Color(0xFF141414) : Colors.white;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.primary,
    onPrimary: onPrimary,
    secondary: t.onSurfaceVariant,
    onSecondary: t.onSurface,
    error: brightness == Brightness.dark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
    onError: brightness == Brightness.dark ? const Color(0xFF690005) : Colors.white,
    surface: t.surface,
    onSurface: t.onSurface,
    onSurfaceVariant: t.onSurfaceVariant,
    outline: t.outline,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.background,
    appBarTheme: AppBarTheme(
      backgroundColor: t.surface,
      foregroundColor: t.onSurface,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: t.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.primary,
        foregroundColor: onPrimary,
      ),
    ),
    dividerTheme: DividerThemeData(color: t.outline.withValues(alpha: 0.35)),
  );
}
