import 'package:alienai_c35/guest_site/guest_site_product.dart';
import 'package:alienai_c35/widgets/ai/ui_serve_image.dart';
import 'package:flutter/material.dart';

/// Resolves site media paths the same way guest HTML / server `pic_url` does.
String guestSitePicUrl(String pic) => guestSitePicThumbUrl(pic);

enum GuestSitePicVariant { thumb, display }

/// In-app site preview: load `/fs/` through the logged-in API (CAS + session).
/// Published guest pages use thumb URLs on the public file host.
class GuestSitePic extends StatelessWidget {
  const GuestSitePic({
    super.key,
    required this.pic,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.error,
    this.variant = GuestSitePicVariant.thumb,
    this.onTap,
  });

  final String pic;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? error;
  final GuestSitePicVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = pic.trim();
    final fallback = error ?? const SizedBox.shrink();
    if (p.isEmpty) return fallback;
    if (p.startsWith('http://') || p.startsWith('https://')) {
      final img = Image.network(
        p,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
      return onTap == null ? img : GestureDetector(onTap: onTap, child: img);
    }
    final path = guestSitePicServePath(p, display: variant == GuestSitePicVariant.display);
    final child = UiServeImage(
      path: path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_) => fallback,
    );
    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }
}

Future<void> showGuestSitePicViewer(BuildContext context, String pic) {
  final p = pic.trim();
  if (p.isEmpty) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF18181B),
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GuestSitePic(
                pic: p,
                variant: GuestSitePicVariant.display,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
