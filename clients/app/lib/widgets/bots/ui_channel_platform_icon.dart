import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:flutter/material.dart';

class UiChannelPlatformIcon extends StatelessWidget {
  const UiChannelPlatformIcon({super.key, required this.platform, this.size = 16, this.accent});

  final String platform;
  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final vis = channelPlatformVisual(platform);
    final iconify = vis.iconifyId;
    if (iconify.isNotEmpty) {
      return UiIcon(iconify, size: size, recolor: vis.iconifyRecolor, color: accent ?? vis.accent);
    }
    return Icon(vis.icon, size: size, color: accent ?? vis.accent);
  }
}