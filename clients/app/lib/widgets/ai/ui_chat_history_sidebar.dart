import 'package:alienai_c35/c/chat/chat_title.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

String _formatRelativeTime(int tsMs) {
  if (tsMs <= 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(tsMs);
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.isNegative || diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}';
}

class UiChatHistorySidebar extends StatefulWidget {
  const UiChatHistorySidebar({
    super.key,
    required this.store,
    required this.onNewChat,
    required this.onChatSelect,
    required this.onChatMenu,
    this.onRefresh,
  });

  final ChatStore store;
  final VoidCallback onNewChat;
  final ValueChanged<int> onChatSelect;
  final void Function(int id, Offset pos) onChatMenu;
  final Future<void> Function()? onRefresh;

  @override
  State<UiChatHistorySidebar> createState() => _UiChatHistorySidebarState();
}

class _UiChatHistorySidebarState extends State<UiChatHistorySidebar> {
  late final _search = TextEditingController(text: widget.store.search);
  var _refreshing = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => widget.store.searchPut(_search.text));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing || widget.onRefresh == null) return;
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final store = widget.store;
          return ColoredBox(
            color: const Color(0xFF0C0C10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 4, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF71717A)),
                            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                            suffixIcon: _refreshing
                                ? const Padding(
                                    padding: EdgeInsets.all(9),
                                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF71717A))),
                                  )
                                : uiIconButton(
                                    tooltip: 'Refresh chat history',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF71717A)),
                                    onPressed: _refresh,
                                  ),
                            suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFF18181B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      uiIconButton(tooltip: 'New chat', onPressed: widget.onNewChat, icon: const Icon(Icons.add_rounded, size: 20, color: Color(0xFFE4E4E7))),
                    ],
                  ),
                ),
                Expanded(
                  child: store.visibleChats.isEmpty && store.archivedChats.isEmpty
                      ? Center(child: Text(store.chats.isEmpty ? 'No chats yet' : 'No matching chats', style: const TextStyle(color: Color(0xFF52525B), fontSize: 13)))
                      : _buildSidebarList(store),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildSidebarList(ChatStore store) {
    final items = _buildItems(store);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is _SidebarHeaderItem) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Text(
              item.title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF71717A), letterSpacing: 0.3),
            ),
          );
        }
        if (item is _SidebarArchivedToggleItem) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => store.archivedOpenPut(!store.archivedOpen),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(store.archivedOpen ? Icons.expand_more : Icons.chevron_right, size: 16, color: const Color(0xFF71717A)),
                    const SizedBox(width: 4),
                    const Expanded(child: Text('Archived', style: TextStyle(fontSize: 12, color: Color(0xFF71717A), fontWeight: FontWeight.w500))),
                    Text('${store.archivedChats.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF52525B))),
                  ],
                ),
              ),
            ),
          );
        }
        if (item is _SidebarChatItem) {
          return _chatTile(item.chat, archived: item.archived, subtitle: item.snippet);
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<_SidebarItem> _buildItems(ChatStore store) {
    final query = store.search.trim();
    if (query.isNotEmpty) {
      final items = <_SidebarItem>[];
      for (final c in store.visibleChats) {
        final snippet = store.searchSnippetFor(c.id, query);
        items.add(_SidebarChatItem(c, archived: false, snippet: snippet));
      }
      for (final c in store.archivedChats) {
        final snippet = store.searchSnippetFor(c.id, query);
        items.add(_SidebarChatItem(c, archived: true, snippet: snippet));
      }
      return items;
    }

    final items = <_SidebarItem>[];
    final pinned = <ChatRow>[];
    final today = <ChatRow>[];
    final yesterday = <ChatRow>[];
    final prev7Days = <ChatRow>[];
    final prev30Days = <ChatRow>[];
    final older = <ChatRow>[];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = todayStart.subtract(const Duration(days: 30));

    for (final c in store.visibleChats) {
      if (c.pinned) {
        pinned.add(c);
        continue;
      }
      if (c.lastMsgAt <= 0) {
        older.add(c);
        continue;
      }
      final dt = DateTime.fromMillisecondsSinceEpoch(c.lastMsgAt);
      if (dt.isAfter(todayStart)) {
        today.add(c);
      } else if (dt.isAfter(yesterdayStart)) {
        yesterday.add(c);
      } else if (dt.isAfter(weekStart)) {
        prev7Days.add(c);
      } else if (dt.isAfter(monthStart)) {
        prev30Days.add(c);
      } else {
        older.add(c);
      }
    }

    void addSection(String title, List<ChatRow> list) {
      if (list.isEmpty) return;
      items.add(_SidebarHeaderItem(title));
      for (final c in list) {
        items.add(_SidebarChatItem(c, archived: false));
      }
    }

    addSection('Pinned', pinned);
    addSection('Today', today);
    addSection('Yesterday', yesterday);
    addSection('Previous 7 Days', prev7Days);
    addSection('Previous 30 Days', prev30Days);
    addSection('Older', older);

    if (store.archivedChats.isNotEmpty) {
      items.add(_SidebarArchivedToggleItem());
      if (store.archivedOpen) {
        for (final c in store.archivedChats) {
          items.add(_SidebarChatItem(c, archived: true));
        }
      }
    }

    return items;
  }

  Widget _chatTile(ChatRow c, {required bool archived, String subtitle = ''}) {
    final selected = c.id == widget.store.activeChatId && !archived;
    final deleting = widget.store.chatDeletingFor(c.id);
    final isStreaming = widget.store.promptBusyFor(c.id);
    return _ChatTile(
      title: c.title.trim().isEmpty || c.title == 'New chat' ? c.title : chatTitleDisplay(c.title),
      subtitle: subtitle,
      selected: selected,
      pinned: c.pinned,
      muted: archived,
      deleting: deleting,
      isStreaming: isStreaming,
      status: c.lastMsgStatus,
      unread: c.unreadStatus,
      lastMsgAt: c.lastMsgAt,
      onTap: deleting ? null : () => widget.onChatSelect(c.id),
      onMenu: deleting ? null : (ctx, global) => widget.onChatMenu(c.id, global),
    );
  }
}

