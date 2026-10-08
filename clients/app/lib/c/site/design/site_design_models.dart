import 'package:flutter/material.dart';

class SiteBackgroundDraft {
  const SiteBackgroundDraft({
    this.type = 'none',
    this.color = '',
    this.url = '',
    this.blur = 0,
    this.overlay = 0,
    this.overlayTone = 'dark',
  });

  final String type;
  final String color;
  final String url;
  final double blur;
  final double overlay;
  final String overlayTone;

  SiteBackgroundDraft copyWith({
    String? type,
    String? color,
    String? url,
    double? blur,
    double? overlay,
    String? overlayTone,
  }) =>
      SiteBackgroundDraft(
        type: type ?? this.type,
        color: color ?? this.color,
        url: url ?? this.url,
        blur: blur ?? this.blur,
        overlay: overlay ?? this.overlay,
        overlayTone: overlayTone ?? this.overlayTone,
      );
}

class SiteCardStyleDraft {
  const SiteCardStyleDraft({
    this.id = 'solid',
    this.params = const {},
  });

  final String id;
  final Map<String, num> params;

  SiteCardStyleDraft copyWith({String? id, Map<String, num>? params}) =>
      SiteCardStyleDraft(id: id ?? this.id, params: params ?? this.params);
}

class SiteBackdropDraft {
  const SiteBackdropDraft({
    this.id = 'none',
    this.params = const {},
    this.color = '',
  });

  final String id;
  final Map<String, num> params;
  /// Empty = theme primary.
  final String color;

  SiteBackdropDraft copyWith({String? id, Map<String, num>? params, String? color, bool clearColor = false}) =>
      SiteBackdropDraft(
        id: id ?? this.id,
        params: params ?? this.params,
        color: clearColor ? '' : (color ?? this.color),
      );
}

/// Per guest block override — empty [cardStyleId] inherits global [SiteCardStyleDraft].
/// [cardStyleId] `none` = bare / no container (link block).
class SiteBlockDesignDraft {
  const SiteBlockDesignDraft({
    required this.block,
    this.cardStyleId = '',
    this.params = const {},
  });

  final String block;
  final String cardStyleId;
  final Map<String, num> params;

  bool get inheritsGlobal => cardStyleId.isEmpty;
  bool get isBare => cardStyleId == 'none';

  SiteBlockDesignDraft copyWith({String? cardStyleId, Map<String, num>? params, bool clearOverride = false}) =>
      SiteBlockDesignDraft(
        block: block,
        cardStyleId: clearOverride ? '' : (cardStyleId ?? this.cardStyleId),
        params: clearOverride ? const {} : (params ?? this.params),
      );
}

class SiteProductDesignDraft {
  const SiteProductDesignDraft({
    this.titleFontSize = 14,
    this.titleFontWeight = 'w600',
    this.titleFontFamily = '',
    this.titleItalic = false,
    this.titleUnderline = false,
    this.titleColor = '',
    this.subtitleFontSize = 12,
    this.subtitleFontWeight = 'w400',
    this.subtitleFontFamily = '',
    this.subtitleItalic = false,
    this.subtitleUnderline = false,
    this.subtitleColor = '',
    this.priceFontSize = 14,
    this.priceFontWeight = 'w600',
    this.priceFontFamily = '',
    this.priceItalic = false,
    this.priceUnderline = false,
    this.priceColor = '',
  });

  final double titleFontSize;
  final String titleFontWeight;
  final String titleFontFamily;
  final bool titleItalic;
  final bool titleUnderline;
  final String titleColor;
  final double subtitleFontSize;
  final String subtitleFontWeight;
  final String subtitleFontFamily;
  final bool subtitleItalic;
  final bool subtitleUnderline;
  final String subtitleColor;
  final double priceFontSize;
  final String priceFontWeight;
  final String priceFontFamily;
  final bool priceItalic;
  final bool priceUnderline;
  final String priceColor;

  SiteProductDesignDraft copyWith({
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
  }) =>
      SiteProductDesignDraft(
        titleFontSize: titleFontSize ?? this.titleFontSize,
        titleFontWeight: titleFontWeight ?? this.titleFontWeight,
        titleFontFamily: titleFontFamily ?? this.titleFontFamily,
        titleItalic: titleItalic ?? this.titleItalic,
        titleUnderline: titleUnderline ?? this.titleUnderline,
        titleColor: titleColor ?? this.titleColor,
        subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
        subtitleFontWeight: subtitleFontWeight ?? this.subtitleFontWeight,
        subtitleFontFamily: subtitleFontFamily ?? this.subtitleFontFamily,
        subtitleItalic: subtitleItalic ?? this.subtitleItalic,
        subtitleUnderline: subtitleUnderline ?? this.subtitleUnderline,
        subtitleColor: subtitleColor ?? this.subtitleColor,
        priceFontSize: priceFontSize ?? this.priceFontSize,
        priceFontWeight: priceFontWeight ?? this.priceFontWeight,
        priceFontFamily: priceFontFamily ?? this.priceFontFamily,
        priceItalic: priceItalic ?? this.priceItalic,
        priceUnderline: priceUnderline ?? this.priceUnderline,
        priceColor: priceColor ?? this.priceColor,
      );
}

