import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _deviceIconGrey = Color(0xFFA1A1AA);

/// Device list / mention picker icon (matches [UiDeviceRow]).
class UiDeviceKindIcon extends StatelessWidget {
  const UiDeviceKindIcon({
    super.key,
    required this.kind,
    this.type = '',
    this.browserEngine = '',
    this.size = 18,
    this.iconColor = _deviceIconGrey,
  });

  final String kind;
  final String type;
  final String browserEngine;
  final double size;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Center(child: _inner()),
      );

  Widget _inner() {
    final t = type.toLowerCase();
    if (t == 'browser' && browserEngine.toLowerCase() == 'extension') {
      final favicon = (size * 1.2).clamp(14.0, 24.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          'https://www.google.com/s2/favicons?domain=chrome.google.com&sz=64',
          width: favicon,
          height: favicon,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.public, size: size, color: iconColor),
        ),
      );
    }
    if (t == 'android') {
      return UiIcon('logos:android-icon', size: size, recolor: false);
    }
    if (t == 'windows') {
      final svg = (size * 1.25).clamp(16.0, 28.0);
      return SvgPicture.asset('assets/icons/windows.svg', width: svg, height: svg, fit: BoxFit.contain);
    }
    if (t == 'linux') {
      return Icon(Icons.terminal_outlined, size: size, color: iconColor);
    }
    return Icon(_iconForKind(kind, type), size: size, color: iconColor);
  }

  IconData _iconForKind(String k, String deviceType) => switch (deviceType.toLowerCase()) {
        'browser' => Icons.public_outlined,
        _ => switch (k.toLowerCase()) {
            'iot' => Icons.sensors_outlined,
            'remote' => Icons.laptop_mac_outlined,
            _ => Icons.devices_other_outlined,
          },
      };
}
