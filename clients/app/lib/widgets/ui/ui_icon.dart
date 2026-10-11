import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const kIconifyPicScheme = 'iconify://';

String? iconifyIdFromPic(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty || s.startsWith('http://') || s.startsWith('https://') || s.startsWith('data:')) return null;
  if (s.startsWith(kIconifyPicScheme)) {
    final id = s.substring(kIconifyPicScheme.length);
    return id.isEmpty ? null : id;
  }
  if (s.contains(':') && !s.contains(' ')) return s;
  return null;
}

final _iconSvgCache = <String, Future<String?>>{};

Future<String?> iconSvgStringLoad(String iconId) {
  final id = iconifyIdFromPic(iconId) ?? iconId.trim();
  if (id.isEmpty) return Future.value(null);
  final url = 'https://api.iconify.design/$id.svg';
  return _iconSvgCache.putIfAbsent(url, () async {
    try {
      final file = await mediaDiskCacheFetch(url);
      if (file != null) return iconSvgSanitize(await file.readAsString());
      return null;
    } catch (_) {
      return null;
    }
  });
}

String iconSvgSanitize(String svg) {
  var s = svg;
  s = s.replaceAll(RegExp(r'<filter\b[^>]*>[\s\S]*?</filter>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<filter\b[^>]*/>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'\s+filter="[^"]*"'), '');
  return s;
}

class UiIcon extends StatelessWidget {
  const UiIcon(this.iconId, {super.key, this.size, this.color, this.recolor = true, this.fallback});

  final String iconId;
  final double? size;
  final Color? color;
  final bool recolor;
  final IconData? fallback;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final id = iconifyIdFromPic(iconId);
    if (id == null) {
      return SizedBox(
        width: resolvedSize,
        height: resolvedSize,
        child: Center(child: Text(iconId, style: TextStyle(fontSize: resolvedSize * 0.4))),
      );
    }
    final resolvedColor = color ?? iconTheme.color ?? DefaultTextStyle.of(context).style.color;
    final colorFilter = recolor && resolvedColor != null ? ColorFilter.mode(resolvedColor, BlendMode.srcIn) : null;
    final placeholder = Icon(fallback ?? Icons.image_outlined, size: resolvedSize * 0.85, color: resolvedColor?.withValues(alpha: 0.35));
    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: FutureBuilder<String?>(
        future: iconSvgStringLoad(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return placeholder;
          final value = snapshot.data;
          if (value == null) return Icon(fallback ?? Icons.image_not_supported_outlined, size: resolvedSize, color: resolvedColor);
          return SvgPicture.string(value, width: resolvedSize, height: resolvedSize, fit: BoxFit.contain, colorFilter: colorFilter);
        },
      ),
    );
  }
}