FontWeight siteFontWeightParse(String raw) => switch (raw.trim()) {
      'w300' || 'light' => FontWeight.w300,
      'w400' || 'regular' || 'normal' => FontWeight.w400,
      'w500' || 'medium' => FontWeight.w500,
      'w700' || 'bold' => FontWeight.w700,
      'w800' || 'extraBold' => FontWeight.w800,
      'w900' || 'black' => FontWeight.w900,
      _ => FontWeight.w600,
    };

String siteFontWeightLabel(String raw) => switch (siteFontWeightNormalize(raw)) {
      'w300' => 'Light',
      'w400' => 'Regular',
      'w500' => 'Medium',
      'w700' => 'Bold',
      'w800' => 'Extra bold',
      'w900' => 'Black',
      _ => 'Semi bold',
    };

String siteFontWeightNormalize(String? raw) {
  final w = (raw ?? '').trim();
  return switch (w) {
    'w300' || 'light' => 'w300',
    'w400' || 'regular' || 'normal' => 'w400',
    'w500' || 'medium' => 'w500',
    'w700' || 'bold' => 'w700',
    'w800' || 'extraBold' => 'w800',
    'w900' || 'black' => 'w900',
    'w600' || 'semiBold' || 'semibold' => 'w600',
    _ => 'w600',
  };
}

const siteFontWeightIds = ['w300', 'w400', 'w500', 'w600', 'w700', 'w800', 'w900'];

class SiteProfileDesignDraft {
  const SiteProfileDesignDraft({
    this.showAvatar = true,
    this.avatarSize = 40,
    this.avatarOutlineWidth = 0,
    this.avatarOutlineColor = '',
    this.showTitle = true,
    this.titleFontSize = 22,
    this.titleFontFamily = '',
    this.titleAlign = 'center',
    this.showBio = true,
    this.bioFontSize = 13,
    this.bioFontFamily = '',
    this.bioAlign = 'center',
    this.showLocation = true,
    this.showHours = true,
    this.hubDefaultTab = 'shop',
    this.hubPostsPreviewLimit = 0,
  });

  final bool showAvatar;
  final double avatarSize;
  final double avatarOutlineWidth;
  final String avatarOutlineColor;
  final bool showTitle;
  final double titleFontSize;
  final String titleFontFamily;
  final String titleAlign;
  final bool showBio;
  final double bioFontSize;
  final String bioFontFamily;
  final String bioAlign;
  final bool showLocation;
  final bool showHours;
  /// `shop` | `posts`
  final String hubDefaultTab;
  /// 0 = use [siteHubPostsPreviewLimitDefault].
  final int hubPostsPreviewLimit;

  SiteProfileDesignDraft copyWith({
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
  }) =>
      SiteProfileDesignDraft(
        showAvatar: showAvatar ?? this.showAvatar,
        avatarSize: avatarSize ?? this.avatarSize,
        avatarOutlineWidth: avatarOutlineWidth ?? this.avatarOutlineWidth,
        avatarOutlineColor: avatarOutlineColor ?? this.avatarOutlineColor,
        showTitle: showTitle ?? this.showTitle,
        titleFontSize: titleFontSize ?? this.titleFontSize,
        titleFontFamily: titleFontFamily ?? this.titleFontFamily,
        titleAlign: titleAlign ?? this.titleAlign,
        showBio: showBio ?? this.showBio,
        bioFontSize: bioFontSize ?? this.bioFontSize,
        bioFontFamily: bioFontFamily ?? this.bioFontFamily,
        bioAlign: bioAlign ?? this.bioAlign,
        showLocation: showLocation ?? this.showLocation,
        showHours: showHours ?? this.showHours,
        hubDefaultTab: hubDefaultTab ?? this.hubDefaultTab,
        hubPostsPreviewLimit: hubPostsPreviewLimit ?? this.hubPostsPreviewLimit,
      );
}

const siteFeaturedStripItemModeCard = 'card';
const siteFeaturedStripItemModeIcon = 'icon';
const siteFeaturedStripItemModeIconLabel = 'icon_label';

const siteFeaturedStripItemModeOptions = <(String id, String label)>[
  (siteFeaturedStripItemModeCard, 'Card'),
  (siteFeaturedStripItemModeIcon, 'Icon'),
  (siteFeaturedStripItemModeIconLabel, 'Icon with label'),
];

