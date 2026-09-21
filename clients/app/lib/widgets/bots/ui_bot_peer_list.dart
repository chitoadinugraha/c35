import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_peer_row.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiBotPeerList extends StatelessWidget {
  const UiBotPeerList({
    super.key,
    required this.store,
    required this.selectedChatId,
    required this.onSelect,
    this.showBack = false,
    this.onBack,
  });

  final BotStore store;
  final String? selectedChatId;
  final ValueChanged<String?> onSelect;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final peers = store.peers;
          final bot = store.botById(store.selectedBotId);
          return ColoredBox(
            color: const Color(0xFF0C0C10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBack && onBack != null)
                  Material(
                    color: const Color(0xFF0C0C10),
                    child: InkWell(
                      onTap: onBack,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(8, 10, 8, 6),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 20, color: _muted),
                            SizedBox(width: 8),
                            Text('Bots', style: TextStyle(color: _muted, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text(
                    bot?.identity.name.isNotEmpty == true ? bot!.identity.name : 'Conversations',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                if (store.loadingPeers)
                  const Expanded(child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))))
                else if (peers.isEmpty)
                  const Expanded(child: Center(child: Text('No conversations', style: TextStyle(color: _muted, fontSize: 13))))
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      itemCount: peers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final c = peers[i];
                        final id = c.id.toString();
                        return UiBotPeerRow(
                          peerName: c.peerName.isNotEmpty ? c.peerName : c.title,
                          peerPic: c.peerPic,
                          channel: c.channelId,
                          lastMsg: c.lastMsgPreview,
                          time: botPeerTimeLabel(c.lastMsgTsMs),
                          aiReplyEnabled: c.aiReplyEnabled,
                          selected: selectedChatId == id,
                          onTap: () => onSelect(id),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
}
