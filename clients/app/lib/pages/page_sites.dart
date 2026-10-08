import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/site/site_guest_order_bus.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/sites/ui_site_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// Single-site admin (Preview + Edit shell). Site picking is `uiSitesPickerOpen`.
class PageSites extends StatefulWidget {
  const PageSites({
    super.key,
    required this.chatConn,
    required this.siteIid,
    this.initialTabRoute,
  });

  final ChatConn chatConn;
  final String siteIid;
  final String? initialTabRoute;

  @override
  State<PageSites> createState() => _PageSitesState();
}

class _PageSitesState extends State<PageSites> {
  late final _store = SiteStore(conn: widget.chatConn);
  SiteGuestOrderEvent? _lastGuestOrderSnack;

  @override
  void initState() {
    super.initState();
    siteGuestOrderBus.addListener(_onGuestOrderPush);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_boot());
    });
  }

  @override
  void dispose() {
    siteGuestOrderBus.removeListener(_onGuestOrderPush);
    super.dispose();
  }

  void _onGuestOrderPush() {
    final e = siteGuestOrderBus.last;
    if (e == null || e == _lastGuestOrderSnack) return;
    final active = (_store.selectedId ?? widget.siteIid.trim());
    if (active.isEmpty || e.siteIid.toString() != active) return;
    _lastGuestOrderSnack = e;
    if (!mounted) return;
    final label = e.subjectName.isNotEmpty ? e.subjectName : 'Tamu';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesanan baru #${e.txId} dari $label · ${moneyFmtIdr(e.total)}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _boot() async {
    await _store.refresh();
    final siteIid = widget.siteIid.trim();
    if (siteIid.isNotEmpty) _store.select(siteIid);
  }

  String? _siteName(String? id) {
    final row = _store.rowById(id);
    if (row == null) return null;
    return row.name.isNotEmpty ? row.name : row.alienId;
  }

  Widget _body() {
    final id = _store.selectedId ?? widget.siteIid.trim();
    if (_store.loading && _store.rowById(id) == null) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final row = _store.rowById(id);
    if (id.isEmpty || row == null) {
      return UiEmptyState(
        icon: Icons.language_outlined,
        title: 'Site not found',
        subtitle: 'It may have been removed or you may not have access.',
        actionHint: 'Go back and pick another site',
      );
    }
    return UiSiteDetail(
      row: row,
      api: _store.api,
      onBack: () => Navigator.pop(context),
      title: _siteName(id) ?? 'Site',
      initialTabRoute: widget.initialTabRoute,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => UiPage(hideBar: true, title: 'Sites', body: _body()),
      );
}
