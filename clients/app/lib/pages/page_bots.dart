import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_add_menu.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_conversation.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_nav_list.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_peer_list.dart';
import 'package:alienai_c35/widgets/ui/ui_master_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _botsEmptyCollapsed = Text('No bots yet\nTap + to add', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 13));

class PageBots extends StatefulWidget {
  const PageBots({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageBots> createState() => _PageBotsState();
}

class _PageBotsState extends State<PageBots> {
  late final _store = BotStore(conn: widget.chatConn);

  @override
  void initState() {
    super.initState();
    _store.attach();
    _store.refreshBots();
  }

  @override
  void dispose() {
    _store.detach();
    super.dispose();
  }

  Widget _conversation(String? id) {
    if (id == null) return const SizedBox.shrink();
    return UiBotConversation(store: _store, chatId: id);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return UiPage(
      title: 'Bots',
      onBack: () => Navigator.pop(context),
      trailing: UiBotAddMenu(store: _store),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final listEmpty = _store.bots.isEmpty && !_store.loadingBots;
          if (wide) {
            return UiMasterDetail(
              nav: UiBotNavList(store: _store, selectedBotId: _store.selectedBotId, onSelect: _store.botSelect, hideEmptyMessage: listEmpty),
              master: UiBotPeerList(store: _store, selectedChatId: _store.selectedChatId, onSelect: _store.chatSelect),
              selectedId: _store.selectedChatId,
              onSelectedIdChanged: _store.chatSelect,
              detailBuilder: _conversation,
              emptyDetail: const Center(child: Text('Select a conversation', style: TextStyle(color: _muted, fontSize: 13))),
              collapseWhenEmpty: true,
              listEmpty: listEmpty,
              emptyCollapsed: _botsEmptyCollapsed,
            );
          }
          if (_store.selectedChatId != null) {
            return UiMasterDetail(
              master: const SizedBox.shrink(),
              selectedId: _store.selectedChatId,
              onDrillBack: () => _store.chatSelect(null),
              detailBuilder: _conversation,
            );
          }
          if (_store.selectedBotId != null) {
            return UiBotPeerList(
              store: _store,
              selectedChatId: _store.selectedChatId,
              onSelect: _store.chatSelect,
              showBack: true,
              onBack: () => _store.botSelect(null),
            );
          }
          return UiBotNavList(
            store: _store,
            selectedBotId: _store.selectedBotId,
            onSelect: _store.botSelect,
            emptyMessage: 'No bots yet\nTap + to add',
          );
        },
      ),
    );
  }
}
