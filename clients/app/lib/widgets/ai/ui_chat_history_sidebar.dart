import 'package:alienai_c35/c/chat/chat_title.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

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
                                : IconButton(
                                    tooltip: 'Refresh chat history',
                                    splashRadius: 16,
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
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          itemCount: store.visibleChats.length + (store.archivedChats.isEmpty ? 0 : 1 + (store.archivedOpen ? store.archivedChats.length : 0)),
                          itemBuilder: (_, i) {
                            final inbox = store.visibleChats;
                            if (i < inbox.length) return _chatTile(inbox[i], archived: false);
                            if (i == inbox.length) {
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
                            return _chatTile(store.archivedChats[i - inbox.length - 1], archived: true);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );

  Widget _chatTile(ChatRow c, {required bool archived}) {
    final selected = c.id == widget.store.activeChatId && !archived;
    final deleting = widget.store.chatDeletingFor(c.id);
    return _ChatTile(
      title: c.title.trim().isEmpty || c.title == 'New chat' ? c.title : chatTitleDisplay(c.title),
      selected: selected,
      pinned: c.pinned,
      muted: archived,
      deleting: deleting,
      onTap: deleting ? null : () => widget.onChatSelect(c.id),
      onMenu: deleting ? null : (ctx, global) => widget.onChatMenu(c.id, global),
    );
  }
}

class _ChatTile extends StatefulWidget {
  const _ChatTile({required this.title, required this.selected, required this.pinned, required this.muted, this.deleting = false, required this.onTap, required this.onMenu});
  final String title;
  final bool selected;
  final bool pinned;
  final bool muted;
  final bool deleting;
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
                    Expanded(child: Text(deleting ? 'Deleting…' : widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: color))),
                    SizedBox(
                      width: 28,
                      height: 28,
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
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
