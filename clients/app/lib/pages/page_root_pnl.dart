import 'dart:async';

import 'package:alienai_c35/c/admin/admin_pnl_api.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/report.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ui/ui_date_range_chip.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_report_widget.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _warn = Color(0xFFFBBF24);

DateRange dateRangeMtd({DateTime? now}) {
  final cur = now ?? DateTime.now();
  final today = DateTime(cur.year, cur.month, cur.day);
  return (from: DateTime(today.year, today.month, 1), to: cur);
}

class PageRootPnl extends StatefulWidget {
  const PageRootPnl({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageRootPnl> createState() => _PageRootPnlState();
}

class _PageRootPnlState extends State<PageRootPnl> {
  late final AdminPnlApi _api = AdminPnlApi.chat(widget.chatConn);
  late DateRange _range = dateRangeMtd();
  ResAdminPlatformPnl? _pnl;
  var _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Session.instance.isRoot) unawaited(_reload());
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pnl = await _api.platformPnl(
        sinceMs: Int64(_range.from.millisecondsSinceEpoch),
        untilMs: Int64(_range.to.millisecondsSinceEpoch),
      );
      if (!mounted) return;
      setState(() => _pnl = pnl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pnl = null;
        _error = '$e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.instance.isRoot) {
      return UiPage(
        title: 'P&L',
        onBack: () => Navigator.pop(context),
        body: const Center(child: Text('Root access required', style: TextStyle(color: _muted))),
      );
    }
    return UiPage(
      title: 'Platform P&L',
      onBack: () => Navigator.pop(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Revenue, COGS, and vendor breakdown', style: TextStyle(color: _muted, fontSize: 12)),
                ),
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
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
              ),
            )
          else if (_pnl != null && _pnl!.aiCogsDriftPct > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                'AI vendor vs wholesale drift ${_pnl!.aiCogsDriftPct.toStringAsFixed(1)}% — review ai_api vendor lines',
                style: const TextStyle(color: _warn, fontSize: 12),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (_pnl != null) UiReportWidgetView(widgets: _pnl!.widgets),
                if (!_loading && _pnl == null && _error == null)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No P&L data', style: TextStyle(color: _muted, fontSize: 13))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
