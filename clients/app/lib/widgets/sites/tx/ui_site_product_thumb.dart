import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _accent = Color(0xFF34D399);
const _border = Color(0xFF3F3F46);

class UiSiteProductThumb extends StatelessWidget {
  const UiSiteProductThumb({super.key, required this.product, this.size = 44});

  final SiteProduct product;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          border: Border.all(color: _border.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: product.pic.trim().isEmpty
            ? UiIcon(
                'iconify://${product.icon.trim().isEmpty ? 'mdi:shopping' : product.icon.trim()}',
                size: size * 0.45,
                color: _muted,
              )
            : UiImg(
                src: product.pic,
                width: size,
                height: size,
                fit: BoxFit.cover,
                fallback: Icon(Icons.shopping_bag_outlined, size: size * 0.45, color: _accent),
              ),
      );
}
