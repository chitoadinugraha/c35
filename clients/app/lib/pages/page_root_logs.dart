import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/admin_log_stream.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/admin/io_admin_user_pick.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_log_table.dart';
import 'package:alienai_c35/widgets/ui/ui_date_range_chip.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _border = Color(0xFF27272A);
const _bg = Color(0xFF18181B);

class PageRootLogs extends StatefulWidget {
  const PageRootLogs({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageRootLogs> createState() => _PageRootLogsState();
}

class _PageRootLogsState extends State<PageRootLogs> {
  late final AdminApi _api = AdminApi.chat(widget.chatConn);
  late final AdminLogStream _stream = AdminLogStream(_api);
  final _searchCtrl = TextEditingController();
  AdminUserHit? _user;
  late DateRange _range = dateRangePreset(DateRangePreset.today);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (Session.instance.isRoot) unawaited(_reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _stream.dispose();
    super.dispose();
  }

  AdminLogFilters _filters() => AdminLogFilters(
        ownerIid: _user?.identityId.toInt(),
        sinceMs: Int64(_range.from.millisecondsSinceEpoch),
        untilMs: Int64(_range.to.millisecondsSinceEpoch),
        text: _searchCtrl.text,
      );

  Future<void> _reload() => _stream.refresh(_filters());

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => unawaited(_reload()));
  }

  Map<int, String> _userNames() {
    if (_user == null) return {};
    return {_user!.identityId.toInt(): _user!.name.isNotEmpty ? _user!.name : _user!.email};
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.instance.isRoot) {
      return UiPage(
        title: 'Logs',
        onBack: () => Navigator.pop(context),
        body: const Center(child: Text('Root access required', style: TextStyle(color: _muted))),
      );
    }
    return UiPage(
      title: 'Logs',
      onBack: () => Navigator.pop(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: _text, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search logs',
                      hintStyle: const TextStyle(color: _muted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                    ),
                    onChanged: (_) => _scheduleReload(),
                  ),
                ),
                const SizedBox(width: 8),
                IoAdminUserPick(
                  api: _api,
                  value: _user,
                  onChanged: (u) {
                    setState(() => _user = u);
                    unawaited(_reload());
                  },
                ),
                const SizedBox(width: 8),
                UiDateRangeChip(
                  range: _range,
                  onChanged: (r) {
                    setState(() => _range = r);
                    unawaited(_reload());
                  },
                ),
              ],
            ),
          ),
          if (_stream.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_stream.error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ),
          Expanded(
            child: ListenableBuilder(
              listenable: _stream,
              builder: (context, _) => UiAdminLogTable(logs: _stream.logs, userNames: _userNames(), loading: _stream.loading),
            ),
          ),
        ],
      ),
    );
  }
}
