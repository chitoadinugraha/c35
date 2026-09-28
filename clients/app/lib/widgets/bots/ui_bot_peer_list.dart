import 'package:alienai_c35/c/bot/bot_meta.dart';
import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/bots/io_bot_delete_dialog.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_peer_row.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_alert.dart';
import 'package:alienai_c35/widgets/ui/ui_menu_position.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _accent = Color(0xFF34D399);

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

  Future<void> _toggleActive(BuildContext context, String botId, bool value) async {
    try {
      await store.botActivePut(botId, value);
    } catch (_) {}
  }

  bool _canDelete(IdentityListRow row) => row.identity.ownerIid.toInt() == Session.instance.uid;

  List<Widget> _headerActions(
    BuildContext context, {
    required IdentityListRow bot,
    required String botId,
    required bool active,
    required bool activeBusy,
  }) =>
      [
        if (activeBusy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _muted),
            ),
          )
        else
          Switch.adaptive(
            value: active,
            onChanged: (v) => _toggleActive(context, botId, v),
            activeThumbColor: _accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        PopupMenuButton<String>(
          tooltip: 'bots.menuTooltip'.tr(),
          enabled: !activeBusy,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert, color: _muted, size: 20),
          color: const Color(0xFF18181B),
          onSelected: (v) => _headerMenuSelected(context, v, bot, botId),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'new_chat',
              child: Row(
                children: [
                  const Icon(Icons.add_comment_outlined, size: 18, color: Color(0xFFA1A1AA)),
                  const SizedBox(width: 10),
                  Text('bots.menuNewChat'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'configure',
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 18, color: Color(0xFFA1A1AA)),
                  const SizedBox(width: 10),
                  Text('bots.menuConfigure'.tr()),
                ],
              ),
            ),
            if (_canDelete(bot))
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 10),
                    Text('bots.menuDelete'.tr(), style: const TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              ),
          ],
        ),
      ];

  Future<void> _deletePeerChatConfirm(BuildContext context, Chat peer) async {
    final name = peer.peerName.isNotEmpty ? peer.peerName : peer.title;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: Text('bots.chatDeleteTitle'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16)),
        content: Text('bots.chatDeleteMessage'.tr(namedArgs: {'name': name}), style: const TextStyle(color: Color(0xFFA1A1AA))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await store.peerChatDelete(peer.id.toString());
      if (selectedChatId == peer.id.toString()) onSelect(null);
    } catch (e) {
      if (context.mounted) await uiAlertError(context, e);
    }
  }

  Future<void> _peerChatMenu(BuildContext context, Chat peer, Offset pos) async {
    final action = await showMenu<String>(
      context: context,
      position: uiMenuPositionAt(context, pos),
      color: const Color(0xFF18181B),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 10),
              Text('common.delete'.tr(), style: const TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
    );
    if (action == 'delete' && context.mounted) await _deletePeerChatConfirm(context, peer);
  }

  Future<void> _headerMenuSelected(BuildContext context, String? action, IdentityListRow bot, String botId) async {
    if (action == null || !context.mounted) return;
    try {
      switch (action) {
        case 'new_chat':
          await store.botPeerCreateApp();
        case 'configure':
          await store.showEditBot(context, botId);
        case 'delete':
          await botDeleteConfirmShow(context, store: store, bot: bot);
      }
    } catch (e) {
      if (context.mounted) await uiAlertError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final peers = store.peers;
          final bot = store.botById(store.selectedBotId);
          final botId = bot?.identity.iid.toString();
          final activeBusy = botId != null && store.botActiveBusy(botId);
          final active = bot != null ? botActiveFromMetaJson(bot.identity.metaJson) : true;
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
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          bot?.identity.name.isNotEmpty == true ? bot!.identity.name : 'Conversations',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (bot != null && botId != null) ..._headerActions(
                        context,
                        bot: bot,
                        botId: botId,
                        active: active,
                        activeBusy: activeBusy,
                      ),
                    ],
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
                        return GestureDetector(
                          onSecondaryTapDown: (d) => _peerChatMenu(context, c, d.globalPosition),
                          onLongPress: () => _peerChatMenu(context, c, Offset(MediaQuery.sizeOf(context).width / 2, 200)),
                          child: UiBotPeerRow(
                            peerName: c.peerName.isNotEmpty ? c.peerName : c.title,
                            peerPic: c.peerPic,
                            channel: c.channelId,
                            lastMsg: c.lastMsgPreview,
                            time: botPeerTimeLabel(c.lastMsgTsMs),
                            aiReplyEnabled: c.aiReplyEnabled,
                            selected: selectedChatId == id,
                            onTap: () => onSelect(id),
                          ),
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
