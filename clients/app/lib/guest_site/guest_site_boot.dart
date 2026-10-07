import 'package:flutter/material.dart';

/// Parsed `site_boot_get` JSON (`mod_site::site_boot_json_assemble`).
class GuestSiteBoot {
  GuestSiteBoot({
    required this.siteIid,
    required this.name,
    required this.alienId,
    required this.avatarUrl,
    required this.mode,
    required this.meta,
    required this.theme,
    required this.pages,
    required this.capabilities,
    required this.productPreload,
    required this.productPreloadMeta,
    required this.links,
    required this.postsPreload,
  });

  final int siteIid;
  final String name;
  final String alienId;
  final String avatarUrl;
  final String mode;
  final Map<String, dynamic> meta;
  final Map<String, dynamic> theme;
  final List<Map<String, dynamic>> pages;
  final Map<String, dynamic> capabilities;
  final Map<String, List<Map<String, dynamic>>> productPreload;
  final Map<String, Map<String, dynamic>> productPreloadMeta;
  final List<Map<String, dynamic>> links;
  final List<Map<String, dynamic>> postsPreload;

  /// Client-side boot from `site.preview` / tool `doc` (no product preload until `boot_get`).
  factory GuestSiteBoot.fromSiteDoc({
    required int siteIid,
    required String name,
    required String alienId,
    required Map<String, dynamic> doc,
    String mode = 'draft',
    String avatarUrl = '',
    Map<String, dynamic>? capabilities,
  }) {
    final pagesRaw = doc['pages'];
    final pages = pagesRaw is List
        ? pagesRaw.whereType<Map<String, dynamic>>().toList(growable: false)
        : const <Map<String, dynamic>>[];
    final theme = doc['theme'] is Map<String, dynamic> ? doc['theme'] as Map<String, dynamic> : const <String, dynamic>{};
    final meta = doc['meta'] is Map<String, dynamic> ? doc['meta'] as Map<String, dynamic> : const <String, dynamic>{};
    return GuestSiteBoot(
      siteIid: siteIid,
      name: name,
      alienId: alienId,
      avatarUrl: avatarUrl,
      mode: mode,
      meta: meta,
      theme: theme,
      pages: pages,
      capabilities: capabilities ?? const <String, dynamic>{},
      productPreload: const {},
      productPreloadMeta: const {},
      links: const [],
      postsPreload: const [],
    );
  }

  factory GuestSiteBoot.fromJson(Map<String, dynamic> json) {
    final pagesRaw = json['pages'];
    final pages = pagesRaw is List
        ? pagesRaw.whereType<Map<String, dynamic>>().toList(growable: false)
        : const <Map<String, dynamic>>[];

    final preloadRaw = json['product_preload'];
    final productPreload = <String, List<Map<String, dynamic>>>{};
    if (preloadRaw is Map) {
      for (final entry in preloadRaw.entries) {
        final v = entry.value;
        if (v is List) {
          productPreload[entry.key.toString()] =
              v.whereType<Map<String, dynamic>>().toList(growable: false);
        }
      }
    }

    final metaRaw = json['product_preload_meta'];
    final productPreloadMeta = <String, Map<String, dynamic>>{};
    if (metaRaw is Map) {
      for (final entry in metaRaw.entries) {
        final v = entry.value;
        if (v is Map<String, dynamic>) {
          productPreloadMeta[entry.key.toString()] = v;
        }
      }
    }

    final linksRaw = json['links'];
    final links = linksRaw is List
        ? linksRaw.whereType<Map<String, dynamic>>().toList(growable: false)
        : const <Map<String, dynamic>>[];

    final postsRaw = json['posts_preload'];
    final postsPreload = postsRaw is List
        ? postsRaw.whereType<Map<String, dynamic>>().toList(growable: false)
        : const <Map<String, dynamic>>[];

    return GuestSiteBoot(
      siteIid: json['site_iid'] as int? ?? json['site_id'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Website',
      alienId: json['alien_id']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'draft',
      meta: _mapOrEmpty(json['meta']),
      theme: _mapOrEmpty(json['theme']),
      pages: pages,
      capabilities: _mapOrEmpty(json['capabilities']),
      productPreload: productPreload,
      productPreloadMeta: productPreloadMeta,
      links: links,
      postsPreload: postsPreload,
    );
  }

  static Map<String, dynamic> _mapOrEmpty(Object? v) =>
      v is Map<String, dynamic> ? v : const <String, dynamic>{};

  List<Map<String, dynamic>> get homeBlocks {
    if (pages.isEmpty) return const [];
    final blocks = pages.first['blocks'];
    if (blocks is List) {
      return blocks.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const [];
  }

  bool get hasProductBlocks => homeBlocks.any((b) {
        final t = b['type']?.toString() ?? '';
        return t == 'product_grid' || t == 'gallery';
      });

  List<Map<String, dynamic>> productsForBlock(String blockId) =>
      productPreload[blockId] ?? const [];

  String? nextProductCursorForBlock(String blockId) =>
      productPreloadMeta[blockId]?['next_cursor']?.toString();

  Color get accentColor {
    final hex = theme['accent']?.toString().replaceAll('#', '') ?? '';
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFFF97316);
  }
}
