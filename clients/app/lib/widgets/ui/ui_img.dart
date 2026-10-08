import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ai/ui_serve_image.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_img_cached.dart';
import 'package:flutter/material.dart';

class UiImg extends StatelessWidget {
  const UiImg({super.key, required this.src, this.fallback, this.fit = BoxFit.cover, this.width, this.height, this.recolor = true});

  final String src;
  final Widget? fallback;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool recolor;

  Map<String, String>? _headers() {
    final token = sessionAuthToken();
    return token.isEmpty ? null : {'Authorization': 'Bearer $token'};
  }

  @override
  Widget build(BuildContext context) {
    final cleaned = src.trim();
    if (cleaned.isEmpty) return fallback ?? const SizedBox.shrink();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      final fb = fallback ?? const SizedBox.shrink();
      return UiImgCached(
        src: cleaned,
        networkUrl: cleaned,
        headers: _headers(),
        fit: fit,
        width: width,
        height: height,
        fallback: fb,
      );
    }
    if (cleaned.startsWith('/fs/') || cleaned.startsWith('fs/')) {
      return UiServeImage(path: cleaned.startsWith('/') ? cleaned : '/$cleaned', fit: fit, width: width, height: height, errorBuilder: (_) => fallback ?? const SizedBox.shrink());
    }
    if (cleaned.startsWith(kIconifyPicScheme) || iconifyIdFromPic(cleaned) != null) {
      return UiIcon(cleaned, size: width ?? height, recolor: recolor);
    }
    final url = mediaUrlResolve(cleaned);
    final fb = fallback ?? const SizedBox.shrink();
    return UiImgCached(
      src: cleaned,
      networkUrl: url,
      headers: _headers(),
      fit: fit,
      width: width,
      height: height,
      fallback: fb,
    );
  }
}
