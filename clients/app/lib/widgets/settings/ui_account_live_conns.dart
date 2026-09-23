import 'package:alienai_c35/c/account/account_api.dart';
import 'package:alienai_c35/c/account/invoke_account.dart';
import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UiAccountLiveConns extends StatefulWidget {
  const UiAccountLiveConns({super.key, required this.account, this.onConnsChanged});
  final AccountApi account;
  final VoidCallback? onConnsChanged;

  @override
  State<UiAccountLiveConns> createState() => UiAccountLiveConnsState();
}

class UiAccountLiveConnsState extends State<UiAccountLiveConns> {
  var _loading = true;
  var _busy = false;
  String? _error;
  List<AccountLiveConn> _conns = [];
  String _selfDv = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get hasOtherDevices => _conns.any((c) => c.dv != _selfDv);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _selfDv = await deviceInstallId();
      final list = await widget.account.liveConnsList();
      if (!mounted) return;
      setState(() {
        _conns = list;
        _loading = false;
      });
      widget.onConnsChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiFriendlyError(e, fallback: 'Could not load sessions.');
      });
    }
  }

  Future<void> _rename(AccountLiveConn c) async {
    final next = await showDialog<String>(context: context, builder: (ctx) => _DeviceRenameDialog(initial: c.label));
    if (next == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.account.deviceLabelPut(dv: c.dv, labelUser: next);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = 'settings.renameFailed'.tr());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(AccountLiveConn c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: Text('settings.revokeDeviceTitle'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))),
        content: Text('settings.revokeDeviceBody'.tr(namedArgs: {'name': _connTitle(c)}), style: const TextStyle(color: Color(0xFFA1A1AA))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white), child: Text('settings.revoke'.tr())),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.account.liveConnRevoke(dv: c.dv);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e, fallback: 'Could not revoke session.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> revokeOthers() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: Text('settings.revokeOthersTitle'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))),
        content: Text('settings.revokeOthersBody'.tr(), style: const TextStyle(color: Color(0xFFA1A1AA))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white), child: Text('settings.revokeOthers'.tr())),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.account.liveConnRevokeOthers(selfDv: _selfDv);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e, fallback: 'Could not revoke sessions.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _connTitle(AccountLiveConn c) => c.label.isEmpty ? 'settings.device'.tr() : c.label;
  String _connSubtitle(AccountLiveConn c) => c.osName.isNotEmpty ? c.osName : _platformLabel(c.platform);
  String _platformLabel(int platform) => switch (platform) { 1 => 'Android / iOS', 2 => 'macOS', 3 => 'Windows / Linux', 4 => 'Web', _ => 'settings.device'.tr() };

  @override
  Widget build(BuildContext context) {
    if (_loading && _conns.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: UILoading());
    if (_error != null && _conns.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))));
    if (_conns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Icon(Icons.wifi_off_outlined, color: Color(0xFF71717A), size: 32),
          const SizedBox(height: 8),
          Text('settings.noActiveConnections'.tr(), style: const TextStyle(color: Color(0xFFE4E4E7), fontWeight: FontWeight.w600)),
          Text('settings.noActiveConnectionsSubtitle'.tr(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
        ]),
      );
    }
    return Stack(children: [
      RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF34D399),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
          if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
          Text('settings.activeConnectionsSubtitle'.tr(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
          const SizedBox(height: 12),
          for (final c in _conns) _ConnTile(conn: c, isSelf: c.dv == _selfDv, title: _connTitle(c), subtitle: _connSubtitle(c), onRename: _busy ? null : () => _rename(c), onRevoke: _busy || c.dv == _selfDv ? null : () => _revoke(c)),
        ]),
      ),
      if (_busy) const Positioned(top: 8, right: 16, child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF34D399)))),
    ]);
  }
}

class _ConnTile extends StatelessWidget {
  const _ConnTile({required this.conn, required this.isSelf, required this.title, required this.subtitle, this.onRename, this.onRevoke});
  final AccountLiveConn conn;
  final bool isSelf;
  final String title;
  final String subtitle;
  final VoidCallback? onRename;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(color: const Color(0xFF111114), borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelf ? const Color(0xFF1F3D32) : const Color(0xFF27272A))),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: isSelf ? const Color(0xFF123528) : const Color(0xFF1A1A1F), borderRadius: BorderRadius.circular(12)), child: Icon(_platformIcon(conn.platform), color: isSelf ? const Color(0xFF34D399) : const Color(0xFF71717A), size: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF4F4F5), fontWeight: FontWeight.w600, fontSize: 15))),
                if (isSelf) const _ThisDeviceBadge(),
              ]),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
            ]),
          ),
          if (onRename != null) uiIconButton(tooltip: 'settings.rename'.tr(), icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF71717A)), onPressed: onRename),
          if (onRevoke != null) TextButton(onPressed: onRevoke, style: TextButton.styleFrom(foregroundColor: const Color(0xFFF87171), padding: const EdgeInsets.symmetric(horizontal: 10)), child: Text('settings.revoke'.tr())),
        ]),
      );

  IconData _platformIcon(int platform) => switch (platform) { 1 => Icons.phone_android, 2 => Icons.laptop_mac, 3 => Icons.desktop_windows, 4 => Icons.language, _ => Icons.devices_other };
}

class _ThisDeviceBadge extends StatelessWidget {
  const _ThisDeviceBadge();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF123528), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.35))),
        child: Text('settings.thisDevice'.tr(), style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: Text('settings.deviceName'.tr(), style: const TextStyle(color: Color(0xFFF4F4F5))),
        content: TextField(controller: _ctrl, autofocus: true, style: const TextStyle(color: Color(0xFFF4F4F5)), decoration: InputDecoration(labelText: 'settings.deviceName'.tr())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr())),
          FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black), child: Text('common.save'.tr())),
        ],
      );
}

class PageAccountLiveConns extends StatefulWidget {
  const PageAccountLiveConns({super.key, required this.account});
  final AccountApi account;
  @override
  State<PageAccountLiveConns> createState() => _PageAccountLiveConnsState();
}

class _PageAccountLiveConnsState extends State<PageAccountLiveConns> {
  final _listKey = GlobalKey<UiAccountLiveConnsState>();

  @override
  Widget build(BuildContext context) => UiPage(
        title: 'settings.activeConnections'.tr(),
        onBack: () => Navigator.pop(context),
        trailing: _listKey.currentState?.hasOtherDevices == true
            ? TextButton(onPressed: _listKey.currentState?.revokeOthers, child: Text('settings.revokeOthers'.tr(), style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)))
            : null,
        body: UiAccountLiveConns(key: _listKey, account: widget.account, onConnsChanged: () => setState(() {})),
      );
}
