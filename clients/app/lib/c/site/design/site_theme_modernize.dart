import 'dart:convert';

const guestThemeRenderStyleVersion = 2;

Map<String, dynamic> siteCreateDefaultThemeMap({String accent = '#2563eb'}) => {
      'accent': accent,
      'layout': 'hub',
      'renderStyleVersion': guestThemeRenderStyleVersion,
      'card': {
        'id': 'elevated',
        'params': {
          'radius': 16.0,
          'shadow': 2.0,
          'borderWidth': 0.0,
          'padding': 12.0,
        },
      },
      'profile': {
        'avatarSize': 88.0,
        'titleFontSize': 22.0,
        'bioFontSize': 14.0,
        'titleFontFamily': 'Inter',
      },
      'product': {'titleTransform': 'none'},
    };

String siteCreateDefaultThemeJson({String accent = '#2563eb'}) =>
    jsonEncode(siteCreateDefaultThemeMap(accent: accent));

/// Mirrors `guest_theme_modernize::modernize_theme_for_render` for in-app preview.
Map<String, dynamic> modernizeThemeForRender(Map<String, dynamic> theme) {
  if (theme.isEmpty) return theme;
  if (theme['dark'] == true) {
    return _applyDarkGlassDefaults(Map<String, dynamic>.from(theme));
  }
  final ver = _asInt(theme['renderStyleVersion']) ?? 0;
  if (ver >= guestThemeRenderStyleVersion) return theme;

  final out = Map<String, dynamic>.from(theme);
  _modernizeLightCard(out);
  _modernizeLightProfile(out);
  _modernizeLightProduct(out);
  out['renderStyleVersion'] = guestThemeRenderStyleVersion;
  return out;
}

Map<String, dynamic> modernizeThemeForRenderJson(String themeJson) {
  if (themeJson.trim().isEmpty) return {};
  final decoded = jsonDecode(themeJson);
  if (decoded is! Map<String, dynamic>) return {};
  return modernizeThemeForRender(decoded);
}

void _modernizeLightCard(Map<String, dynamic> out) {
  final card = Map<String, dynamic>.from(
    out['card'] is Map ? out['card'] as Map<String, dynamic> : const {},
  );
  final id = card['id']?.toString() ?? 'solid';
  if (id == 'solid' || id.isEmpty) {
    card['id'] = 'elevated';
  }
  final params = Map<String, dynamic>.from(
    card['params'] is Map ? card['params'] as Map<String, dynamic> : const {},
  );
  final radius = _asDouble(params['radius']) ?? 8.0;
  if (radius < 14.0) params['radius'] = 16.0;
  final shadow = _asDouble(params['shadow']) ?? 1.0;
  if (shadow < 2.0) params['shadow'] = 2.0;
  final borderW = _asDouble(params['borderWidth']) ?? 1.0;
  if (!params.containsKey('borderWidth') || borderW > 0.5) {
    params['borderWidth'] = 0.0;
  }
  card['params'] = params;
  out['card'] = card;
}

void _modernizeLightProfile(Map<String, dynamic> out) {
  final profile = Map<String, dynamic>.from(
    out['profile'] is Map ? out['profile'] as Map<String, dynamic> : const {},
  );
  _bumpDouble(profile, 'avatarSize', 88.0, 72.0);
  _bumpDouble(profile, 'titleFontSize', 22.0, 18.0);
  _bumpDouble(profile, 'bioFontSize', 14.0, 12.0);
  final titleFont = profile['titleFontFamily']?.toString() ?? '';
  if (titleFont.isEmpty) profile['titleFontFamily'] = 'Inter';
  out['profile'] = profile;
}

void _modernizeLightProduct(Map<String, dynamic> out) {
  final product = Map<String, dynamic>.from(
    out['product'] is Map ? out['product'] as Map<String, dynamic> : const {},
  );
  if (!product.containsKey('titleTransform')) {
    product['titleTransform'] = 'none';
  }
  out['product'] = product;
}

Map<String, dynamic> _applyDarkGlassDefaults(Map<String, dynamic> theme) {
  final ver = _asInt(theme['renderStyleVersion']) ?? 0;
  if (ver >= guestThemeRenderStyleVersion) return theme;

  final out = Map<String, dynamic>.from(theme);
  final card = Map<String, dynamic>.from(
    out['card'] is Map ? out['card'] as Map<String, dynamic> : const {},
  );
  final id = card['id']?.toString() ?? 'solid';
  if (id == 'solid' || id.isEmpty) card['id'] = 'glass';
  final params = Map<String, dynamic>.from(
    card['params'] is Map ? card['params'] as Map<String, dynamic> : const {},
  );
  params.putIfAbsent('radius', () => 16.0);
  params.putIfAbsent('blur', () => 14.0);
  card['params'] = params;
  out['card'] = card;

  final profile = Map<String, dynamic>.from(
    out['profile'] is Map ? out['profile'] as Map<String, dynamic> : const {},
  );
  final titleFont = profile['titleFontFamily']?.toString() ?? '';
  if (titleFont.isEmpty) profile['titleFontFamily'] = 'Outfit';
  out['profile'] = profile;

  out['renderStyleVersion'] = guestThemeRenderStyleVersion;
  return out;
}

void _bumpDouble(Map<String, dynamic> map, String key, double target, double legacyCap) {
  final cur = _asDouble(map[key]) ?? legacyCap;
  if (cur <= legacyCap) map[key] = target;
}

double? _asDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
