import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared “Powered by [alien_receipt icon] alienai.id” attribution (guest hub, receipts on-screen).
class UiPoweredByAlien extends StatelessWidget {
  const UiPoweredByAlien({super.key, this.color, this.strongColor, this.fontSize = 12});

  static const brandLabel = 'alienai.id';
  static const alienReceiptIconAsset = 'assets/icons/alien_receipt.svg';

  final Color? color;
  final Color? strongColor;
  final double fontSize;

  static final _uri = Uri.parse('https://alienai.id/');

  @override
  Widget build(BuildContext context) {
    final muted = color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final strong = strongColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88);
    final iconSize = fontSize + 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Powered by', style: TextStyle(fontSize: fontSize, color: muted, fontWeight: FontWeight.w300)),
          const SizedBox(width: 5),
          SvgPicture.asset(alienReceiptIconAsset, width: iconSize, height: iconSize),
          const SizedBox(width: 4),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => launchUrl(_uri, mode: LaunchMode.externalApplication),
              behavior: HitTestBehavior.opaque,
              child: Text(
                brandLabel,
                style: TextStyle(fontSize: fontSize, color: strong, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
