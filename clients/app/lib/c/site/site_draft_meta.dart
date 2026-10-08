import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';

export 'package:alienai_c35/c/site/design/site_design_models.dart'
    show SiteProductDesignDraft, siteFontWeightNormalize, siteFontWeightParse, siteFontWeightLabel, siteFontWeightIds;

class SiteTaxDraft {
  const SiteTaxDraft({
    required this.id,
    required this.type,
    required this.name,
    this.percent = 0,
    this.active = true,
  });

  final String id;
  final String type;
  final String name;
  final double percent;
  final bool active;

  SiteTaxDraft copyWith({String? id, String? type, String? name, double? percent, bool? active}) => SiteTaxDraft(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        percent: percent ?? this.percent,
        active: active ?? this.active,
      );
}


const kSiteTaxTypeServiceTax = 'service_tax';
const kSiteTaxTypePpn = 'ppn';
const kSiteTaxTypePph = 'pph';

const kSiteTaxTypes = [kSiteTaxTypeServiceTax, kSiteTaxTypePpn, kSiteTaxTypePph];

String siteTaxTypeNormalize(String? raw) {
  final t = (raw ?? '').trim().toLowerCase();
  return switch (t) {
    'service_tax' || 'service' => kSiteTaxTypeServiceTax,
    'ppn' || 'vat' || 'percent' => kSiteTaxTypePpn,
    'pph' || 'withholding' => kSiteTaxTypePph,
    _ when kSiteTaxTypes.contains(t) => t,
    _ => kSiteTaxTypePpn,
  };
}

String siteTaxDefaultName(String type) => switch (siteTaxTypeNormalize(type)) {
      kSiteTaxTypeServiceTax => 'Service tax',
      kSiteTaxTypePph => 'PPh',
      _ => 'PPN',
    };

class SiteDraftMeta {
  const SiteDraftMeta({this.taxes = const [], this.productDesign = const SiteProductDesignDraft()});

  final List<SiteTaxDraft> taxes;
  final SiteProductDesignDraft productDesign;
}

