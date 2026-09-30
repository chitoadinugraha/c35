import 'dart:async';

import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_add_menu.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_conversation.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_nav_list.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_peer_list.dart';
import 'package:alienai_c35/widgets/ui/ui_master_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _masterBreakpoint = 720.0;

class PageBots extends StatefulWidget {
  const PageBots({super.key, required this.chatConn, this.shellStore});

  final ChatConn chatConn;
  final ChatStore? shellStore;

  @override
  State<PageBots> createState() => _PageBotsState();
}

class _PageBotsState extends State<PageBots> {
  late final _store = BotStore(conn: widget.chatConn, shellStore: widget.shellStore);
  StreamSubscription? _billingBalanceSub;
  StreamSubscription? _billingQuotaSub;
  StreamSubscription? _billingCommissionSub;

  @override
  void initState() {
    super.initState();
    _store.attach();
    _store.refreshBots();
    _billingBalanceSub = widget.chatConn.onBillingBalance.listen(AppStore.instance.billingBalancePush);
    _billingQuotaSub = widget.chatConn.onBillingQuota.listen(AppStore.instance.billingQuotaPush);
    _billingCommissionSub = widget.chatConn.onBillingCommission.listen(AppStore.instance.billingCommissionPush);
  }

  @override
  void dispose() {
    _billingBalanceSub?.cancel();
    _billingQuotaSub?.cancel();
    _billingCommissionSub?.cancel();
    _store.detach();
    super.dispose();
  }

  bool _wide(BuildContext context) => MediaQuery.sizeOf(context).width >= _masterBreakpoint;

  String _botTitle(String? botId) {
    final bot = _store.botById(botId);
    if (bot == null) return 'Bots';
    return bot.identity.name.isNotEmpty ? bot.identity.name : bot.identity.alienId;
  }

  String _chatTitle(String? chatId) {
    final peer = _store.peerById(chatId);
    if (peer == null) return 'Conversation';
    return peer.peerName.isNotEmpty ? peer.peerName : peer.title;
  }

  Widget _conversation(String? id, {required bool showTitleBar}) {
    if (id == null) return const SizedBox.shrink();
    return UiBotConversation(store: _store, chatId: id, showTitleBar: showTitleBar);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final wide = _wide(context);
          final onBotList = _store.selectedBotId == null && _store.selectedChatId == null;
          final onPeerList = _store.selectedBotId != null && _store.selectedChatId == null;
          final onChat = _store.selectedChatId != null;

          final title = wide
              ? 'Bots'
              : onChat
                  ? _chatTitle(_store.selectedChatId)
                  : onPeerList
                      ? _botTitle(_store.selectedBotId)
                      : 'Bots';

          VoidCallback onBack = () => Navigator.pop(context);
          if (!wide) {
            if (onChat) {
              onBack = () => _store.chatSelect(null);
            } else if (onPeerList) {
              onBack = () => _store.botSelect(null);
            }
          }

          final trailing = wide || onBotList
              ? UiBotAddMenu(store: _store)
              : onPeerList
                  ? UiBotPeerHeaderActions(store: _store)
                  : onChat
                      ? UiBotChatHeaderActions(store: _store, chatId: _store.selectedChatId!)
                      : null;

          final listEmpty = _store.bots.isEmpty && !_store.loadingBots;

          Widget body;
          if (wide) {
            body = UiMasterDetail(
              nav: UiBotNavList(store: _store, selectedBotId: _store.selectedBotId, onSelect: _store.botSelect),
              master: UiBotPeerList(store: _store, selectedChatId: _store.selectedChatId, onSelect: _store.chatSelect),
              selectedId: _store.selectedChatId,
              onSelectedIdChanged: _store.chatSelect,
              detailBuilder: (id) => _conversation(id, showTitleBar: true),
              emptyDetail: const Center(child: Text('Select a conversation', style: TextStyle(color: _muted, fontSize: 13))),
              collapseWhenEmpty: true,
              listEmpty: listEmpty,
            );
          } else if (onChat) {
            body = UiMasterDetail(
              master: const SizedBox.shrink(),
              selectedId: _store.selectedChatId,
              onDrillBack: () => _store.chatSelect(null),
              detailBuilder: (id) => _conversation(id, showTitleBar: false),
            );
          } else if (_store.selectedBotId != null) {
            body = UiBotPeerList(
              store: _store,
              selectedChatId: _store.selectedChatId,
              onSelect: _store.chatSelect,
              headerInAppBar: true,
            );
          } else {
            body = UiBotNavList(store: _store, selectedBotId: _store.selectedBotId, onSelect: _store.botSelect);
          }

          return UiPage(
            title: title,
            onBack: onBack,
            onSearch: wide || onBotList ? _store.searchPut : null,
            searchHint: 'Search bots',
            trailing: trailing,
            body: body,
          );
        },
      );
}
