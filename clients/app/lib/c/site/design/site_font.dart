import 'package:flutter/material.dart';

import 'site_font_loader.dart';

/// Curated Google Font families by category. Ids are Google family names.
enum SiteFontCategory { suggested, sans, serif, display, mono, all }

class SiteFontEntry {
  const SiteFontEntry(this.id, this.label, {this.category = SiteFontCategory.suggested});

  final String id;
  final String label;
  final SiteFontCategory category;
}

const siteFontSuggested = <SiteFontEntry>[
  SiteFontEntry('', 'Theme default'),
  SiteFontEntry('Inter', 'Inter', category: SiteFontCategory.sans),
  SiteFontEntry('Roboto', 'Roboto', category: SiteFontCategory.sans),
  SiteFontEntry('Poppins', 'Poppins', category: SiteFontCategory.sans),
  SiteFontEntry('Montserrat', 'Montserrat', category: SiteFontCategory.sans),
  SiteFontEntry('Lora', 'Lora', category: SiteFontCategory.serif),
  SiteFontEntry('Playfair Display', 'Playfair Display', category: SiteFontCategory.display),
  SiteFontEntry('Oswald', 'Oswald', category: SiteFontCategory.display),
  SiteFontEntry('Raleway', 'Raleway', category: SiteFontCategory.sans),
  SiteFontEntry('Nunito', 'Nunito', category: SiteFontCategory.sans),
  SiteFontEntry('Merriweather', 'Merriweather', category: SiteFontCategory.serif),
  SiteFontEntry('Space Grotesk', 'Space Grotesk', category: SiteFontCategory.sans),
];

const siteFontByCategory = <SiteFontCategory, List<SiteFontEntry>>{
  SiteFontCategory.sans: [
    SiteFontEntry('Inter', 'Inter', category: SiteFontCategory.sans),
    SiteFontEntry('Roboto', 'Roboto', category: SiteFontCategory.sans),
    SiteFontEntry('Poppins', 'Poppins', category: SiteFontCategory.sans),
    SiteFontEntry('Montserrat', 'Montserrat', category: SiteFontCategory.sans),
    SiteFontEntry('Raleway', 'Raleway', category: SiteFontCategory.sans),
    SiteFontEntry('Nunito', 'Nunito', category: SiteFontCategory.sans),
    SiteFontEntry('Space Grotesk', 'Space Grotesk', category: SiteFontCategory.sans),
    SiteFontEntry('Open Sans', 'Open Sans', category: SiteFontCategory.sans),
    SiteFontEntry('Lato', 'Lato', category: SiteFontCategory.sans),
    SiteFontEntry('Source Sans 3', 'Source Sans 3', category: SiteFontCategory.sans),
    SiteFontEntry('DM Sans', 'DM Sans', category: SiteFontCategory.sans),
    SiteFontEntry('Manrope', 'Manrope', category: SiteFontCategory.sans),
    SiteFontEntry('Outfit', 'Outfit', category: SiteFontCategory.sans),
    SiteFontEntry('Figtree', 'Figtree', category: SiteFontCategory.sans),
    SiteFontEntry('Plus Jakarta Sans', 'Plus Jakarta Sans', category: SiteFontCategory.sans),
  ],
  SiteFontCategory.serif: [
    SiteFontEntry('Lora', 'Lora', category: SiteFontCategory.serif),
    SiteFontEntry('Merriweather', 'Merriweather', category: SiteFontCategory.serif),
    SiteFontEntry('Playfair Display', 'Playfair Display', category: SiteFontCategory.serif),
    SiteFontEntry('Libre Baskerville', 'Libre Baskerville', category: SiteFontCategory.serif),
    SiteFontEntry('Source Serif 4', 'Source Serif 4', category: SiteFontCategory.serif),
    SiteFontEntry('Cormorant Garamond', 'Cormorant Garamond', category: SiteFontCategory.serif),
    SiteFontEntry('EB Garamond', 'EB Garamond', category: SiteFontCategory.serif),
    SiteFontEntry('Spectral', 'Spectral', category: SiteFontCategory.serif),
    SiteFontEntry('Crimson Text', 'Crimson Text', category: SiteFontCategory.serif),
  ],
  SiteFontCategory.display: [
    SiteFontEntry('Oswald', 'Oswald', category: SiteFontCategory.display),
    SiteFontEntry('Playfair Display', 'Playfair Display', category: SiteFontCategory.display),
    SiteFontEntry('Bebas Neue', 'Bebas Neue', category: SiteFontCategory.display),
    SiteFontEntry('Anton', 'Anton', category: SiteFontCategory.display),
    SiteFontEntry('Righteous', 'Righteous', category: SiteFontCategory.display),
    SiteFontEntry('Pacifico', 'Pacifico', category: SiteFontCategory.display),
    SiteFontEntry('Lobster', 'Lobster', category: SiteFontCategory.display),
    SiteFontEntry('Abril Fatface', 'Abril Fatface', category: SiteFontCategory.display),
    SiteFontEntry('Comfortaa', 'Comfortaa', category: SiteFontCategory.display),
  ],
  SiteFontCategory.mono: [
    SiteFontEntry('Roboto Mono', 'Roboto Mono', category: SiteFontCategory.mono),
    SiteFontEntry('Source Code Pro', 'Source Code Pro', category: SiteFontCategory.mono),
    SiteFontEntry('IBM Plex Mono', 'IBM Plex Mono', category: SiteFontCategory.mono),
    SiteFontEntry('JetBrains Mono', 'JetBrains Mono', category: SiteFontCategory.mono),
    SiteFontEntry('Fira Code', 'Fira Code', category: SiteFontCategory.mono),
    SiteFontEntry('Space Mono', 'Space Mono', category: SiteFontCategory.mono),
    SiteFontEntry('Inconsolata', 'Inconsolata', category: SiteFontCategory.mono),
  ],
};