Map<String, dynamic> _metaMap(String metaJson) {
  if (metaJson.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(metaJson);
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}

SiteTaxDraft siteTaxDraftFromJson(Map<String, dynamic> m) => SiteTaxDraft(
      id: m['id']?.toString() ?? '',
      type: siteTaxTypeNormalize(m['type']?.toString()),
      name: m['name']?.toString() ?? '',
      percent: (m['percent'] as num?)?.toDouble() ?? 0,
      active: m['active'] is bool ? m['active'] as bool : true,
    );

Map<String, dynamic> siteTaxDraftToJson(SiteTaxDraft t) => {
      'id': t.id,
      'type': t.type,
      'name': t.name,
      'percent': t.percent,
      'active': t.active,
    };

SiteProductDesignDraft siteProductDesignFromJson(Object? raw) {
  if (raw is! Map) return const SiteProductDesignDraft();
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  return SiteProductDesignDraft(
    titleFontSize: (m['titleFontSize'] as num?)?.toDouble() ?? 14,
    titleFontWeight: siteFontWeightNormalize(m['titleFontWeight']?.toString()),
    titleFontFamily: m['titleFontFamily']?.toString() ?? '',
    titleItalic: m['titleItalic'] is bool ? m['titleItalic'] as bool : false,
    titleUnderline: m['titleUnderline'] is bool ? m['titleUnderline'] as bool : false,
    titleColor: m['titleColor']?.toString() ?? '',
    subtitleFontSize: (m['subtitleFontSize'] as num?)?.toDouble() ?? 12,
    subtitleFontWeight: siteFontWeightNormalize(m['subtitleFontWeight']?.toString()),
    subtitleFontFamily: m['subtitleFontFamily']?.toString() ?? '',
    subtitleItalic: m['subtitleItalic'] is bool ? m['subtitleItalic'] as bool : false,
    subtitleUnderline: m['subtitleUnderline'] is bool ? m['subtitleUnderline'] as bool : false,
    subtitleColor: m['subtitleColor']?.toString() ?? '',
    priceFontSize: (m['priceFontSize'] as num?)?.toDouble() ?? 14,
    priceFontWeight: siteFontWeightNormalize(m['priceFontWeight']?.toString()),
    priceFontFamily: m['priceFontFamily']?.toString() ?? '',
    priceItalic: m['priceItalic'] is bool ? m['priceItalic'] as bool : false,
    priceUnderline: m['priceUnderline'] is bool ? m['priceUnderline'] as bool : false,
    priceColor: m['priceColor']?.toString() ?? '',
  );
}

Map<String, dynamic> siteProductDesignToJson(SiteProductDesignDraft d) => {
      'titleFontSize': d.titleFontSize,
      'titleFontWeight': d.titleFontWeight,
      'titleFontFamily': d.titleFontFamily,
      'titleItalic': d.titleItalic,
      'titleUnderline': d.titleUnderline,
      'titleColor': d.titleColor,
      'subtitleFontSize': d.subtitleFontSize,
      'subtitleFontWeight': d.subtitleFontWeight,
      'subtitleFontFamily': d.subtitleFontFamily,
      'subtitleItalic': d.subtitleItalic,
      'subtitleUnderline': d.subtitleUnderline,
      'subtitleColor': d.subtitleColor,
      'priceFontSize': d.priceFontSize,
      'priceFontWeight': d.priceFontWeight,
      'priceFontFamily': d.priceFontFamily,
      'priceItalic': d.priceItalic,
      'priceUnderline': d.priceUnderline,
      'priceColor': d.priceColor,
    };

SiteDraftMeta siteDraftMetaParse(String metaJson) {
  final map = _metaMap(metaJson);
  final taxesRaw = map['taxes'];
  final taxes = taxesRaw is List
      ? taxesRaw
          .whereType<Map<String, dynamic>>()
          .map(siteTaxDraftFromJson)
          .toList(growable: false)
      : const <SiteTaxDraft>[];
  return SiteDraftMeta(
    taxes: taxes,
    productDesign: siteProductDesignFromJson(map['product_design']),
  );
}

String siteDraftMetaMerge(
  String metaJson, {
  List<SiteTaxDraft>? taxes,
  SiteProductDesignDraft? productDesign,
}) {
  final map = _metaMap(metaJson);
  if (taxes != null) map['taxes'] = taxes.map(siteTaxDraftToJson).toList(growable: false);
  if (productDesign != null) map['product_design'] = siteProductDesignToJson(productDesign);
  return jsonEncode(map);
}

SiteDoc siteDocWithMetaJson(SiteDoc doc, String metaJson) {
  final out = doc.clone();
  out.metaJson = metaJson;
  return out;
}

String siteMetaFieldGet(String metaJson, String key) => _metaMap(metaJson)[key]?.toString() ?? '';

String siteMetaMergeFields(String metaJson, {String? tagline, String? seoTitle}) {
  final map = _metaMap(metaJson);
  if (tagline != null) {
    if (tagline.trim().isEmpty) {
      map.remove('tagline');
    } else {
      map['tagline'] = tagline.trim();
    }
  }
  if (seoTitle != null) {
    if (seoTitle.trim().isEmpty) {
      map.remove('seo_title');
    } else {
      map['seo_title'] = seoTitle.trim();
    }
  }
  return jsonEncode(map);
}

Map<String, dynamic> siteThemeParse(String themeJson) => _metaMap(themeJson);

String siteThemeAccentGet(String themeJson) => siteThemeParse(themeJson)['accent']?.toString() ?? '';

String siteThemeMergeAccent(String themeJson, String accent) {
  final map = siteThemeParse(themeJson);
  final v = accent.trim();
  if (v.isEmpty) {
    map.remove('accent');
  } else {
    map['accent'] = v;
  }
  return jsonEncode(map);
}

SiteDoc siteDocWithThemeJson(SiteDoc doc, String themeJson) {
  final out = doc.clone();
  out.themeJson = themeJson;
  return out;
}