String siteFeaturedStripItemModeNormalize(String raw) {
  final s = raw.trim();
  return switch (s) {
    '' => siteFeaturedStripItemModeIcon,
    'tile' => siteFeaturedStripItemModeCard,
    siteFeaturedStripItemModeCard || siteFeaturedStripItemModeIcon || siteFeaturedStripItemModeIconLabel => s,
    _ => siteFeaturedStripItemModeIcon,
  };
}

String siteFeaturedStripItemModeLabel(String mode) => switch (siteFeaturedStripItemModeNormalize(mode)) {
      siteFeaturedStripItemModeCard => 'Card',
      siteFeaturedStripItemModeIconLabel => 'Icon with label',
      _ => 'Icon',
    };

bool siteFeaturedStripItemModeUsesCard(String mode) => siteFeaturedStripItemModeNormalize(mode) == siteFeaturedStripItemModeCard;

class SiteFeaturedStripDraft {
  const SiteFeaturedStripDraft({
    this.showLabel = true,
    this.slideFrom = 'left',
    this.headerAlign = 'left',
    this.header = '',
    this.headerFontSize = 14,
    this.headerFontFamily = '',
    this.itemAlign = 'left',
    this.itemMode = siteFeaturedStripItemModeIcon,
  });

  final bool showLabel;
  final String slideFrom;
  final String headerAlign;
  final String header;
  final double headerFontSize;
  final String headerFontFamily;
  final String itemAlign;
  final String itemMode;

  SiteFeaturedStripDraft copyWith({
    bool? showLabel,
    String? slideFrom,
    String? headerAlign,
    String? header,
    double? headerFontSize,
    String? headerFontFamily,
    String? itemAlign,
    String? itemMode,
  }) =>
      SiteFeaturedStripDraft(
        showLabel: showLabel ?? this.showLabel,
        slideFrom: slideFrom ?? this.slideFrom,
        headerAlign: headerAlign ?? this.headerAlign,
        header: header ?? this.header,
        headerFontSize: headerFontSize ?? this.headerFontSize,
        headerFontFamily: headerFontFamily ?? this.headerFontFamily,
        itemAlign: itemAlign ?? this.itemAlign,
        itemMode: itemMode ?? this.itemMode,
      );
}

const siteDesignBlockEntries = [
  ('profile', 'Profile'),
  ('partners_display', 'Partners display'),
  ('clients_display', 'Clients display'),
  ('link', 'Social links'),
  ('site_product', 'Products'),
];

const siteFeaturedDisplayIds = ['partners_display', 'clients_display'];

const siteCardStyleBlockIds = ['link', 'site_product', 'partners_display', 'clients_display'];

const siteFeaturedPartnersDefaultHeader = 'Featured Partners';
const siteFeaturedClientsDefaultHeader = 'Featured Clients';

String siteFeaturedDisplayDefaultHeader(String id) =>
    id == 'partners_display' ? siteFeaturedPartnersDefaultHeader : siteFeaturedClientsDefaultHeader;

String siteFeaturedDisplayKind(String id) => id == 'partners_display' ? 'partners' : 'clients';

String siteProfileDesignSubtitle(SiteProfileDesignDraft d) {
  final parts = <String>[
    'Avatar ${d.avatarSize.round()}px',
    'Title ${d.titleFontSize.round()}px',
    if (d.showLocation || d.showHours) 'Meta',
  ];
  return parts.join(' · ');
}

String siteFeaturedStripSubtitle(SiteFeaturedStripDraft d) {
  final label = d.showLabel ? 'Label on' : 'Label off';
  return '$label · ${siteFeaturedStripItemModeLabel(d.itemMode)}';
}

const siteBackdropIds = ['none', 'glow', 'mesh', 'grain', 'diamond', 'aurora'];

const siteDesignAppearanceIds = ['theme', 'cards', 'background', 'backdrop'];

String siteDesignBlockItemId(String block) => block;

String? siteDesignBlockFromItemId(String id) =>
    siteDesignBlockEntries.any((e) => e.$1 == id) ? id : null;

bool siteDesignBlockIsFeatured(String id) => siteFeaturedDisplayIds.contains(id);

bool siteDesignBlockIsProfile(String id) => id == 'profile';

bool siteDesignBlockHasCardStyle(String id) => siteCardStyleBlockIds.contains(id);

String siteDesignItemLabel(String id) {
  for (final (blockId, label) in siteDesignBlockEntries) {
    if (id == blockId) return label;
  }
  return switch (id) {
    'theme' => 'Theme',
    'cards' => 'Cards',
    'background' => 'Background',
    'backdrop' => 'Backdrop',
    _ => id,
  };
}

List<String> get siteDesignItemIds => [
      ...siteDesignAppearanceIds,
      for (final (id, _) in siteDesignBlockEntries) siteDesignBlockItemId(id),
    ];

String siteBackdropLabel(String id) => switch (id) {
      'glow' => 'Glow',
      'mesh' => 'Mesh',
      'grain' => 'Grain',
      'diamond' => 'Diamond',
      'aurora' => 'Aurora',
      _ => 'None',
    };
