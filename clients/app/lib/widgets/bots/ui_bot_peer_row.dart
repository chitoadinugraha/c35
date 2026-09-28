import 'package:alienai_c35/c/bot/bot_meta.dart' show kBotAppChannelId;
import 'package:alienai_c35/widgets/bots/ui_bot_peer_avatar.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);

class UiBotPeerRow extends StatelessWidget {
  const UiBotPeerRow({
    super.key,
    required this.peerName,
    this.peerPic = '',
    this.channelPlatform = '',
    this.lastMsg = '',
    this.time = '',
    this.aiReplyEnabled = true,
    this.unread = 0,
    this.selected = false,
    this.onTap,
  });

  final String peerName;
  final String peerPic;
  final String channelPlatform;
  final String lastMsg;
  final String time;
  final bool aiReplyEnabled;
  final int unread;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF18181B) : Colors.transparent;
    final titleColor = selected ? const Color(0xFFF4F4F5) : const Color(0xFFA1A1AA);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: selected ? const BorderSide(color: _border) : BorderSide.none),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFF1C1C22),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              UiBotPeerAvatar(name: peerName, pic: peerPic, platform: channelPlatform, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(peerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w500))),
                        if (time.isNotEmpty) Text(time, style: const TextStyle(color: Color(0xFF52525B), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(child: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12))),
                        if (!aiReplyEnabled && channelPlatform != kBotAppChannelId)
                          const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.stop_circle, size: 16, color: Color(0xFFEF4444))),
                        if (unread > 0) ...[
                          const SizedBox(width: 6),
                          _unreadBadge(unread),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unreadBadge(int count) => Container(
        constraints: const BoxConstraints(minWidth: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(999)),
        child: Text(count > 99 ? '99+' : '$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}
