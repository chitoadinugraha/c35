import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared “Powered by [alien] alienai.id” attribution for guest hub (CSA).
class UiPoweredByAlien extends StatelessWidget {
  const UiPoweredByAlien({super.key, this.color, this.strongColor, this.fontSize = 12});

  final Color? color;
  final Color? strongColor;
  final double fontSize;

  static final _uri = Uri.parse('https://alienai.id/');

  @override
  Widget build(BuildContext context) {
    final muted = color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final strong = strongColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88);
    return GestureDetector(
      onTap: () => launchUrl(_uri, mode: LaunchMode.externalApplication),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Powered by', style: TextStyle(fontSize: fontSize, color: muted, fontWeight: FontWeight.w300)),
            const SizedBox(width: 5),
            UiAlienIcon(size: fontSize + 2, color: strong),
            const SizedBox(width: 4),
            Text(
              'alienai.id',
              style: TextStyle(fontSize: fontSize, color: strong, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
