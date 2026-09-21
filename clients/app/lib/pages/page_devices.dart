import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/device/device_store.dart';
import 'package:alienai_c35/widgets/devices/ui_device_add_menu.dart';
import 'package:alienai_c35/widgets/devices/ui_device_detail.dart';
import 'package:alienai_c35/widgets/devices/ui_device_row.dart';
import 'package:alienai_c35/widgets/ui/ui_master_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class PageDevices extends StatefulWidget {
  const PageDevices({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageDevices> createState() => _PageDevicesState();
}

class _PageDevicesState extends State<PageDevices> {
  late final _store = DeviceStore(conn: widget.chatConn);
  late final _search = TextEditingController(text: _store.search);

  @override
  void initState() {
    super.initState();
    _search.addListener(() => _store.searchPut(_search.text));
    _store.refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _rowMenu(String id, Offset pos) async {
    final row = _store.rowById(id);
    if (row == null) return;
    final pinned = row.isPinned;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      color: const Color(0xFF18181B),
      items: [
        PopupMenuItem(value: pinned ? 'unpin' : 'pin', child: Text(pinned ? 'Unpin' : 'Pin')),
        const PopupMenuItem(value: 'archive', child: Text('Archive')),
      ],
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'pin') await _store.pinPut(id, true);
      if (action == 'unpin') await _store.pinPut(id, false);
      if (action == 'archive') await _store.archivePut(id, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _masterList() => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => ColoredBox(
          color: const Color(0xFF0C0C10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: TextField(
                  controller: _search,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search devices',
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
              if (_store.loading)
                const Expanded(child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))))
              else if (_store.filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _store.rows.isEmpty ? 'No devices yet\nTap + to add' : 'No matching devices',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount: _store.filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final row = _store.filtered[i];
                      final id = row.identity;
                      final sid = id.iid.toString();
                      return GestureDetector(
                        onSecondaryTapDown: (d) => _rowMenu(sid, d.globalPosition),
                        onLongPress: () => _rowMenu(sid, Offset(MediaQuery.sizeOf(context).width / 2, 200)),
                        child: UiDeviceRow(
                          name: id.name.isNotEmpty ? id.name : id.type,
                          kind: id.kind,
                          type: id.type,
                          pinned: row.isPinned,
                          online: deviceOnlineFromMeta(id.metaJson),
                          selected: _store.selectedId == sid,
                          onTap: () => _store.select(sid),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _detail(String? id) {
    final row = _store.rowById(id);
    if (row == null) return const SizedBox.shrink();
    return UiDeviceDetail(row: row);
  }

  Widget _emptyDetail() {
    if (!_store.loading && _store.rows.isEmpty) {
      return const Center(
        child: Text('No devices yet\nTap + to add', style: TextStyle(color: _muted, fontSize: 13), textAlign: TextAlign.center),
      );
    }
    return const Center(child: Text('Select a device', style: TextStyle(color: _muted, fontSize: 13)));
  }

  @override
  Widget build(BuildContext context) => UiPage(
        title: 'Devices',
        onBack: () => Navigator.pop(context),
        trailing: UiDeviceAddMenu(store: _store),
        body: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final listEmpty = _store.rows.isEmpty && !_store.loading;
            return UiMasterDetail(
              master: _masterList(),
              selectedId: _store.selectedId,
              onSelectedIdChanged: _store.select,
              onDrillBack: () => _store.select(null),
              detailBuilder: _detail,
              emptyDetail: _emptyDetail(),
              collapseWhenEmpty: true,
              listEmpty: listEmpty,
              emptyCollapsed: listEmpty ? const Center(child: Text('No devices yet\nTap + to add', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 13))) : null,
            );
          },
        ),
      );
}
