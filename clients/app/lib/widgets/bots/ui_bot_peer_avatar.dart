import 'package:alienai_c35/c/bot/bot_meta.dart' show kBotAppChannelId;
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:alienai_c35/widgets/bots/ui_channel_platform_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

const _badgeBorder = Color(0xFF18181B);

class UiBotPeerAvatar extends StatelessWidget {
  const UiBotPeerAvatar({
    super.key,
    required this.name,
    this.pic = '',
    this.platform = '',
    this.size = 40,
    this.showChannelBadge = true,
  });

  final String name;
  final String pic;
  final String platform;
  final double size;
  final bool showChannelBadge;

  String _picResolved() {
    if (pic.trim().isNotEmpty) return pic;
    if (platform == kBotAppChannelId && Session.instance.pic.trim().isNotEmpty) return Session.instance.pic;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final badge = size * 0.44;
    final vis = platform.trim().isEmpty ? null : channelPlatformVisual(platform);
    final resolvedPic = _picResolved();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          UiUserAvatar(name: name, pic: resolvedPic, size: size),
          if (showChannelBadge && vis != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Tooltip(
                message: vis.label,
                child: Container(
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    color: vis.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: platform == kBotAppChannelId ? const Color(0xFF3F3F46) : _badgeBorder, width: 1.5),
                  ),
                  child: platform == kBotAppChannelId
                      ? Icon(vis.icon, size: badge * 0.58, color: const Color(0xFFE4E4E7))
                      : UiChannelPlatformIcon(platform: platform, size: badge * 0.58),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
