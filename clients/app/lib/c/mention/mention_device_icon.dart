import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/widgets/devices/ui_device_kind_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

/// Server `MentionItem.icon` for identities — see `mention_identity_icon` (Rust).
const mentionDeviceIconPrefix = 'device-kind:';
const mentionIdentityPicPrefix = 'identity-pic:';

class MentionDeviceIconSpec {
  const MentionDeviceIconSpec({required this.kind, required this.type, required this.browserEngine});

  final String kind;
  final String type;
  final String browserEngine;
}

MentionDeviceIconSpec? mentionDeviceIconSpec(String icon) {
  final raw = icon.trim();
  if (!raw.startsWith(mentionDeviceIconPrefix)) return null;
  final rest = raw.substring(mentionDeviceIconPrefix.length);
  final parts = rest.split(':');
  return switch (parts) {
    ['android'] => const MentionDeviceIconSpec(kind: 'remote', type: 'android', browserEngine: ''),
    ['windows'] => const MentionDeviceIconSpec(kind: 'remote', type: 'windows', browserEngine: ''),
    ['browser', 'extension'] => const MentionDeviceIconSpec(kind: 'remote', type: 'browser', browserEngine: 'extension'),
    ['browser', final engine] => MentionDeviceIconSpec(kind: 'remote', type: 'browser', browserEngine: engine),
    ['browser'] => const MentionDeviceIconSpec(kind: 'remote', type: 'browser', browserEngine: 'playwright'),
    ['iot'] => const MentionDeviceIconSpec(kind: 'iot', type: '', browserEngine: ''),
    ['remote'] => const MentionDeviceIconSpec(kind: 'remote', type: '', browserEngine: ''),
    _ => null,
  };
}

String? mentionIdentityPicPath(String icon) {
  final raw = icon.trim();
  if (!raw.startsWith(mentionIdentityPicPrefix)) return null;
  final path = raw.substring(mentionIdentityPicPrefix.length).trim();
  return path.isEmpty ? null : path;
}

Widget catalogMentionIdentityIcon(CatalogMention m, {double size = 16, Color iconColor = const Color(0xFFA1A1AA)}) {
  final picPath = mentionIdentityPicPath(m.icon);
  if (picPath != null) {
    final fallback = Icon(Icons.language_rounded, size: size, color: iconColor);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: UiImg(src: picPath, width: size, height: size, fit: BoxFit.cover, fallback: fallback, recolor: false),
    );
  }
  if (m.isDevice) return catalogMentionDeviceIcon(m, size: size, iconColor: iconColor);
  final raw = m.icon.trim();
  if (raw.startsWith('iconify://') || (raw.contains(':') && !raw.contains(' '))) {
    return UiIcon(raw, size: size, color: iconColor, recolor: true);
  }
  if (m.isSite) return Icon(Icons.language_rounded, size: size, color: iconColor);
  return Icon(Icons.alternate_email_rounded, size: size, color: iconColor);
}

Widget catalogMentionDeviceIcon(CatalogMention m, {double size = 16, Color iconColor = const Color(0xFFA1A1AA)}) {
  final spec = mentionDeviceIconSpec(m.icon);
  if (spec != null) {
    return UiDeviceKindIcon(kind: spec.kind, type: spec.type, browserEngine: spec.browserEngine, size: size, iconColor: iconColor);
  }
  return UiDeviceKindIcon(kind: 'remote', type: '', browserEngine: '', size: size, iconColor: iconColor);
}