/// Legacy kebab-case ids stored before we switched to Google family names.
const _siteFontLegacyIds = <String, String>{
  'inter': 'Inter',
  'roboto': 'Roboto',
  'poppins': 'Poppins',
  'montserrat': 'Montserrat',
  'lora': 'Lora',
  'playfair-display': 'Playfair Display',
  'oswald': 'Oswald',
  'raleway': 'Raleway',
  'nunito': 'Nunito',
  'merriweather': 'Merriweather',
  'space-grotesk': 'Space Grotesk',
};

/// Back-compat alias used by older call sites.
List<(String, String)> get siteFontPresets => [
      for (final e in siteFontSuggested) (e.id, e.label),
    ];

String siteFontNormalizeId(String id) {
  if (id.isEmpty) return '';
  return _siteFontLegacyIds[id] ?? id;
}

String siteFontLabel(String id) {
  final normalized = siteFontNormalizeId(id);
  if (normalized.isEmpty) return 'Theme default';
  for (final e in siteFontSuggested) {
    if (e.id == normalized) return e.label;
  }
  for (final list in siteFontByCategory.values) {
    for (final e in list) {
      if (e.id == normalized) return e.label;
    }
  }
  return normalized;
}

String siteFontCategoryLabel(SiteFontCategory c) => switch (c) {
      SiteFontCategory.suggested => 'Suggested',
      SiteFontCategory.sans => 'Sans',
      SiteFontCategory.serif => 'Serif',
      SiteFontCategory.display => 'Display',
      SiteFontCategory.mono => 'Mono',
      SiteFontCategory.all => 'All',
    };

List<SiteFontEntry> _siteFontAllEntries() {
  final seen = <String>{''};
  final out = <SiteFontEntry>[const SiteFontEntry('', 'Theme default')];
  for (final e in siteFontSuggested) {
    if (e.id.isEmpty || !seen.add(e.id)) continue;
    out.add(e);
  }
  for (final list in siteFontByCategory.values) {
    for (final e in list) {
      if (!seen.add(e.id)) continue;
      out.add(SiteFontEntry(e.id, e.label, category: SiteFontCategory.all));
    }
  }
  return out;
}

List<SiteFontEntry> siteFontEntriesFor(SiteFontCategory category, {String query = ''}) {
  final q = query.trim().toLowerCase();
  final List<SiteFontEntry> base = switch (category) {
    SiteFontCategory.suggested => siteFontSuggested,
    SiteFontCategory.all => _siteFontAllEntries(),
    _ => siteFontByCategory[category] ?? const [],
  };
  if (q.isEmpty) return base;
  return base.where((e) => e.label.toLowerCase().contains(q) || e.id.toLowerCase().contains(q)).toList();
}

/// Resolves a site font. TTF files are fetched on first use (lazy) via [SiteFontLoader].
TextStyle siteFontTextStyle({required String familyId, required TextStyle base}) {
  final name = siteFontNormalizeId(familyId);
  if (name.isEmpty) return base;
  SiteFontLoader.instance.ensureLoaded(name);
  return base.copyWith(fontFamily: name);
}
