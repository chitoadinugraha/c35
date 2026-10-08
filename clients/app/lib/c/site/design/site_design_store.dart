import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:alienai_c35/c/site/design/overlay_effect_instance.dart';
import 'package:alienai_c35/c/site/design/site_backdrop.dart';
import 'package:alienai_c35/c/site/design/site_card_style.dart';
import 'package:alienai_c35/c/site/design/site_color.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/c/site/design/site_theme.dart';

/// Live design document for the site designer. Persisted inside `theme_json`.
class SiteDesignStore extends ChangeNotifier {
  SiteDesignStore({
    this.themeBaseId = 'monochrome',
    this.themeDark = false,
    this.accent = '',
    this.background = const SiteBackgroundDraft(),
    SiteBackdropDraft? backdrop,
    SiteCardStyleDraft? cardStyle,
    List<SiteBlockDesignDraft>? blockDesigns,
    SiteFeaturedStripDraft? partnersDisplay,
    SiteFeaturedStripDraft? clientsDisplay,
    SiteProfileDesignDraft? profileDesign,
    SiteProductDesignDraft? productDesign,
  })  : backdrop = backdrop ?? const SiteBackdropDraft(),
        cardStyle = cardStyle ?? const SiteCardStyleDraft(),
        blockDesigns = List.of(blockDesigns ?? const []),
        partnersDisplay = partnersDisplay ?? const SiteFeaturedStripDraft(header: siteFeaturedPartnersDefaultHeader),
        clientsDisplay = clientsDisplay ?? const SiteFeaturedStripDraft(header: siteFeaturedClientsDefaultHeader),
        profileDesign = profileDesign ?? const SiteProfileDesignDraft(),
        productDesign = productDesign ?? const SiteProductDesignDraft(),
        overlayEffects = [];

  String themeBaseId;
  bool themeDark;
  String accent;
  SiteBackgroundDraft background;
  SiteBackdropDraft backdrop;
  SiteCardStyleDraft cardStyle;
  List<SiteBlockDesignDraft> blockDesigns;
  SiteFeaturedStripDraft partnersDisplay;
  SiteFeaturedStripDraft clientsDisplay;
  SiteProfileDesignDraft profileDesign;
  SiteProductDesignDraft productDesign;
  List<SiteOverlayEffectDraft> overlayEffects;

  var _themeTouched = false;

  void loadTheme(String themeJson, {SiteProductDesignDraft? productFallback}) {
    final map = _map(themeJson);
    themeBaseId = (map['base']?.toString().trim().isNotEmpty ?? false) ? map['base'].toString() : 'monochrome';
    themeDark = map['dark'] == true;
    accent = map['accent']?.toString() ?? '';
    background = _backgroundFrom(map['background']) ?? const SiteBackgroundDraft();
    backdrop = _backdropFrom(map['backdrop']) ?? const SiteBackdropDraft();
    cardStyle = _cardFrom(map['card']) ?? const SiteCardStyleDraft();
    blockDesigns = _blocksFrom(map['blocks']);
    partnersDisplay = _stripFrom(map['partners'], siteFeaturedPartnersDefaultHeader);
    clientsDisplay = _stripFrom(map['clients'], siteFeaturedClientsDefaultHeader);
    profileDesign = _profileFrom(map['profile']) ?? const SiteProfileDesignDraft();
    final product = _productFrom(map['product']);
    productDesign = product ?? productFallback ?? const SiteProductDesignDraft();
    overlayEffects = _effectsFrom(map['effects']);
    _themeTouched = false;
  }

