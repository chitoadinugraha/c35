import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/device/device_store.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/widgets/devices/ui_device_add_menu.dart';
import 'package:alienai_c35/widgets/devices/ui_device_detail.dart';
import 'package:alienai_c35/widgets/devices/ui_device_row.dart';
import 'package:alienai_c35/widgets/ui/ui_alert.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:alienai_c35/widgets/ui/ui_master_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_page_bar.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _icon = Color(0xFFA1A1AA);
const _masterBg = Color(0xFF0C0C10);

class PageDevices extends StatefulWidget {
  const PageDevices({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageDevices> createState() => _PageDevicesState();
}

class _PageDevicesState extends State<PageDevices> {
  late final _store = DeviceStore(conn: widget.chatConn);

  @override
  void initState() {
    super.initState();
    _store.refresh();
  }

  String? _deviceName(String? id) {
    final row = _store.rowById(id);
    if (row == null) return null;
    final identity = row.identity;
    return identity.name.isNotEmpty ? identity.name : identity.type;
  }

  Future<String?> _renameAsk(String current) => showDialog<String>(
        context: context,
        builder: (ctx) => _DeviceRenameDialog(initial: current),
      );

  Future<void> _rowMenu(String id, Offset pos) async {
    final row = _store.rowById(id);
    if (row == null) return;
    final pinned = row.isPinned;
    final currentName = row.identity.name.isNotEmpty ? row.identity.name : row.identity.type;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      color: const Color(0xFF18181B),
      items: [
        PopupMenuItem(
          value: pinned ? 'unpin' : 'pin',
          child: Row(
            children: [
              Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: _icon),
              const SizedBox(width: 10),
              Text(pinned ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: _icon),
              SizedBox(width: 10),
              Text('Rename'),
            ],
          ),
        ),
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
      ],
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'pin') await _store.pinPut(id, true);
      if (action == 'unpin') await _store.pinPut(id, false);
      if (action == 'rename') {
        final name = await _renameAsk(currentName);
        if (name == null || !mounted) return;
        await _store.namePut(id, name);
      }
      if (action == 'archive') await _store.archivePut(id, true);
    } catch (e) {
      if (mounted) await uiAlertError(context, e);
    }
  }

  Widget _masterList() => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => ColoredBox(
          color: _masterBg,
          child: _store.loading
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)))
              : _store.filtered.isEmpty
                  ? _store.rows.isEmpty ? UiEmptyState.devices() : UiEmptyState.noMatches('devices')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      itemCount: _store.filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final row = _store.filtered[i];
                        final id = row.identity;
                        final sid = id.iid.toString();
                        final deviceIid = id.iid.toInt();
                        final session = RemoteSession.of(widget.chatConn, deviceIid);
                        return GestureDetector(
                          onSecondaryTapDown: (d) => _rowMenu(sid, d.globalPosition),
                          onLongPress: () => _rowMenu(sid, Offset(MediaQuery.sizeOf(context).width / 2, 200)),
                          child: ListenableBuilder(
                            listenable: Listenable.merge([session.connected, session.status]),
                            builder: (context, _) => UiDeviceRow(
                              name: id.name.isNotEmpty ? id.name : id.type,
                              kind: id.kind,
                              type: id.type,
                              pinned: row.isPinned,
                              clusterOnline: deviceOnlineFromMeta(id.metaJson),
                              webrtcConnected: session.connected.value,
                              webrtcConnecting: session.isLinking,
                              selected: _store.selectedId == sid,
                              onTap: () => _store.select(sid),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );

  Widget _masterBar() {
    final bar = _DeviceMasterBar(onBack: () => Navigator.pop(context), store: _store);
    return ColoredBox(
      color: _masterBg,
      child: uiDesktopWindow ? bar : SafeArea(bottom: false, child: bar),
    );
  }

  Widget _detail(String? id) {
    final row = _store.rowById(id);
    if (row == null) return const SizedBox.shrink();
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return UiDeviceDetail(
      row: row,
      chatConn: widget.chatConn,
      onBack: wide ? null : () => _store.select(null),
      title: wide ? null : (_deviceName(id) ?? 'Device'),
    );
  }

  Widget _emptyDetail() => const Center(child: Text('Select a device', style: TextStyle(color: _muted, fontSize: 13)));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final listEmpty = _store.rows.isEmpty && !_store.loading;
          return UiPage(
            hideBar: true,
            title: 'Devices',
            body: UiMasterDetail(
              master: _masterList(),
              masterBar: _masterBar(),
              selectedId: _store.selectedId,
              onSelectedIdChanged: _store.select,
              onDrillBack: () => _store.select(null),
              detailBuilder: _detail,
              emptyDetail: _emptyDetail(),
              collapseWhenEmpty: true,
              listEmpty: listEmpty,
            ),
          );
        },
      );
}

class _DeviceMasterBar extends StatefulWidget {
  const _DeviceMasterBar({required this.onBack, required this.store});

  final VoidCallback onBack;
  final DeviceStore store;

  @override
  State<_DeviceMasterBar> createState() => _DeviceMasterBarState();
}

class _DeviceMasterBarState extends State<_DeviceMasterBar> {
  static const _muted = Color(0xFF71717A);

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

  Widget _searchBar() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F5)),
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
          uiIconButton(
            tooltip: _searchCtrl.text.isNotEmpty ? 'Clear' : 'Close search',
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFA1A1AA)),
            onPressed: _searchCtrl.text.isNotEmpty
                ? () {
                    _searchCtrl.clear();
                    _searchFocus.requestFocus();
                    setState(() {});
                  }
                : _closeSearch,
          ),
        ],
      );

  Widget? _trailing() {
    if (_searchOpen) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        uiIconButton(tooltip: 'Search', onPressed: _openSearch, icon: const Icon(Icons.search, size: 18, color: Color(0xFFA1A1AA))),
        UiDeviceAddMenu(store: widget.store),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => UiPageBar(
        title: 'Devices',
        onBack: widget.onBack,
        trailing: _trailing(),
        searchWidget: _searchOpen ? _searchBar() : null,
      );
}

class _DeviceRenameDialog extends StatefulWidget {
  const _DeviceRenameDialog({required this.initial});

  final String initial;

  @override
  State<_DeviceRenameDialog> createState() => _DeviceRenameDialogState();
}

class _DeviceRenameDialogState extends State<_DeviceRenameDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Rename device', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Color(0xFFF4F4F5)),
          decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(0xFF71717A))),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: const Text('Save')),
        ],
      );
}
