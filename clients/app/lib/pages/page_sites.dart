import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/widgets/sites/ui_site_detail.dart';
import 'package:alienai_c35/widgets/sites/ui_site_row.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:alienai_c35/widgets/ui/ui_master_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_page_bar.dart';
import 'package:alienai_c35/widgets/ui/ui_search_toggle.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'dart:async';

import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _masterBg = Color(0xFF0C0C10);

class PageSites extends StatefulWidget {
  const PageSites({super.key, required this.chatConn, this.initialSiteIid, this.initialTabRoute});

  final ChatConn chatConn;
  final String? initialSiteIid;
  final String? initialTabRoute;

  @override
  State<PageSites> createState() => _PageSitesState();
}

class _PageSitesState extends State<PageSites> {
  late final _store = SiteStore(conn: widget.chatConn);

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    await _store.refresh();
    final siteIid = widget.initialSiteIid?.trim();
    if (siteIid != null && siteIid.isNotEmpty) _store.select(siteIid);
  }

  String? _siteName(String? id) {
    final row = _store.rowById(id);
    if (row == null) return null;
    return row.name.isNotEmpty ? row.name : row.alienId;
  }

  Widget _masterList() => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => ColoredBox(
          color: _masterBg,
          child: _store.loading
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)))
              : _store.filtered.isEmpty
                  ? _store.rows.isEmpty ? UiEmptyState.sites() : UiEmptyState.noMatches('sites')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      itemCount: _store.filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final row = _store.filtered[i];
                        final sid = row.siteIid.toString();
                        return UiSiteRow(row: row, selected: _store.selectedId == sid, onTap: () => _store.select(sid));
                      },
                    ),
        ),
      );

  Widget _masterBar() {
    final bar = _SiteMasterBar(onBack: () => Navigator.pop(context), store: _store);
    return ColoredBox(color: _masterBg, child: uiDesktopWindow ? bar : SafeArea(bottom: false, child: bar));
  }

  Widget _detail(String? id) {
    final row = _store.rowById(id);
    if (row == null) return const SizedBox.shrink();
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return UiSiteDetail(
      row: row,
      api: _store.api,
      onBack: wide ? null : () => _store.select(null),
      title: wide ? null : (_siteName(id) ?? 'Site'),
      initialTabRoute: widget.initialTabRoute,
    );
  }

  Widget _emptyDetail() => const Center(child: Text('Select a site', style: TextStyle(color: _muted, fontSize: 13)));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final listEmpty = _store.rows.isEmpty && !_store.loading;
          return UiPage(
            hideBar: true,
            title: 'Sites',
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

class _SiteMasterBar extends StatelessWidget {
  const _SiteMasterBar({required this.onBack, required this.store});

  final VoidCallback onBack;
  final SiteStore store;

  @override
  Widget build(BuildContext context) => UiPageBar(
        onBack: onBack,
        title: 'Sites',
        trailing: UiSearchToggle(onSearch: store.searchPut),
      );
}