  Map<String, dynamic> toThemeMap() {
    final accentOut = _themeTouched || accent.trim().isEmpty
        ? siteColorFormat(siteThemeResolve(themeBaseId, themeDark).tokens.primary)
        : accent.trim();
    return {
      'accent': accentOut,
      'base': themeBaseId,
      'dark': themeDark,
      'background': {
        'type': background.type,
        'color': background.color,
        'url': background.url,
        'blur': background.blur,
        'overlay': background.overlay,
        'overlayTone': background.overlayTone,
      },
      'card': {'id': cardStyle.id, 'params': cardStyle.params},
      'backdrop': {'id': backdrop.id, 'params': backdrop.params, 'color': backdrop.color},
      'profile': {
        'showAvatar': profileDesign.showAvatar,
        'avatarSize': profileDesign.avatarSize,
        'avatarOutlineWidth': profileDesign.avatarOutlineWidth,
        'avatarOutlineColor': profileDesign.avatarOutlineColor,
        'showTitle': profileDesign.showTitle,
        'titleFontSize': profileDesign.titleFontSize,
        'titleFontFamily': profileDesign.titleFontFamily,
        'titleAlign': profileDesign.titleAlign,
        'showBio': profileDesign.showBio,
        'bioFontSize': profileDesign.bioFontSize,
        'bioFontFamily': profileDesign.bioFontFamily,
        'bioAlign': profileDesign.bioAlign,
        'showLocation': profileDesign.showLocation,
        'showHours': profileDesign.showHours,
        'hubDefaultTab': profileDesign.hubDefaultTab,
        'hubPostsPreviewLimit': profileDesign.hubPostsPreviewLimit,
      },
      'product': {
        'titleFontSize': productDesign.titleFontSize,
        'titleFontWeight': productDesign.titleFontWeight,
        'titleFontFamily': productDesign.titleFontFamily,
        'titleItalic': productDesign.titleItalic,
        'titleUnderline': productDesign.titleUnderline,
        'titleColor': productDesign.titleColor,
        'subtitleFontSize': productDesign.subtitleFontSize,
        'subtitleFontWeight': productDesign.subtitleFontWeight,
        'subtitleFontFamily': productDesign.subtitleFontFamily,
        'subtitleItalic': productDesign.subtitleItalic,
        'subtitleUnderline': productDesign.subtitleUnderline,
        'subtitleColor': productDesign.subtitleColor,
        'priceFontSize': productDesign.priceFontSize,
        'priceFontWeight': productDesign.priceFontWeight,
        'priceFontFamily': productDesign.priceFontFamily,
        'priceItalic': productDesign.priceItalic,
        'priceUnderline': productDesign.priceUnderline,
        'priceColor': productDesign.priceColor,
      },
      'partners': _stripTo(partnersDisplay),
      'clients': _stripTo(clientsDisplay),
      'blocks': [
        for (final b in blockDesigns) {'block': b.block, 'cardStyleId': b.cardStyleId, 'params': b.params},
      ],
      'effects': [
        for (final e in overlayEffects)
          {'id': e.id, 'presetId': e.presetId, 'params': e.params, 'active': e.active},
      ],
    };
  }

  String toThemeJson() => jsonEncode(toThemeMap());

  SiteOverlayEffectDraft? overlayEffectGet(String id) {
    for (final e in overlayEffects) {
      if (e.id == id) return e;
    }
    return null;
  }

  String overlayEffectAdd({
    required String presetId,
    Map<String, Object?> params = const {},
    bool active = true,
  }) {
    final id = overlayEffectInstanceNewId(presetId);
    overlayEffects.add(SiteOverlayEffectDraft(
      id: id,
      presetId: presetId,
      params: Map<String, Object?>.from(params),
      active: active,
    ));
    notifyListeners();
    return id;
  }

  void overlayEffectUpdate(
    String id, {
    String? presetId,
    Map<String, Object?>? params,
    bool? active,
  }) {
    final i = overlayEffects.indexWhere((e) => e.id == id);
    if (i < 0) return;
    overlayEffects[i] = overlayEffects[i].copyWith(presetId: presetId, params: params, active: active);
    notifyListeners();
  }

