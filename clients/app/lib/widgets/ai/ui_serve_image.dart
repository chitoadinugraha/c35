import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/session.dart';
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
    final url = p.startsWith('http') ? p : '${C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '')}${p.startsWith('/') ? p : '/$p'}';
    final token = sessionAuthToken();
    final loading = errorBuilder?.call(context) ?? const SizedBox.shrink();
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
      loadingBuilder: (_, child, progress) => progress == null ? child : loading,
      errorBuilder: (context, error, stackTrace) => errorBuilder?.call(context) ?? const Center(child: Icon(Icons.broken_image_rounded, color: Color(0xFF71717A), size: 28)),
    );
  }
}
