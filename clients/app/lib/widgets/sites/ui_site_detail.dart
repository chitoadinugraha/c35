import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/collection_def.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_table.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteDetail extends StatefulWidget {
  const UiSiteDetail({super.key, required this.row, required this.api, this.onBack, this.title, this.initialTabRoute});

  final SiteRow row;
  final SiteApi api;
  final VoidCallback? onBack;
  final String? title;
  final String? initialTabRoute;

  @override
  State<UiSiteDetail> createState() => _UiSiteDetailState();
}

class _UiSiteDetailState extends State<UiSiteDetail> {
  late final _siteIid = widget.row.siteIid.toInt();
  var _tableSearch = '';
  var _collectionSearchOpen = false;
  late final _searchCtrl = TextEditingController();
  late final _searchFocus = FocusNode();
  List<TableDef> _defs = const [];
  var _defsLoading = true;
  var _publishing = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _tableSearch = _searchCtrl.text));
    _loadDefs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadDefs() async {
    setState(() => _defsLoading = true);
    try {
      _defs = await widget.api.collectionDefs(siteIid: _siteIid);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _defsLoading = false);
    }
  }

  String get _guestUrl {
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    final slug = widget.row.alienId.isNotEmpty ? widget.row.alienId : widget.row.siteIid.toString();
    return '$base/$slug?draft=1';
  }

  Future<void> _openPreview() async {
    final uri = Uri.parse(_guestUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open preview URL')));
    }
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await widget.api.publish(_siteIid);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site published'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _openCollectionSearch() {
    setState(() => _collectionSearchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  int _initialTabIndex() => switch (widget.initialTabRoute) {
        'site.pos' || 'site.product' => 1,
        'site.contact' => 2,
        'site.object' => 3,
        'site.settings' => 4,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    const tabs = ['Preview', 'Products', 'Contacts', 'Objects', 'Settings'];
    return DefaultTabController(
      length: tabs.length,
      initialIndex: _initialTabIndex().clamp(0, tabs.length - 1),
      child: ColoredBox(
        color: const Color(0xFF08080A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onBack != null || widget.title != null) _navBarWrap(),
            Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final isCollection = controller.index >= 1 && controller.index <= 3;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              labelColor: _text,
                              unselectedLabelColor: _muted,
                              indicatorColor: _accent,
                              dividerColor: _border,
                              tabs: [for (final t in tabs) Tab(text: t)],
                            ),
                          ),
                          if (isCollection) ...[
                            if (_collectionSearchOpen)
                              SizedBox(width: 220, child: _searchBar())
                            else
                              IconButton(
                                tooltip: 'Search table',
                                onPressed: _openCollectionSearch,
                                icon: const Icon(Icons.search, size: 20, color: _muted),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _previewTab(),
                  _collectionTab('site.product'),
                  _collectionTab('site.contact'),
                  _collectionTab('site.object'),
                  _settingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBarWrap() => uiDesktopWindow
      ? _navBar()
      : SafeArea(bottom: false, child: _navBar());

  Widget _navBar() => Container(
        padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(
          children: [
            if (widget.onBack != null)
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, color: _text)),
            Expanded(
              child: Text(widget.title ?? widget.row.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _searchBar() => TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        style: const TextStyle(color: _text, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Filter rows',
          hintStyle: const TextStyle(color: _muted),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 16, color: _muted),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _collectionSearchOpen = false);
            },
          ),
          border: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        ),
      );

  Widget _previewTab() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guest URL', style: TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 6),
            SelectableText(_guestUrl, style: const TextStyle(color: _text, fontSize: 15)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _openPreview,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open preview'),
                  style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
                ),
                OutlinedButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: _publishing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.publish_outlined, size: 18),
                  label: Text(_publishing ? 'Publishing…' : 'Publish'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Layout edits happen on Home via @mention + web.builder topic.', style: TextStyle(color: _muted, fontSize: 13)),
          ],
        ),
      );

  Widget _settingsTab() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _settingRow('Alien ID', widget.row.alienId),
            _settingRow('Site ID', '${widget.row.siteIid}'),
            _settingRow('Published', widget.row.publishedVersionId.isEmpty ? 'Draft only' : widget.row.publishedVersionId),
          ],
        ),
      );

  Widget _settingRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value.isEmpty ? '—' : value, style: const TextStyle(color: _text, fontSize: 14)),
          ],
        ),
      );

  Widget _collectionTab(String collection) {
    if (_defsLoading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final def = widget.api.tableDefFor(_defs, collection);
    if (def == null) {
      return Center(child: Text('No table definition for $collection', style: const TextStyle(color: _muted)));
    }
    return UiSiteCollectionTable(
      api: widget.api,
      siteIid: _siteIid,
      def: def,
      searchQuery: _tableSearch,
    );
  }
}

class UiSiteCollectionTable extends StatefulWidget {
  const UiSiteCollectionTable({
    super.key,
    required this.api,
    required this.siteIid,
    required this.def,
    this.searchQuery = '',
  });

  final SiteApi api;
  final int siteIid;
  final TableDef def;
  final String searchQuery;

