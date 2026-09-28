import 'dart:async';

import 'package:alienai_c35/c/bot/bot_meta.dart';
import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/bots/io_bot_delete_dialog.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_peer_row.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_alert.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_menu.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _accent = Color(0xFF34D399);
const _refreshColor = Color(0xFF34D399);

bool _botCanDelete(IdentityListRow row) => row.identity.ownerIid.toInt() == Session.instance.uid;

class UiBotPeerHeaderActions extends StatelessWidget {
  const UiBotPeerHeaderActions({super.key, required this.store});

  final BotStore store;

  Future<void> _toggleActive(BuildContext context, String botId, bool value) async {
    try {
      await store.botActivePut(botId, value);
    } catch (_) {}
  }

  Future<void> _headerMenuSelected(BuildContext context, String action, IdentityListRow bot, String botId) async {
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

  Future<void> _openHeaderMenu(BuildContext context, RenderBox anchor, IdentityListRow bot, String botId) async {
    final action = await uiBotMenuShowBelow<String>(
      context: context,
      anchor: anchor,
      items: [
        uiBotMenuItem(value: 'new_chat', icon: Icons.add_comment_outlined, label: 'bots.menuNewChat'.tr()),
        uiBotMenuItem(value: 'configure', icon: Icons.settings_outlined, label: 'bots.menuConfigure'.tr()),
        if (_botCanDelete(bot)) uiBotMenuItem(value: 'delete', icon: Icons.delete_outline, label: 'bots.menuDelete'.tr(), destructive: true),
      ],
    );
    if (action == null || !context.mounted) return;
    await _headerMenuSelected(context, action, bot, botId);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final bot = store.botById(store.selectedBotId);
          final botId = bot?.identity.iid.toString();
          if (bot == null || botId == null) return const SizedBox.shrink();
          final activeBusy = store.botActiveBusy(botId);
          final active = botActiveFromMetaJson(bot.identity.metaJson);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activeBusy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
                )
              else
                Switch.adaptive(
                  value: active,
                  onChanged: (v) => _toggleActive(context, botId, v),
                  activeThumbColor: _accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              Builder(
                builder: (btnCtx) => uiIconButton(
                  tooltip: 'bots.menuTooltip'.tr(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.more_vert, color: _muted, size: 20),
                  onPressed: activeBusy
                      ? null
                      : () {
                          final box = btnCtx.findRenderObject() as RenderBox?;
                          if (box == null || !box.hasSize) return;
                          unawaited(_openHeaderMenu(btnCtx, box, bot, botId));
                        },
                ),
              ),
            ],
          );
        },
      );
}

class UiBotPeerList extends StatelessWidget {
  const UiBotPeerList({
    super.key,
    required this.store,
    required this.selectedChatId,
    required this.onSelect,
    this.headerInAppBar = false,
  });

  final BotStore store;
  final String? selectedChatId;
  final ValueChanged<String?> onSelect;
  final bool headerInAppBar;

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
    final action = await uiBotMenuShowAt<String>(
      context: context,
      global: pos,
      items: [
        uiBotMenuItem(value: 'delete', icon: Icons.delete_outline, label: 'common.delete'.tr(), destructive: true),
      ],
    );
    if (action == 'delete' && context.mounted) await _deletePeerChatConfirm(context, peer);
  }

  Widget _scrollableEmpty(BuildContext context, Widget child) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      );

  Widget _peerList(BuildContext context, List<Chat> peers) => ListView.separated(
        padding: EdgeInsets.fromLTRB(8, headerInAppBar ? 8 : 0, 8, 8),
        physics: const AlwaysScrollableScrollPhysics(),
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
              channelPlatform: store.peerChannelPlatform(c),
              lastMsg: c.lastMsgPreview,
              time: botPeerTimeLabel(c.lastMsgTsMs),
              aiReplyEnabled: c.aiReplyEnabled,
              selected: selectedChatId == id,
              onTap: () => onSelect(id),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final peers = store.peers;
          final bot = store.botById(store.selectedBotId);
          final botId = bot?.identity.iid.toString();
          Widget listBody;
          if (store.loadingPeers && peers.isEmpty) {
            listBody = const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
          } else if (peers.isEmpty) {
            listBody = _scrollableEmpty(context, const Text('No conversations', style: TextStyle(color: _muted, fontSize: 13)));
          } else {
            listBody = _peerList(context, peers);
          }

          return ColoredBox(
            color: const Color(0xFF0C0C10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!headerInAppBar)
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
                        if (bot != null && botId != null) UiBotPeerHeaderActions(store: store),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: store.refreshPeers,
                    color: _refreshColor,
                    child: listBody,
                  ),
                ),
              ],
            ),
          );
        },
      );
}
