import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);

class UiBotPeerRow extends StatelessWidget {
  const UiBotPeerRow({
    super.key,
    required this.peerName,
    this.peerPic = '',
    this.channel = '',
    this.lastMsg = '',
    this.time = '',
    this.aiReplyEnabled = true,
    this.unread = 0,
    this.selected = false,
    this.onTap,
  });

  final String peerName;
  final String peerPic;
  final String channel;
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
              _avatar(),
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
                        if (!aiReplyEnabled) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.stop_circle, size: 16, color: Color(0xFFEF4444))),
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

  Widget _avatar() => SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            UiUserAvatar(name: peerName, pic: peerPic, size: 40),
            if (channel.isNotEmpty)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: const Color(0xFF18181B), shape: BoxShape.circle, border: Border.all(color: _border)),
                  child: Icon(_channelIcon(channel), size: 11, color: const Color(0xFFA1A1AA)),
                ),
              ),
          ],
        ),
      );

  Widget _unreadBadge(int count) => Container(
        constraints: const BoxConstraints(minWidth: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(999)),
        child: Text(count > 99 ? '99+' : '$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
      );

  IconData _channelIcon(String ch) => switch (ch.toLowerCase()) {
        'telegram' => Icons.send_rounded,
        'whatsapp' => Icons.chat_rounded,
        'discord' => Icons.forum_outlined,
        'web' || 'site' => Icons.language_rounded,
        _ => Icons.hub_outlined,
      };
}