  @override
  State<UiSiteCollectionTable> createState() => _UiSiteCollectionTableState();
}

class _UiSiteCollectionTableState extends State<UiSiteCollectionTable> {
  var _loading = true;
  var _busy = false;
  List<Map<String, String>> _rows = const [];
  final _products = <String, SiteProduct>{};
  final _contacts = <String, SiteContact>{};
  final _objects = <String, SiteObject>{};
  final _embeds = <SiteProductEmbed>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UiSiteCollectionTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.def.collection != widget.def.collection || oldWidget.siteIid != widget.siteIid) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      switch (widget.def.collection) {
        case 'site.product':
          final items = await widget.api.productList(widget.siteIid);
          _embeds
            ..clear()
            ..addAll(await widget.api.productEmbedList(widget.siteIid));
          _products
            ..clear()
            ..addEntries(items.map((p) {
              final cells = siteProductCells(p);
              return MapEntry(siteRowKey(widget.def, cells), p);
            }));
          _rows = _products.values.map(siteProductCells).toList(growable: false);
        case 'site.contact':
          final items = await widget.api.contactList(widget.siteIid);
          _contacts
            ..clear()
            ..addEntries(items.map((c) {
              final cells = siteContactCells(c);
              return MapEntry(siteRowKey(widget.def, cells), c);
            }));
          _rows = _contacts.values.map(siteContactCells).toList(growable: false);
        case 'site.object':
          final items = await widget.api.objectList(widget.siteIid);
          _objects
            ..clear()
            ..addEntries(items.map((o) {
              final cells = siteObjectCells(o);
              return MapEntry(siteRowKey(widget.def, cells), o);
            }));
          _rows = _objects.values.map(siteObjectCells).toList(growable: false);
        default:
          _rows = const [];
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commit(String rowKey, ColDef col, String value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (widget.def.collection) {
        case 'site.product':
          final base = _products[rowKey] ?? widget.api.productNew(widget.siteIid);
          final updated = await widget.api.productPut(widget.siteIid, siteProductApplyCell(base, col, value));
          final cells = siteProductCells(updated);
          final key = siteRowKey(widget.def, cells);
          _products[key] = updated;
          _rows = _products.values.map(siteProductCells).toList(growable: false);
        case 'site.contact':
          final base = _contacts[rowKey] ?? widget.api.contactNew(widget.siteIid);
          final updated = await widget.api.contactPut(widget.siteIid, siteContactApplyCell(base, col, value));
          final cells = siteContactCells(updated);
          final key = siteRowKey(widget.def, cells);
          _contacts[key] = updated;
          _rows = _contacts.values.map(siteContactCells).toList(growable: false);
        case 'site.object':
          final base = _objects[rowKey] ?? widget.api.objectNew(widget.siteIid);
          final updated = await widget.api.objectPut(widget.siteIid, siteObjectApplyCell(base, col, value));
          final cells = siteObjectCells(updated);
          final key = siteRowKey(widget.def, cells);
          _objects[key] = updated;
          _rows = _objects.values.map(siteObjectCells).toList(growable: false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addRow() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (widget.def.collection) {
        case 'site.product':
          final p = await widget.api.productPut(widget.siteIid, widget.api.productNew(widget.siteIid));
          final cells = siteProductCells(p);
          _products[siteRowKey(widget.def, cells)] = p;
          _rows = _products.values.map(siteProductCells).toList(growable: false);
        case 'site.contact':
          final c = await widget.api.contactPut(widget.siteIid, widget.api.contactNew(widget.siteIid));
          final cells = siteContactCells(c);
          _contacts[siteRowKey(widget.def, cells)] = c;
          _rows = _contacts.values.map(siteContactCells).toList(growable: false);
        case 'site.object':
          final o = await widget.api.objectPut(widget.siteIid, widget.api.objectNew(widget.siteIid));
          final cells = siteObjectCells(o);
          _objects[siteRowKey(widget.def, cells)] = o;
          _rows = _objects.values.map(siteObjectCells).toList(growable: false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _embedSubtable(String rowKey) {
    final product = _products[rowKey];
    if (product == null) return const SizedBox.shrink();
    final sub = widget.def.subtables.isNotEmpty ? widget.def.subtables.first : null;
    final embedDef = collectionDefEmbedFallback();
    if (sub == null || embedDef == null) {
      return Text('No subtable definition', style: const TextStyle(color: _muted, fontSize: 12));
    }
    final pid = product.productId.toString();
    final embedRows = _embeds
        .where((e) => e.productId == product.productId)
        .map(siteProductEmbedCells)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sub.label.isNotEmpty ? sub.label : 'Subtable', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        UiTable(def: embedDef, rows: embedRows, searchQuery: widget.searchQuery),
        if (embedRows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('No alt labels for product $pid', style: const TextStyle(color: _muted, fontSize: 12)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => UiTable(
        def: widget.def,
        rows: _rows,
        loading: _loading || _busy,
        searchQuery: widget.searchQuery,
        onCellCommit: _commit,
        onAddRow: _addRow,
        expandedBuilder: widget.def.collection == 'site.product' && widget.def.subtables.isNotEmpty ? _embedSubtable : null,
      );
}
