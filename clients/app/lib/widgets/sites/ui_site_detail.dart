import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/collection_def.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:alienai_c35/widgets/sites/io_site_domain_dialogs.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:alienai_c35/widgets/sites/tx/ui_site_tx_editor.dart';
import 'package:alienai_c35/widgets/sites/ui_site_preview.dart';
import 'package:alienai_c35/widgets/ui/ui_col_cell.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_table.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _error = Color(0xFFF87171);

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
  var _previewMode = SitePreviewMode.draft;
  var _previewReloadNonce = 0;

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

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await widget.api.publish(_siteIid);
      if (mounted) {
        setState(() => _previewReloadNonce++);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site published'), behavior: SnackBarBehavior.floating));
      }
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
        'site.pos' => 1,
        'site.product' => 2,
        'site.contact' => 3,
        'site.object' => 4,
        'site.settings' => 5,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    const tabs = ['Preview', 'Orders', 'Products', 'Contacts', 'Objects', 'Settings'];
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
                    final isCollection = controller.index >= 1 && controller.index <= 4;
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
                              uiIconButton(
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
                  _ordersTab(),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SegmentedButton<SitePreviewMode>(
                  segments: const [
                    ButtonSegment(value: SitePreviewMode.draft, label: Text('Draft'), icon: Icon(Icons.edit_note, size: 16)),
                    ButtonSegment(value: SitePreviewMode.published, label: Text('Published'), icon: Icon(Icons.public, size: 16)),
                  ],
                  selected: {_previewMode},
                  onSelectionChanged: (s) => setState(() => _previewMode = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _text : _muted),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: _publishing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.publish_outlined, size: 18),
                  label: Text(_publishing ? 'Publishing…' : 'Publish'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: UiSitePreview(
                row: widget.row,
                api: widget.api,
                mode: _previewMode,
                reloadNonce: _previewReloadNonce,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Layout edits happen on Home via @mention + web.builder topic.', style: TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      );

  Widget _settingsTab() => _UiSiteSettingsTab(
        row: widget.row,
        api: widget.api,
        siteIid: _siteIid,
        defs: _defs,
        onCapabilitiesSaved: _loadDefs,
      );

  Widget _ordersTab() => UiSiteOrdersTab(
        api: widget.api,
        site: widget.row,
        siteIid: _siteIid,
        searchQuery: _tableSearch,
        defs: _defs,
        defsLoading: _defsLoading,
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

class UiSiteOrdersTab extends StatefulWidget {
  const UiSiteOrdersTab({
    super.key,
    required this.api,
    required this.site,
    required this.siteIid,
    required this.defs,
    required this.defsLoading,
    this.searchQuery = '',
  });

  final SiteApi api;
  final SiteRow site;
  final int siteIid;
  final List<TableDef> defs;
  final bool defsLoading;
  final String searchQuery;

  @override
  State<UiSiteOrdersTab> createState() => _UiSiteOrdersTabState();
}

class _UiSiteOrdersTabState extends State<UiSiteOrdersTab> {
  late final TxApi _txApi = TxApi(widget.api.conn);
  var _loading = true;
  var _busy = false;
  List<Tx> _txs = const [];
  final _byKey = <String, Tx>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UiSiteOrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) _load();
  }

  TableDef _def() =>
      widget.api.tableDefFor(widget.defs, 'site.tx') ?? collectionDefForFallback('site.tx')!;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _txs = await _txApi.list(widget.siteIid);
      final def = _def();
      _byKey
        ..clear()
        ..addEntries(_txs.map((t) {
          final cells = siteTxCells(t);
          return MapEntry(siteRowKey(def, cells), t);
        }));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({Int64? txId}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await Navigator.of(context).push<Tx>(
        MaterialPageRoute(
          builder: (_) => UiSiteTxEditor(siteIid: widget.siteIid, api: widget.api, site: widget.site, txId: txId, onSaved: (_) {}),
        ),
      );
      if (saved != null) await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.defsLoading || _loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final def = _def();
    final rows = _txs.map(siteTxCells).toList(growable: false);
    return UiTable(
      def: def,
      rows: rows,
      loading: _busy,
      searchQuery: widget.searchQuery,
      onAddRow: () => _openEditor(),
      onRowTap: (key) {
        final tx = _byKey[key];
        if (tx != null) _openEditor(txId: tx.txId);
      },
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
  final _productsById = <String, SiteProduct>{};
  final _contactsById = <String, SiteContact>{};
  final _objects = <String, SiteObject>{};
  final _embeds = <SiteProductEmbed>[];

  UiColCellHost get _colCellHost => UiColCellHost(
        siteIid: widget.siteIid,
        products: _productsById,
        contacts: _contactsById,
      );

  void _syncProducts(List<SiteProduct> items) {
    _products
      ..clear()
      ..addEntries(items.map((p) {
        final cells = siteProductCells(p);
        return MapEntry(siteRowKey(widget.def, cells), p);
      }));
    _productsById
      ..clear()
      ..addEntries(items.map((p) => MapEntry('${p.productId}', p)));
  }

  void _syncContacts(List<SiteContact> items) {
    _contacts
      ..clear()
      ..addEntries(items.map((c) {
        final cells = siteContactCells(c);
        return MapEntry(siteRowKey(widget.def, cells), c);
      }));
    _contactsById
      ..clear()
      ..addEntries(items.map((c) => MapEntry('${c.contactId}', c)));
  }

  Future<void> _loadRefProducts() async {
    final items = await widget.api.productList(widget.siteIid);
    _productsById
      ..clear()
      ..addEntries(items.map((p) => MapEntry('${p.productId}', p)));
  }

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
          _syncProducts(items);
          _rows = _products.values.map(siteProductCells).toList(growable: false);
        case 'site.contact':
          final items = await widget.api.contactList(widget.siteIid);
          _syncContacts(items);
          _rows = _contacts.values.map(siteContactCells).toList(growable: false);
        case 'site.object':
          final items = await widget.api.objectList(widget.siteIid);
          await _loadRefProducts();
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

  List<SiteProductEmbed> _productEmbeds(Int64 productId) =>
      _embeds.where((e) => e.productId == productId).toList(growable: false);

  Future<void> _commitEmbed(String productRowKey, String embedRowKey, ColDef col, String value) async {
    if (_busy) return;
    final product = _products[productRowKey];
    if (product == null) return;
    setState(() => _busy = true);
    try {
      final embeds = _productEmbeds(product.productId);
      final idx = embeds.indexWhere((e) => e.embedId.toString() == embedRowKey);
      final base = idx >= 0 ? embeds[idx] : widget.api.productEmbedNew(widget.siteIid, product.productId);
      final updated = siteProductEmbedApplyCell(base, col, value);
      final next = [...embeds];
      if (idx >= 0) {
        next[idx] = updated;
      } else {
        next.add(updated);
      }
      await widget.api.productPut(widget.siteIid, product, embeds: next);
      _embeds
        ..clear()
        ..addAll(await widget.api.productEmbedList(widget.siteIid));
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addEmbed(String productRowKey) async {
    if (_busy) return;
    final product = _products[productRowKey];
    if (product == null) return;
    setState(() => _busy = true);
    try {
      final next = [..._productEmbeds(product.productId), widget.api.productEmbedNew(widget.siteIid, product.productId)];
      await widget.api.productPut(widget.siteIid, product, embeds: next);
      _embeds
        ..clear()
        ..addAll(await widget.api.productEmbedList(widget.siteIid));
      if (mounted) setState(() {});
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
    final embedRows = _productEmbeds(product.productId).map(siteProductEmbedCells).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sub.label.isNotEmpty ? sub.label : 'Subtable', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        UiTable(
          def: embedDef,
          rows: embedRows,
          loading: _busy,
          searchQuery: widget.searchQuery,
          colCellHost: _colCellHost,
          onCellCommit: (embedKey, col, value) => _commitEmbed(rowKey, embedKey, col, value),
          onAddRow: () => _addEmbed(rowKey),
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
        colCellHost: _colCellHost,
        onCellCommit: _commit,
        onAddRow: _addRow,
        expandedBuilder: widget.def.collection == 'site.product' && widget.def.subtables.isNotEmpty ? _embedSubtable : null,
      );
}

class _UiSiteSettingsTab extends StatefulWidget {
  const _UiSiteSettingsTab({
    required this.row,
    required this.api,
    required this.siteIid,
    required this.defs,
    required this.onCapabilitiesSaved,
  });

  final SiteRow row;
  final SiteApi api;
  final int siteIid;
  final List<TableDef> defs;
  final Future<void> Function() onCapabilitiesSaved;

  @override
  State<_UiSiteSettingsTab> createState() => _UiSiteSettingsTabState();
}

class _UiSiteSettingsTabState extends State<_UiSiteSettingsTab> {
  var _loading = true;
  var _savingCaps = false;
  var _domainsBusy = false;
  int? _fixingDomainId;
  Map<String, bool> _caps = {for (final k in ['commerce', 'booking', 'queue']) k: true};
  final _domains = <String, SiteDomain>{};
  List<Map<String, String>> _domainRows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  TableDef _domainDef() =>
      widget.api.domainTableDef(widget.defs) ?? TableDef(collection: 'site.domain', primaryKey: 'site_iid,id');

  void _setDomains(List<SiteDomain> items) {
    final def = _domainDef();
    _domains
      ..clear()
      ..addEntries(items.map((d) {
        final cells = siteDomainCells(d);
        return MapEntry(siteRowKey(def, cells), d);
      }));
    _domainRows = _domains.values.map(siteDomainCells).toList(growable: false);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await widget.api.configGet(widget.siteIid);
      _caps = siteCapabilitiesParse(config.capabilitiesJson);
      _setDomains(await widget.api.domainList(widget.siteIid));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCapability(String key, bool value) async {
    if (_savingCaps) return;
    setState(() {
      _savingCaps = true;
      _caps = {..._caps, key: value};
    });
    try {
      await widget.api.configPut(widget.siteIid, capabilitiesJson: siteCapabilitiesEncode(_caps));
      await widget.onCapabilitiesSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      await _load();
    } finally {
      if (mounted) setState(() => _savingCaps = false);
    }
  }

  Future<void> _commitDomain(String rowKey, ColDef col, String value) async {
    if (_domainsBusy) return;
    setState(() => _domainsBusy = true);
    try {
      final base = _domains[rowKey] ?? widget.api.domainNew(widget.siteIid);
      await widget.api.domainPut(widget.siteIid, siteDomainApplyCell(base, col, value));
      _setDomains(await widget.api.domainList(widget.siteIid));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _domainsBusy = false);
    }
  }

  Future<void> _addDomain() async {
    if (_domainsBusy) return;
    setState(() => _domainsBusy = true);
    try {
      await widget.api.domainPut(widget.siteIid, widget.api.domainNew(widget.siteIid));
      _setDomains(await widget.api.domainList(widget.siteIid));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _domainsBusy = false);
    }
  }

  Future<void> _refreshDomains() async => _setDomains(await widget.api.domainList(widget.siteIid));

  Future<void> _verifyDomain(SiteDomain d) async {
    if (_domainsBusy) return;
    await ioSiteDomainDnsDialogOpen(
      context,
      domain: d.hostname,
      errorMessage: d.verifyError.isNotEmpty ? d.verifyError : null,
      onCheck: () async {
        setState(() => _domainsBusy = true);
        try {
          final res = await widget.api.domainVerify(widget.siteIid, d.id.toInt());
          await _refreshDomains();
          if (!mounted) return false;
          if (res.dnsVerified) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DNS verified'), behavior: SnackBarBehavior.floating));
            return true;
          }
          final msg = res.error.isNotEmpty ? res.error : 'DNS verification failed';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
          return false;
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
          return false;
        } finally {
          if (mounted) setState(() => _domainsBusy = false);
        }
      },
    );
  }

  Future<void> _fixHttps(SiteDomain d) async {
    if (_fixingDomainId != null) return;
    setState(() => _fixingDomainId = d.id.toInt());
    try {
      final res = await widget.api.domainVerify(widget.siteIid, d.id.toInt(), forceTls: true);
      await _refreshDomains();
      if (!mounted) return;
      final tls = res.tlsStatus.trim();
      if (tls == 'ready' || tls == 'active') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('HTTPS ready'), behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tls.isEmpty ? 'TLS sync requested' : 'TLS: $tls'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _fixingDomainId = null);
    }
  }

  Widget _domainStatusRow(String rowKey, double width) {
    final d = _domains[rowKey];
    if (d == null) return const SizedBox.shrink();
    final domainId = d.id.toInt();
    final dnsOk = siteDomainDnsVerified(d);
    final tls = siteDomainTlsChip(d.tlsStatus);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.6))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!dnsOk)
                  TextButton(
                    onPressed: _domainsBusy ? null : () => _verifyDomain(d),
                    child: const Text('Verify DNS'),
                  )
                else if (tls == SiteDomainTlsChip.failed)
                  TextButton(
                    onPressed: _fixingDomainId != null ? null : () => _fixHttps(d),
                    child: _fixingDomainId == domainId
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
                        : const Text('Fix HTTPS'),
                  ),
                TextButton(
                  onPressed: _domainsBusy ? null : () => ioSiteDomainDnsDialogOpen(context, domain: d.hostname),
                  child: const Text('DNS steps'),
                ),
              ],
            ),
            if (dnsOk) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SiteDomainStatusChip(label: 'DNS verified', tone: _SiteDomainChipTone.ok),
                  switch (tls) {
                    SiteDomainTlsChip.ready => _SiteDomainStatusChip(label: 'HTTPS ready', tone: _SiteDomainChipTone.ok),
                    SiteDomainTlsChip.failed => _SiteDomainStatusChip(label: 'HTTPS failed', tone: _SiteDomainChipTone.bad),
                    SiteDomainTlsChip.disabled => _SiteDomainStatusChip(label: 'HTTPS cluster only', tone: _SiteDomainChipTone.muted),
                    SiteDomainTlsChip.pending => _SiteDomainStatusChip(label: 'HTTPS pending', tone: _SiteDomainChipTone.warn),
                  },
                ],
              ),
              if (d.tlsError.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(d.tlsError, style: const TextStyle(color: _error, fontSize: 12)),
              ],
            ] else if (d.verifyError.isNotEmpty) ...[
              Text(d.verifyError, style: const TextStyle(color: _error, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
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

  Widget _capToggle(String key, String label) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(color: _text, fontSize: 14)),
        value: _caps[key] ?? true,
        activeThumbColor: _accent,
        onChanged: _savingCaps ? null : (v) => _saveCapability(key, v),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final domainDef = widget.api.domainTableDef(widget.defs);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _infoRow('Alien ID', widget.row.alienId),
        _infoRow('Site ID', '${widget.row.siteIid}'),
        _infoRow('Published', widget.row.publishedVersionId.isEmpty ? 'Draft only' : widget.row.publishedVersionId),
        const SizedBox(height: 20),
        const Text('Capabilities', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Enable backend features for this site.', style: TextStyle(color: _muted, fontSize: 12)),
        _capToggle('commerce', 'Commerce (Orders & Products)'),
        _capToggle('booking', 'Booking (Objects tab)'),
        _capToggle('queue', 'Queue blocks'),
        const SizedBox(height: 28),
        const Text('Domains', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('CNAME to $siteDomainCnameTarget (grey / DNS only)', style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 12),
        if (domainDef == null)
          const Text('No domain table definition', style: TextStyle(color: _muted))
        else
          UiTable(
            def: domainDef,
            rows: _domainRows,
            loading: _domainsBusy,
            onCellCommit: _commitDomain,
            onAddRow: _addDomain,
            rowBuilder: (scope) => [...scope.defaultTiles, _domainStatusRow(scope.rowKey, scope.tableWidth)],
          ),
      ],
    );
  }
}

enum _SiteDomainChipTone { ok, warn, bad, muted }

class _SiteDomainStatusChip extends StatelessWidget {
  const _SiteDomainStatusChip({required this.label, required this.tone});

  final String label;
  final _SiteDomainChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (tone) {
      _SiteDomainChipTone.ok => (
          const Color(0xFF14532D).withValues(alpha: 0.45),
          const Color(0xFF22C55E).withValues(alpha: 0.45),
          const Color(0xFF4ADE80),
          Icons.verified,
        ),
      _SiteDomainChipTone.warn => (
          const Color(0xFF713F12).withValues(alpha: 0.40),
          const Color(0xFFF59E0B).withValues(alpha: 0.45),
          const Color(0xFFFCD34D),
          Icons.hourglass_top,
        ),
      _SiteDomainChipTone.bad => (
          const Color(0xFF7F1D1D).withValues(alpha: 0.40),
          const Color(0xFFEF4444).withValues(alpha: 0.45),
          const Color(0xFFFCA5A5),
          Icons.error_outline,
        ),
      _SiteDomainChipTone.muted => (
          const Color(0xFF27272A),
          _border,
          _muted,
          Icons.info_outline,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}
