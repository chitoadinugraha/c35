import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/presentation/slide_theme.dart';
import 'package:flutter/material.dart';

class PresentationThemeCatalogItem {
  const PresentationThemeCatalogItem({
    required this.id,
    required this.labelKey,
    required this.sort,
    required this.tokens,
    this.icon = '',
    this.aliases = const [],
  });

  final String id;
  final String labelKey;
  final int sort;
  final String icon;
  final Map<String, dynamic> tokens;
  final List<String> aliases;

  Color get accentColor => SlideTheme.colorFromHex(tokens['accent']?.toString(), const Color(0xFFF97316));

  String get displayLabel {
    final key = labelKey.trim();
    if (key.contains('.')) return catalogT(key);
    return key.isEmpty ? id : key;
  }

  SlideTheme toSlideTheme() => SlideTheme.fromTokens(id: id, label: displayLabel, raw: tokens);

  factory PresentationThemeCatalogItem.fromJson(Map<String, dynamic> j) {
    final aliasesRaw = j['aliases'];
    final aliases = aliasesRaw is List ? aliasesRaw.map((e) => '$e').toList() : const <String>[];
    final tokensRaw = j['tokens'];
    final tokens = tokensRaw is Map ? Map<String, dynamic>.from(tokensRaw) : <String, dynamic>{};
    return PresentationThemeCatalogItem(
      id: '${j['id'] ?? ''}',
      labelKey: '${j['label_key'] ?? ''}',
      sort: (j['sort'] as num?)?.toInt() ?? 0,
      icon: '${j['icon'] ?? ''}',
      tokens: tokens,
      aliases: aliases,
    );
  }
}
