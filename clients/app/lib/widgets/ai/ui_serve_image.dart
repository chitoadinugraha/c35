import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ui/ui_img_cached.dart';
import 'package:flutter/material.dart';

class UiServeImage extends StatelessWidget {
  const UiServeImage({super.key, required this.path, this.fit = BoxFit.cover, this.width, this.height, this.errorBuilder});
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: sessionTick,
        builder: (_, __, ___) => _build(context),
      );

  Widget _build(BuildContext context) {
    final p = path.trim();
    if (p.isEmpty) return errorBuilder?.call(context) ?? const SizedBox.shrink();
    final url = p.startsWith('http') ? p : mediaUrlResolve(p);
    final token = sessionAuthToken();
    final loading = errorBuilder?.call(context) ?? const SizedBox.shrink();
    final headers = token.isEmpty ? null : {'Authorization': 'Bearer $token'};
    return UiImgCached(
      src: p,
      networkUrl: url,
      headers: headers,
      fit: fit,
      width: width,
      height: height,
      fallback: loading,
    );
  }
}
