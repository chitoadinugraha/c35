import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'package:alienai_c35/c/log.dart';

const _iconifyScheme = 'iconify://';

String? overlayEffectIconifyId(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return null;
  if (s.startsWith(_iconifyScheme)) {
    final id = s.substring(_iconifyScheme.length);
    return id.isEmpty ? null : id;
  }
  if (s.contains(':') && !s.contains(' ')) return s;
  return null;
}

final _iconSvgCache = <String, Future<String?>>{};

Future<String?> overlayEffectIconSvgLoad(String iconId) {
  final id = overlayEffectIconifyId(iconId) ?? iconId.trim();
  if (id.isEmpty) return Future.value(null);
  final url = 'https://api.iconify.design/$id.svg';
  return _iconSvgCache.putIfAbsent(url, () async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      return res.body;
    } catch (e) {
      lError(e);
      return null;
    }
  });
}

/// Renders preset `iconify://…` icons with Material fallback.
class UiOverlayEffectIcon extends StatelessWidget {
  const UiOverlayEffectIcon({
    super.key,
    required this.icon,
    this.size = 20,
    this.color,
    this.fallback = Icons.auto_awesome_outlined,
  });

  final String icon;
  final double size;
  final Color? color;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    final id = overlayEffectIconifyId(icon);
    if (id == null) {
      return Icon(fallback, size: size, color: color);
    }
    final resolvedColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<String?>(
        future: overlayEffectIconSvgLoad(id),
        builder: (context, snap) {
          final svg = snap.data;
          if (svg == null) {
            return Icon(fallback, size: size, color: resolvedColor);
          }
          return SvgPicture.string(
            svg,
            width: size,
            height: size,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
          );
        },
      ),
    );
  }
}
