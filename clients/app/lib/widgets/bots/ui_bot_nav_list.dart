import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:alienai_c35/widgets/bots/io_bot_delete_dialog.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_add_menu.dart';
import 'package:alienai_c35/widgets/ui/ui_alert.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _icon = Color(0xFFA1A1AA);
const _bg = Color(0xFF0C0C10);

class UiBotNavList extends StatefulWidget {
  const UiBotNavList({
    super.key,
    required this.store,
    required this.selectedBotId,
    required this.onSelect,
  });

  final BotStore store;
  final String? selectedBotId;
  final ValueChanged<String?> onSelect;

  @override
  State<UiBotNavList> createState() => _UiBotNavListState();
}

class _UiBotNavListState extends State<UiBotNavList> {
  var _searchOpen = false;
  late final _searchCtrl = TextEditingController();
  late final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => widget.store.searchPut(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() => _searchOpen = false);
  }

  bool _canDelete(IdentityListRow row) => row.identity.ownerIid.toInt() == Session.instance.uid;

  Future<void> _deleteBot(IdentityListRow row) async {
    await botDeleteConfirmShow(context, store: widget.store, bot: row);
  }

  Future<void> _rowMenu(String id, Offset pos) async {
    final row = widget.store.botById(id);
    if (row == null) return;
    final canDelete = _canDelete(row);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      color: const Color(0xFF18181B),
      items: [
        const PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 18, color: _icon),
              SizedBox(width: 10),
              Text('Archive'),
            ],
          ),
        ),
        if (canDelete)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                SizedBox(width: 10),
                Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
              ],
            ),
          ),
      ],
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'archive') await widget.store.archivePut(id, true);
      if (action == 'delete') await _deleteBot(row);
    } catch (e) {
      if (mounted) await uiAlertError(context, e);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (widget.store.search.trim().isNotEmpty) return;
    widget.store.reorderPut(oldIndex, newIndex);
  }

  Widget _header() {
    if (_searchOpen) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F5)),
                decoration: InputDecoration(
                  hintText: 'Search bots',
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 16, color: _muted),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
            uiIconButton(
              tooltip: _searchCtrl.text.isNotEmpty ? 'Clear' : 'Close search',
              icon: const Icon(Icons.close, size: 18, color: _icon),
              onPressed: _searchCtrl.text.isNotEmpty
                  ? () {
                      _searchCtrl.clear();
                      _searchFocus.requestFocus();
                      setState(() {});
                    }
                  : _closeSearch,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text('Bots', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          uiIconButton(tooltip: 'Search', onPressed: _openSearch, icon: const Icon(Icons.search, size: 18, color: _icon)),
          UiBotAddMenu(store: widget.store),
        ],
      ),
    );
  }

  Widget _rowTile(IdentityListRow row, {Key? key}) {
    final id = row.identity.iid.toString();
    final selected = widget.selectedBotId == id;
    final label = row.identity.name.isNotEmpty ? row.identity.name : row.identity.alienId;
    final icons = botChannelIcons(row.identity.metaJson);
    return Material(
      key: key,
      color: selected ? const Color(0xFF18181B) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: selected ? const BorderSide(color: _border) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onSelect(id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiUserAvatar(name: row.identity.name, pic: row.identity.pic, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? const Color(0xFFF4F4F5) : const Color(0xFFA1A1AA),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (icons.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: icons
                            .map(
                              (e) => Icon(e.$1, size: 14, color: e.$2),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<IdentityListRow> bots) {
    final canReorder = widget.store.search.trim().isEmpty;
    if (canReorder) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        buildDefaultDragHandles: false,
        itemCount: bots.length,
        onReorderItem: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex),
        proxyDecorator: (child, _, __) => Material(color: Colors.transparent, elevation: 4, borderRadius: BorderRadius.circular(8), child: child),
        itemBuilder: (context, i) {
          final row = bots[i];
          final id = row.identity.iid.toString();
          return ReorderableDragStartListener(
            key: ValueKey(id),
            index: i,
            child: GestureDetector(
              onSecondaryTapDown: (d) => _rowMenu(id, d.globalPosition),
              onLongPress: () => _rowMenu(id, Offset(MediaQuery.sizeOf(context).width / 2, 200)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _rowTile(row),
              ),
            ),
          );
        },
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: bots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final row = bots[i];
        final id = row.identity.iid.toString();
        return GestureDetector(
          onSecondaryTapDown: (d) => _rowMenu(id, d.globalPosition),
          onLongPress: () => _rowMenu(id, Offset(MediaQuery.sizeOf(context).width / 2, 200)),
          child: _rowTile(row),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final bots = widget.store.filtered;
          return ColoredBox(
            color: _bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                if (widget.store.loadingBots)
                  const Expanded(child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))))
                else if (bots.isEmpty)
                  Expanded(child: widget.store.bots.isEmpty ? UiEmptyState.bots() : UiEmptyState.noMatches('bots'))
                else
                  Expanded(child: _list(bots)),
              ],
            ),
          );
        },
      );
}
