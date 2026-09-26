import 'package:alienai_c35/widgets/ai/ui_serve_image.dart';
import 'package:flutter/material.dart';

/// `/fs/{hash}` image tile — wraps [UiServeImage].
class UiFsImage extends StatelessWidget {
  const UiFsImage({
    super.key,
    required this.path,
    required this.baseUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String path;
  final String baseUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) => UiServeImage(
        path: path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
}
