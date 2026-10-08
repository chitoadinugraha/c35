import 'dart:convert';

import 'package:alienai_c35/c/site/design/site_color.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/guest_site/guest_site_product_design.dart';
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
    required this.productDesign,
    required this.theme,
    required this.pages,
    required this.capabilities,
    required this.productPreload,
    required this.productPreloadMeta,
    required this.links,
    required this.postsPreload,
    this.design,
    this.featuredContacts = const [],
    this.effects = const [],
    this.commerceObjects = const [],
  });

  final int siteIid;
  final String name;
  final String alienId;
  final String avatarUrl;
  final String mode;
  final Map<String, dynamic> meta;
  final SiteProductDesignDraft productDesign;
  final Map<String, dynamic> theme;
  final List<Map<String, dynamic>> pages;
  final Map<String, dynamic> capabilities;
  final Map<String, List<Map<String, dynamic>>> productPreload;
  final Map<String, Map<String, dynamic>> productPreloadMeta;
  final List<Map<String, dynamic>> links;
  final List<Map<String, dynamic>> postsPreload;

  /// Theme document from boot `design` (`SiteDesignStore.toThemeMap` shape). Null when the boot has no `design` key.
  final SiteDesignStore? design;

  /// Boot `featured_contacts`: `{id, name, pic, featured}` where `featured` is `partners` or `clients`.
  final List<Map<String, dynamic>> featuredContacts;

  /// Boot `effects`: `{id, presetId, params, active}`. Parsed for the effect layer; painting lives on that track.
  final List<Map<String, dynamic>> effects;

  /// Boot `commerce_boot.objects`: reservable units `{id, name, code, pic, kind, product_id}`.
  final List<Map<String, dynamic>> commerceObjects;

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
    final productFallback = siteProductDesignFromJson(meta['product_design']);
    final design = _designStore(doc['design'], productFallback);
    return GuestSiteBoot(
      siteIid: siteIid,
      name: name,
      alienId: alienId,
      avatarUrl: avatarUrl,
      mode: mode,
      meta: meta,
      productDesign: design?.productDesign ?? productFallback,
      theme: theme,
      pages: pages,
      capabilities: capabilities ?? const <String, dynamic>{},
      productPreload: const {},
      productPreloadMeta: const {},
      links: const [],
      postsPreload: const [],
      design: design,
      featuredContacts: _mapList(doc['featured_contacts']),
      effects: _mapList(doc['effects']),
      commerceObjects: commerceObjectsFrom(doc),
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

    final productFallback = guestSiteProductDesignFromBoot(json);
    final design = _designStore(json['design'], productFallback);
    return GuestSiteBoot(
      siteIid: json['site_iid'] as int? ?? json['site_id'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Website',
      alienId: json['alien_id']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'draft',
      meta: _mapOrEmpty(json['meta']),
      productDesign: design?.productDesign ?? productFallback,
      theme: _mapOrEmpty(json['theme']),
      pages: pages,
      capabilities: _mapOrEmpty(json['capabilities']),
      productPreload: productPreload,
      productPreloadMeta: productPreloadMeta,
      links: links,
      postsPreload: postsPreload,
      design: design,
      featuredContacts: _mapList(json['featured_contacts']),
      effects: _mapList(json['effects']),
      commerceObjects: commerceObjectsFrom(json),
    );
  }

  static Map<String, dynamic> _mapOrEmpty(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> commerceObjectsFrom(Map<String, dynamic> json) {
    final boot = json['commerce_boot'];
    if (boot is! Map) return const [];
    return _mapList(boot['objects']);
  }

  static List<Map<String, dynamic>> _mapList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) item.map((k, v) => MapEntry(k.toString(), v)),
    ];
  }

  /// `design` is a theme_json object, or a JSON string of that object. Absent means accent-only.
  static SiteDesignStore? _designStore(Object? raw, SiteProductDesignDraft productFallback) {
    if (raw == null) return null;
    final store = SiteDesignStore();
    if (raw is String) {
      if (raw.trim().isEmpty) return null;
      store.loadTheme(raw, productFallback: productFallback);
      return store;
    }
    if (raw is Map) {
      store.loadTheme(jsonEncode(_mapOrEmpty(raw)), productFallback: productFallback);
      return store;
    }
    return null;
  }

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
    final fromDesign = design?.accent.trim() ?? '';
    if (fromDesign.isNotEmpty) return siteColorParse(fromDesign);
    final hex = theme['accent']?.toString().replaceAll('#', '') ?? '';
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFFF97316);
  }

  String get locationLabel => meta['location_label']?.toString().trim() ?? '';

  String get locationHref => meta['location_href']?.toString().trim() ?? '';

  List<SiteScheduleSlot> get openHoursSlots => siteScheduleSlotsFromMetaJson(jsonEncode(meta));

  List<Map<String, dynamic>> get metaOpenHoursRows => siteScheduleSlotsToHoursRows(openHoursSlots);

  bool get shouldShowMetaLocation =>
      locationLabel.isNotEmpty && !homeBlocks.any((b) => b['type']?.toString() == 'map') && !_hubShowsLocation;

  bool get shouldShowMetaHours => openHoursSlots.isNotEmpty && !homeBlocks.any((b) => b['type']?.toString() == 'hours');

  bool get _hubShowsLocation => homeBlocks.any((b) {
        if (b['type']?.toString() != 'hub_profile') return false;
        final props = b['props'];
        if (props is! Map<String, dynamic>) return false;
        return (props['location_label']?.toString().trim() ?? '').isNotEmpty;
      });
}