  void overlayEffectRemove(String id) {
    overlayEffects.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  SiteBlockDesignDraft? blockDesignGet(String block) {
    for (final b in blockDesigns) {
      if (b.block == block) return b;
    }
    return null;
  }

  void blockDesignPut(SiteBlockDesignDraft doc) {
    final i = blockDesigns.indexWhere((b) => b.block == doc.block);
    if (doc.inheritsGlobal) {
      if (i >= 0) blockDesigns.removeAt(i);
    } else if (i >= 0) {
      blockDesigns[i] = doc;
    } else {
      blockDesigns.add(doc);
    }
    notifyListeners();
  }

  SiteFeaturedStripDraft featuredStripGet(String kind) => kind == 'partners' ? partnersDisplay : clientsDisplay;

  void featuredStripUpdate(
    String kind, {
    bool? showLabel,
    String? slideFrom,
    String? headerAlign,
    String? header,
    double? headerFontSize,
    String? headerFontFamily,
    String? itemAlign,
    String? itemMode,
  }) {
    if (showLabel == null &&
        slideFrom == null &&
        headerAlign == null &&
        header == null &&
        headerFontSize == null &&
        headerFontFamily == null &&
        itemAlign == null &&
        itemMode == null) {
      return;
    }
    final next = featuredStripGet(kind).copyWith(
      showLabel: showLabel,
      slideFrom: slideFrom,
      headerAlign: headerAlign,
      header: header,
      headerFontSize: headerFontSize,
      headerFontFamily: headerFontFamily,
      itemAlign: itemAlign,
      itemMode: itemMode,
    );
    if (kind == 'partners') {
      partnersDisplay = next;
    } else {
      clientsDisplay = next;
    }
    notifyListeners();
  }

  void profileDesignUpdate({
    bool? showAvatar,
    double? avatarSize,
    double? avatarOutlineWidth,
    String? avatarOutlineColor,
    bool? showTitle,
    double? titleFontSize,
    String? titleFontFamily,
    String? titleAlign,
    bool? showBio,
    double? bioFontSize,
    String? bioFontFamily,
    String? bioAlign,
    bool? showLocation,
    bool? showHours,
    String? hubDefaultTab,
    int? hubPostsPreviewLimit,
  }) {
    if (showAvatar == null &&
        avatarSize == null &&
        avatarOutlineWidth == null &&
        avatarOutlineColor == null &&
        showTitle == null &&
        titleFontSize == null &&
        titleFontFamily == null &&
        titleAlign == null &&
        showBio == null &&
        bioFontSize == null &&
        bioFontFamily == null &&
        bioAlign == null &&
        showLocation == null &&
        showHours == null &&
        hubDefaultTab == null &&
        hubPostsPreviewLimit == null) {
      return;
    }
    profileDesign = profileDesign.copyWith(
      showAvatar: showAvatar,
      avatarSize: avatarSize,
      avatarOutlineWidth: avatarOutlineWidth,
      avatarOutlineColor: avatarOutlineColor,
      showTitle: showTitle,
      titleFontSize: titleFontSize,
      titleFontFamily: titleFontFamily,
      titleAlign: titleAlign,
      showBio: showBio,
      bioFontSize: bioFontSize,
      bioFontFamily: bioFontFamily,
      bioAlign: bioAlign,
      showLocation: showLocation,
      showHours: showHours,
      hubDefaultTab: hubDefaultTab,
      hubPostsPreviewLimit: hubPostsPreviewLimit,
    );
    notifyListeners();
  }

  void productDesignUpdate({
    double? titleFontSize,
    String? titleFontWeight,
    String? titleFontFamily,
    bool? titleItalic,
    bool? titleUnderline,
    String? titleColor,
    double? subtitleFontSize,
    String? subtitleFontWeight,
    String? subtitleFontFamily,
    bool? subtitleItalic,
    bool? subtitleUnderline,
    String? subtitleColor,
    double? priceFontSize,
    String? priceFontWeight,
    String? priceFontFamily,
    bool? priceItalic,
    bool? priceUnderline,
    String? priceColor,
  }) {
    if (titleFontSize == null &&
        titleFontWeight == null &&
        titleFontFamily == null &&
        titleItalic == null &&
        titleUnderline == null &&
        titleColor == null &&
        subtitleFontSize == null &&
        subtitleFontWeight == null &&
        subtitleFontFamily == null &&
        subtitleItalic == null &&
        subtitleUnderline == null &&
        subtitleColor == null &&
        priceFontSize == null &&
        priceFontWeight == null &&
        priceFontFamily == null &&
        priceItalic == null &&
        priceUnderline == null &&
        priceColor == null) {
      return;
    }
    productDesign = productDesign.copyWith(
      titleFontSize: titleFontSize,
      titleFontWeight: titleFontWeight == null ? null : siteFontWeightNormalize(titleFontWeight),
      titleFontFamily: titleFontFamily,
      titleItalic: titleItalic,
      titleUnderline: titleUnderline,
      titleColor: titleColor,
      subtitleFontSize: subtitleFontSize,
      subtitleFontWeight: subtitleFontWeight == null ? null : siteFontWeightNormalize(subtitleFontWeight),
      subtitleFontFamily: subtitleFontFamily,
      subtitleItalic: subtitleItalic,
      subtitleUnderline: subtitleUnderline,
      subtitleColor: subtitleColor,
      priceFontSize: priceFontSize,
      priceFontWeight: priceFontWeight == null ? null : siteFontWeightNormalize(priceFontWeight),
      priceFontFamily: priceFontFamily,
      priceItalic: priceItalic,
      priceUnderline: priceUnderline,
      priceColor: priceColor,
    );
    notifyListeners();
  }

  void designUpdate({
    String? themeBaseId,
    bool? themeDark,
    SiteBackgroundDraft? background,
    SiteBackdropDraft? backdrop,
    SiteCardStyleDraft? cardStyle,
  }) {
    var changed = false;
    if (themeBaseId != null && themeBaseId != this.themeBaseId) {
      this.themeBaseId = themeBaseId;
      _themeTouched = true;
      changed = true;
    }
    if (themeDark != null && themeDark != this.themeDark) {
      this.themeDark = themeDark;
      _themeTouched = true;
      changed = true;
    }
    if (background != null) {
      this.background = background;
      changed = true;
    }
    if (backdrop != null &&
        (backdrop.id != this.backdrop.id || backdrop.color != this.backdrop.color || !_mapNumEq(backdrop.params, this.backdrop.params))) {
      this.backdrop = backdrop;
      changed = true;
    }
    if (cardStyle != null && (cardStyle.id != this.cardStyle.id || !_mapNumEq(cardStyle.params, this.cardStyle.params))) {
      this.cardStyle = cardStyle;
      changed = true;
    }
    if (_themeTouched) {
      accent = siteColorFormat(siteThemeResolve(this.themeBaseId, this.themeDark).tokens.primary);
    }
    if (changed) notifyListeners();
  }

  void cardStyleReset() => designUpdate(cardStyle: SiteCardStyleDraft(id: siteCardStyleNormalizeId(cardStyle.id)));

  void backdropReset() => designUpdate(backdrop: SiteBackdropDraft(id: siteBackdropNormalizeId(backdrop.id)));

  bool _mapNumEq(Map<String, num> a, Map<String, num> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

Map<String, dynamic> _map(String raw) {
  if (raw.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
  } catch (_) {}
  return {};
}

Map<String, num> _numMap(Object? raw) {
  final out = <String, num>{};
  if (raw is Map) {
    for (final e in raw.entries) {
      if (e.value is num) out['${e.key}'] = e.value as num;
    }
  }
  return out;
}


List<SiteOverlayEffectDraft> _effectsFrom(Object? raw) {
  if (raw is! List) return [];
  final out = <SiteOverlayEffectDraft>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final m = item.map((k, v) => MapEntry(k.toString(), v));
    final id = '${m['id'] ?? ''}'.trim();
    final presetId = '${m['presetId'] ?? ''}'.trim();
    if (id.isEmpty || presetId.isEmpty) continue;
    final params = <String, Object?>{};
    final paramsRaw = m['params'];
    if (paramsRaw is Map) {
      for (final e in paramsRaw.entries) {
        params['${e.key}'] = e.value;
      }
    }
    final active = m['active'];
    out.add(SiteOverlayEffectDraft(
      id: id,
      presetId: presetId,
      params: params,
      active: active is bool ? active : active != false,
    ));
  }
  return out;
}
SiteBackgroundDraft? _backgroundFrom(Object? raw) {
  if (raw is! Map) return null;
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  return SiteBackgroundDraft(
    type: '${m['type'] ?? 'none'}',
    color: '${m['color'] ?? ''}',
    url: '${m['url'] ?? ''}',
    blur: (m['blur'] as num?)?.toDouble() ?? 0,
    overlay: (m['overlay'] as num?)?.toDouble() ?? 0,
    overlayTone: '${m['overlayTone'] ?? 'dark'}',
  );
}

SiteBackdropDraft? _backdropFrom(Object? raw) {
  if (raw is! Map) return null;
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  return SiteBackdropDraft(id: '${m['id'] ?? 'none'}', params: _numMap(m['params']), color: '${m['color'] ?? ''}');
}

SiteCardStyleDraft? _cardFrom(Object? raw) {
  if (raw is! Map) return null;
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  return SiteCardStyleDraft(id: '${m['id'] ?? 'solid'}', params: _numMap(m['params']));
}

SiteProfileDesignDraft? _profileFrom(Object? raw) {
  if (raw is! Map) return null;
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  return SiteProfileDesignDraft(
    showAvatar: m['showAvatar'] is bool ? m['showAvatar'] as bool : true,
    avatarSize: (m['avatarSize'] as num?)?.toDouble() ?? 40,
    avatarOutlineWidth: (m['avatarOutlineWidth'] as num?)?.toDouble() ?? 0,
    avatarOutlineColor: '${m['avatarOutlineColor'] ?? ''}',
    showTitle: m['showTitle'] is bool ? m['showTitle'] as bool : true,
    titleFontSize: (m['titleFontSize'] as num?)?.toDouble() ?? 22,
    titleFontFamily: '${m['titleFontFamily'] ?? ''}',
    titleAlign: '${m['titleAlign'] ?? 'center'}',
    showBio: m['showBio'] is bool ? m['showBio'] as bool : true,
    bioFontSize: (m['bioFontSize'] as num?)?.toDouble() ?? 13,
    bioFontFamily: '${m['bioFontFamily'] ?? ''}',
    bioAlign: '${m['bioAlign'] ?? 'center'}',
    showLocation: m['showLocation'] is bool ? m['showLocation'] as bool : true,
    showHours: m['showHours'] is bool ? m['showHours'] as bool : true,
    hubDefaultTab: '${m['hubDefaultTab'] ?? 'shop'}',
    hubPostsPreviewLimit: (m['hubPostsPreviewLimit'] as num?)?.toInt() ?? 0,
  );
}

SiteProductDesignDraft? _productFrom(Object? raw) {
  if (raw is! Map) return null;
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  return SiteProductDesignDraft(
    titleFontSize: (m['titleFontSize'] as num?)?.toDouble() ?? 14,
    titleFontWeight: siteFontWeightNormalize(m['titleFontWeight']?.toString()),
    titleFontFamily: '${m['titleFontFamily'] ?? ''}',
    titleItalic: m['titleItalic'] is bool ? m['titleItalic'] as bool : false,
    titleUnderline: m['titleUnderline'] is bool ? m['titleUnderline'] as bool : false,
    titleColor: '${m['titleColor'] ?? ''}',
    subtitleFontSize: (m['subtitleFontSize'] as num?)?.toDouble() ?? 12,
    subtitleFontWeight: siteFontWeightNormalize(m['subtitleFontWeight']?.toString()),
    subtitleFontFamily: '${m['subtitleFontFamily'] ?? ''}',
    subtitleItalic: m['subtitleItalic'] is bool ? m['subtitleItalic'] as bool : false,
    subtitleUnderline: m['subtitleUnderline'] is bool ? m['subtitleUnderline'] as bool : false,
    subtitleColor: '${m['subtitleColor'] ?? ''}',
    priceFontSize: (m['priceFontSize'] as num?)?.toDouble() ?? 14,
    priceFontWeight: siteFontWeightNormalize(m['priceFontWeight']?.toString()),
    priceFontFamily: '${m['priceFontFamily'] ?? ''}',
    priceItalic: m['priceItalic'] is bool ? m['priceItalic'] as bool : false,
    priceUnderline: m['priceUnderline'] is bool ? m['priceUnderline'] as bool : false,
    priceColor: '${m['priceColor'] ?? ''}',
  );
}

SiteFeaturedStripDraft _stripFrom(Object? raw, String defaultHeader) {
  if (raw is! Map) return SiteFeaturedStripDraft(header: defaultHeader);
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  final header = '${m['header'] ?? ''}'.trim();
  return SiteFeaturedStripDraft(
    showLabel: m['showLabel'] is bool ? m['showLabel'] as bool : true,
    slideFrom: '${m['slideFrom'] ?? 'left'}',
    headerAlign: '${m['headerAlign'] ?? 'left'}',
    header: header.isEmpty ? defaultHeader : header,
    headerFontSize: (m['headerFontSize'] as num?)?.toDouble() ?? 14,
    headerFontFamily: '${m['headerFontFamily'] ?? ''}',
    itemAlign: '${m['itemAlign'] ?? 'left'}',
    itemMode: siteFeaturedStripItemModeNormalize('${m['itemMode'] ?? ''}'),
  );
}

Map<String, Object?> _stripTo(SiteFeaturedStripDraft d) => {
      'showLabel': d.showLabel,
      'slideFrom': d.slideFrom,
      'headerAlign': d.headerAlign,
      'header': d.header,
      'headerFontSize': d.headerFontSize,
      'headerFontFamily': d.headerFontFamily,
      'itemAlign': d.itemAlign,
      'itemMode': d.itemMode,
    };

List<SiteBlockDesignDraft> _blocksFrom(Object? raw) {
  if (raw is! List) return [];
  final out = <SiteBlockDesignDraft>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final m = item.map((k, v) => MapEntry(k.toString(), v));
    final block = '${m['block'] ?? ''}'.trim();
    if (block.isEmpty) continue;
    out.add(SiteBlockDesignDraft(block: block, cardStyleId: '${m['cardStyleId'] ?? ''}', params: _numMap(m['params'])));
  }
  return out;
}
