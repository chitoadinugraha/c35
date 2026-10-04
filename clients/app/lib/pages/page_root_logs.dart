import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/admin_log_stream.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/c/pb/c35/report.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/admin/io_admin_user_pick.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_log_table.dart';
import 'package:alienai_c35/widgets/ui/ui_date_range_chip.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_report_widget.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _border = Color(0xFF27272A);
const _bg = Color(0xFF18181B);
const _bar = Color(0xFF111114);
const _accent = Color(0xFF34D399);

InputDecoration _logFilterDecoration({required String hint, Widget? prefixIcon}) => InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 13),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
    );

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
  List<UiWidget> _reportWidgets = const [];
  var _reportLoading = false;
  String? _reportError;

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

  Future<void> _reload() async {
    final filters = _filters();
    await Future.wait([_stream.refresh(filters), _loadReport(filters)]);
  }

  Future<void> _loadReport(AdminLogFilters filters) async {
    setState(() {
      _reportLoading = true;
      _reportError = null;
    });
    try {
      final widgets = await _api.adminLogReport(
        ownerIid: filters.ownerIid,
        sinceMs: filters.sinceMs,
        untilMs: filters.untilMs,
      );
      if (!mounted) return;
      setState(() => _reportWidgets = widgets);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reportWidgets = const [];
        _reportError = '$e';
      });
    } finally {
      if (mounted) setState(() => _reportLoading = false);
    }
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => unawaited(_reload()));
  }

  Map<int, String> _userNames() {
    if (_user == null) return {};
    return {_user!.identityId.toInt(): _user!.name.isNotEmpty ? _user!.name : _user!.email};
  }

  bool _busy() => _reportLoading || _stream.loading;

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
      body: ListenableBuilder(
        listenable: _stream,
        builder: (context, _) => Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(color: _bar, border: Border(bottom: BorderSide(color: _border))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: _text, fontSize: 13),
                      decoration: _logFilterDecoration(
                        hint: 'Search logs',
                        prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
                      ),
                      onChanged: (_) => _scheduleReload(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IoAdminUserPick(
                    api: _api,
                    value: _user,
                    compactSelected: true,
                    onChanged: (u) {
                      setState(() => _user = u);
                      unawaited(_reload());
                    },
                  ),
                  const SizedBox(width: 8),
                  UiDateRangeChip(range: _range, compact: true, onChanged: (r) {
                    setState(() => _range = r);
                    unawaited(_reload());
                  }),
                  if (_busy()) ...[
                    const SizedBox(width: 10),
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_stream.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(_stream.error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ),
          if (_reportError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(_reportError!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ),
          if (_reportWidgets.isNotEmpty)
            UiReportWidgetView(widgets: _reportWidgets),
          Expanded(
            child: UiAdminLogTable(logs: _stream.logs, userNames: _userNames(), loading: _stream.loading && _stream.logs.isEmpty),
          ),
        ],
        ),
      ),
    );
  }
}