sealed class _SidebarItem {}

class _SidebarHeaderItem extends _SidebarItem {
  _SidebarHeaderItem(this.title);
  final String title;
}

class _SidebarChatItem extends _SidebarItem {
  _SidebarChatItem(this.chat, {required this.archived, this.snippet = ''});
  final ChatRow chat;
  final bool archived;
  final String snippet;
}

class _SidebarArchivedToggleItem extends _SidebarItem {}

class _ChatTile extends StatefulWidget {
  const _ChatTile({
    required this.title,
    required this.selected,
    required this.pinned,
    required this.muted,
    this.deleting = false,
    this.isStreaming = false,
    this.status = 'done',
    this.unread = false,
    this.lastMsgAt = 0,
    this.subtitle = '',
    required this.onTap,
    required this.onMenu,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool pinned;
  final bool muted;
  final bool deleting;
  final bool isStreaming;
  final String status;
  final bool unread;
  final int lastMsgAt;
  final VoidCallback? onTap;
  final void Function(BuildContext context, Offset global)? onMenu;

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final deleting = widget.deleting;
    final color = deleting
        ? const Color(0xFFFCA5A5)
        : widget.selected
            ? const Color(0xFFF4F4F5)
            : (widget.muted ? const Color(0xFF71717A) : const Color(0xFFA1A1AA));
    final bg = deleting
        ? const Color(0xFF3B1218)
        : widget.selected
            ? const Color(0xFF18181B)
            : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: deleting ? const BorderSide(color: Color(0xFF7F1D1D)) : BorderSide.none,
          ),
          child: InkWell(
              borderRadius: BorderRadius.circular(8),
              hoverColor: deleting ? const Color(0xFF45161D) : const Color(0xFF1C1C22),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              onTap: widget.onTap,
              onSecondaryTapUp: widget.onMenu == null ? null : (d) => widget.onMenu!(context, d.globalPosition),
              onLongPress: widget.onMenu == null
                  ? null
                  : () {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null || !box.hasSize) return;
                      widget.onMenu!(context, box.localToGlobal(Offset(box.size.width - 8, box.size.height / 2)));
                    },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                child: Row(
                  children: [
                    if (widget.pinned && !deleting) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.push_pin, size: 12, color: Color(0xFFA1A1AA))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(deleting ? 'Deleting…' : widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: color)),
                          if (widget.subtitle.isNotEmpty && !deleting)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!deleting) ...[
                      if (widget.isStreaming)
                        const Padding(
                          padding: EdgeInsets.only(left: 4, right: 2),
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF60A5FA)),
                          ),
                        )
                      else if (widget.unread)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 2),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.status == 'error' ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (widget.lastMsgAt > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 2),
                          child: Text(
                            _formatRelativeTime(widget.lastMsgAt),
                            style: const TextStyle(fontSize: 10, color: Color(0xFF52525B)),
                          ),
                        ),
                    ],
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: deleting
                          ? const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFFFCA5A5))))
                          : Opacity(
                              opacity: _hover ? 1 : 0,
                              child: IgnorePointer(
                                ignoring: !_hover,
                                child: uiIconButton(
                                  tooltip: 'Chat actions',
                                  onPressed: () {
                                    final box = context.findRenderObject() as RenderBox?;
                                    if (box == null || !box.hasSize) return;
                                    widget.onMenu!(context, box.localToGlobal(Offset(box.size.width - 8, box.size.height / 2)));
                                  },
                                  icon: const Icon(Icons.more_horiz, size: 16, color: Color(0xFFA1A1AA)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }
}
