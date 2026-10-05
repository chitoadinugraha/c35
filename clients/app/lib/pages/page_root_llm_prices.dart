import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

class PageRootLlmPrices extends StatefulWidget {
  const PageRootLlmPrices({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageRootLlmPrices> createState() => _PageRootLlmPricesState();
}

class _PageRootLlmPricesState extends State<PageRootLlmPrices> with SingleTickerProviderStateMixin {
  late final AdminApi _api = AdminApi.chat(widget.chatConn);
  late final TabController _tabs = TabController(length: 3, vsync: this);
  ResAdminLlmCatalogList? _data;
  var _loading = false;
  String? _error;
  var _enabledOnly = true;

  @override
  void initState() {
    super.initState();
    if (Session.instance.isRoot) unawaited(_reload());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.adminLlmCatalogList(enabledOnly: _enabledOnly);
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _data = null;
        _error = '$e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _usd(double v) => v <= 0 ? '—' : '\$${v.toStringAsFixed(v < 0.1 ? 4 : 3)}';

  String _idr(double usd) {
    if (usd <= 0) return '—';
    final fx = AppStore.instance.wallet.fxMicroPerUsd;
    return moneyFmtIdrDetail(moneyUsdToLocal(usd, fx));
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.instance.isRoot) {
      return UiPage(
        title: 'Catalog prices',
        onBack: () => Navigator.pop(context),
        body: const Center(child: Text('Root access required', style: TextStyle(color: adminMuted))),
      );
    }
    final markup = _data?.retailMarkup ?? 1.5;
    return UiPage(
      title: 'Catalog prices',
      onBack: () => Navigator.pop(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Chat: enabled only'),
                  selected: _enabledOnly,
                  onSelected: (v) {
                    setState(() => _enabledOnly = v);
                    unawaited(_reload());
                  },
                ),
                const Spacer(),
                Text('Retail ×${markup.toStringAsFixed(2)}', style: const TextStyle(color: adminMuted, fontSize: 12)),
                const SizedBox(width: 8),
                IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh, size: 20)),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: adminText,
            unselectedLabelColor: adminMuted,
            indicatorColor: adminText,
            tabs: const [
              Tab(text: 'Chat LLM'),
              Tab(text: 'Voice / media'),
              Tab(text: 'Live'),
            ],
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_error != null)
            Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: adminMuted, fontSize: 13))))
          else if (_data == null)
            const Expanded(child: Center(child: Text('No data', style: TextStyle(color: adminMuted))))
          else
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _scrollTable(_ChatPriceTable(rows: _data!.models, usd: _usd, idr: _idr)),
                  _scrollTable(_ServiceRateTable(rows: _data!.services, usd: _usd, idr: _idr)),
                  _scrollTable(_ServiceRateTable(rows: _data!.live, usd: _usd, idr: _idr)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _scrollTable(Widget table) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: table,
        ),
      );
}

class _ChatPriceTable extends StatelessWidget {
  const _ChatPriceTable({required this.rows, required this.usd, required this.idr});

  final List<AdminLlmCatalogRow> rows;
  final String Function(double) usd;
  final String Function(double) idr;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No chat models', style: TextStyle(color: adminMuted));
    const header = TextStyle(color: adminMuted, fontSize: 11, fontWeight: FontWeight.w600);
    const cell = TextStyle(color: adminText, fontSize: 11);
    const sub = TextStyle(color: adminMuted, fontSize: 10);
    return DataTable(
      headingRowHeight: 36,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 48,
      columnSpacing: 12,
      horizontalMargin: 8,
      columns: const [
        DataColumn(label: Text('Model', style: header)),
        DataColumn(label: Text('In (orig)', style: header)),
        DataColumn(label: Text('In (retail)', style: header)),
        DataColumn(label: Text('Cache in (orig)', style: header)),
        DataColumn(label: Text('Cache in (retail)', style: header)),
        DataColumn(label: Text('Out (orig)', style: header)),
        DataColumn(label: Text('Out (retail)', style: header)),
        DataColumn(label: Text('Src', style: header)),
      ],
      rows: [
        for (final r in rows)
          DataRow(
            cells: [
              DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(r.label.isNotEmpty ? r.label : r.id, style: cell), Text('${r.provider} · ${r.id}', style: sub)])),
              DataCell(_rateCell(usd(r.usdInPer1m), '${idr(r.usdInPer1m)}/M', cell, sub)),
              DataCell(_rateCell(usd(r.retailUsdInPer1m), '${idr(r.retailUsdInPer1m)}/M', cell, sub)),
              DataCell(_rateCell(usd(r.usdInCachePer1m), r.usdInCachePer1m > 0 ? '${idr(r.usdInCachePer1m)}/M' : '—', cell, sub)),
              DataCell(_rateCell(usd(r.retailUsdInCachePer1m), r.retailUsdInCachePer1m > 0 ? '${idr(r.retailUsdInCachePer1m)}/M' : '—', cell, sub)),
              DataCell(_rateCell(usd(r.usdOutPer1m), '${idr(r.usdOutPer1m)}/M', cell, sub)),
              DataCell(_rateCell(usd(r.retailUsdOutPer1m), '${idr(r.retailUsdOutPer1m)}/M', cell, sub)),
              DataCell(Text(r.source, style: sub)),
            ],
          ),
      ],
    );
  }
}

class _ServiceRateTable extends StatelessWidget {
  const _ServiceRateTable({required this.rows, required this.usd, required this.idr});

  final List<AdminServiceRateRow> rows;
  final String Function(double) usd;
  final String Function(double) idr;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No rows', style: TextStyle(color: adminMuted));
    const header = TextStyle(color: adminMuted, fontSize: 11, fontWeight: FontWeight.w600);
    const cell = TextStyle(color: adminText, fontSize: 11);
    const sub = TextStyle(color: adminMuted, fontSize: 10);
    return DataTable(
      headingRowHeight: 36,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 56,
      columnSpacing: 12,
      horizontalMargin: 8,
      columns: const [
        DataColumn(label: Text('Item', style: header)),
        DataColumn(label: Text('Unit', style: header)),
        DataColumn(label: Text('Wholesale', style: header)),
        DataColumn(label: Text('Retail', style: header)),
        DataColumn(label: Text('Detail', style: header)),
      ],
      rows: [
        for (final r in rows)
          DataRow(
            cells: [
              DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(r.label.isNotEmpty ? r.label : r.id, style: cell), Text('${r.category} · ${r.id}', style: sub)])),
              DataCell(Text(r.unit, style: sub)),
              DataCell(_rateCell(usd(r.wholesaleUsd), idr(r.wholesaleUsd), cell, sub)),
              DataCell(_rateCell(usd(r.retailUsd), idr(r.retailUsd), cell, sub)),
              DataCell(Text(r.detail, style: sub)),
            ],
          ),
      ],
    );
  }
}

Widget _rateCell(String usdLine, String idrLine, TextStyle cell, TextStyle sub) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(usdLine, style: cell), Text(idrLine, style: sub)],
    );
