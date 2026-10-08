import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/site/site_commerce_cache.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/widgets/sites/tx/ui_site_tx_editor.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// Full-screen staff POS (id.alienai transaksi editor). Not the Sites Orders tab.
Future<void> sitePosOpen({
  required BuildContext context,
  required ChatConn chatConn,
  required String siteIid,
  Int64? txId,
}) async {
  try {
    await chatConn.reconnect();
  } catch (_) {}
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => PageSitePos(chatConn: chatConn, siteIid: siteIid, txId: txId),
    ),
  );
}

class PageSitePos extends StatefulWidget {
  const PageSitePos({
    super.key,
    required this.chatConn,
    required this.siteIid,
    this.txId,
  });

  final ChatConn chatConn;
  final String siteIid;
  final Int64? txId;

  @override
  State<PageSitePos> createState() => _PageSitePosState();
}

class _PageSitePosState extends State<PageSitePos> {
  late final _store = SiteStore(conn: widget.chatConn);
  var _booting = true;
  String? _blockReason;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_boot());
    });
  }

  Future<void> _boot() async {
    setState(() {
      _booting = true;
      _blockReason = null;
    });
    try {
      final siteIidStr = widget.siteIid.trim();
      await _store.ensureCacheRestored();
      if (_store.rowById(siteIidStr) == null) {
        await _store.refresh();
      } else {
        unawaited(_store.refresh());
      }
      if (siteIidStr.isNotEmpty) _store.select(siteIidStr);
      final row = _store.rowById(siteIidStr);
      if (row == null) {
        _blockReason = 'not_found';
        return;
      }
      final siteIid = row.siteIid.toInt();
      var commerce = true;
      try {
        final config = await _store.api.configGet(siteIid);
        commerce = siteCapabilitiesParse(config.capabilitiesJson)['commerce'] ?? true;
      } catch (_) {
        final cached = await siteCapabilitiesCacheRestore(Session.instance.uid, siteIid);
        if (cached != null) {
          commerce = siteCapabilitiesParse(cached)['commerce'] ?? true;
        } else {
          final products = await siteProductCacheRestore(Session.instance.uid, siteIid);
          if (products.isEmpty) {
            _blockReason = 'offline';
            return;
          }
        }
      }
      if (!commerce) _blockReason = 'commerce_disabled';
    } catch (_) {
      _blockReason = 'load_failed';
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  Widget _body() {
    if (_booting) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final id = widget.siteIid.trim();
    final row = _store.rowById(id);
    if (_blockReason == 'commerce_disabled') {
      return UiEmptyState(
        icon: Icons.point_of_sale_outlined,
        title: 'Commerce disabled',
        subtitle: 'Turn on Commerce in site settings to use POS.',
        actionHint: 'Go back',
      );
    }
    if (_blockReason == 'offline') {
      return UiEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Offline',
        subtitle: 'Connect once while online to cache products for POS, then you can sell offline.',
        actionHint: 'Go back',
      );
    }
    if (_blockReason != null || row == null) {
      return UiEmptyState(
        icon: Icons.language_outlined,
        title: 'Site not found',
        subtitle: 'It may have been removed or you may not have access.',
        actionHint: 'Go back',
      );
    }
    return UiSiteTxEditor(
      siteIid: row.siteIid.toInt(),
      api: _store.api,
      site: row,
      txId: widget.txId,
      posEntry: true,
      onSaved: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => UiPage(hideBar: true, title: 'POS', body: _body()),
      );
}
