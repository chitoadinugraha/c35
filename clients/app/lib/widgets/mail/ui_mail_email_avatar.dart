import 'package:alienai_c35/c/mail/mail_email_avatar.dart';
import 'package:alienai_c35/widgets/ai/ui_serve_image.dart';
import 'package:flutter/material.dart';

class UiMailEmailAvatar extends StatelessWidget {
  const UiMailEmailAvatar({
    super.key,
    required this.email,
    this.hintUrl = '',
    this.resolver,
    this.radius = 16,
    this.batchSelected = false,
    this.selectionAccentColor,
  });

  final String email;
  final String hintUrl;
  final MailEmailAvatarResolver? resolver;
  final double radius;
  final bool batchSelected;
  final Color? selectionAccentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = selectionAccentColor ?? cs.primary;
    if (batchSelected) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: accent,
        child: Icon(Icons.check, size: radius, color: cs.onPrimary),
      );
    }

    final letter = mailEmailAvatarLetter(email);
    final color = mailEmailAvatarColor(email);
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(letter, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.75)),
    );

    final netUrl = mailEmailAvatarNetworkUrl(
      email: email,
      hintUrl: hintUrl,
      resolver: resolver,
      gravatarSize: (radius * 2 * 2).clamp(40, 160).toInt(),
    );
    if (netUrl.isEmpty) return fallback;

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: netUrl.startsWith('http')
            ? Image.network(netUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
            : UiServeImage(path: netUrl, fit: BoxFit.cover, errorBuilder: (_) => fallback),
      ),
    );
  }
}
