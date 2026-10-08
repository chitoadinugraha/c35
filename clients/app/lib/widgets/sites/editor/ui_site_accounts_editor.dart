import 'dart:async';

import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

class UiSiteAccountsEditor extends StatefulWidget {
  const UiSiteAccountsEditor({
    super.key,
    required this.api,
    required this.siteIid,
    required this.masterDetail,
    this.detailId,
    this.onDetailIdChanged,
    this.onDraftSaved,
  });

  final SiteApi api;
  final int siteIid;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;
  final VoidCallback? onDraftSaved;

  @override
  State<UiSiteAccountsEditor> createState() => _UiSiteAccountsEditorState();
}

class _UiSiteAccountsEditorState extends State<UiSiteAccountsEditor> {
  late final _searchCtrl = TextEditingController();
  late final _bankCtrl = TextEditingController();
  late final _nameCtrl = TextEditingController();
  late final _numberCtrl = TextEditingController();
  late final _qrisCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  String? _error;
  String? _selectedId;
  String? _editingId;
  var _suppress = false;
  Timer? _saveTimer;
  final _items = <SitePaymentAccountDraft>[];

  @override
  void initState() {
    super.initState();
    for (final c in [_bankCtrl, _nameCtrl, _numberCtrl, _qrisCtrl]) {
      c.addListener(_onField);
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _searchCtrl.dispose();
    _bankCtrl.dispose();
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _qrisCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteAccountsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (oldWidget.detailId != widget.detailId) _bindActive();
  }

  List<SitePaymentAccountDraft> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return List<SitePaymentAccountDraft>.from(_items);
    return _items.where((a) {
      return a.bank.toLowerCase().contains(q) ||
          a.accountName.toLowerCase().contains(q) ||
          a.accountNumber.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String? get _activeId => widget.masterDetail ? _selectedId : widget.detailId;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      _items
        ..clear()
        ..addAll(siteDraftExtrasParse(draft.doc.metaJson).paymentAccounts);
      _pickDefault();
      _bindActive();
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickDefault() {
    if (_items.isEmpty) {
      _selectedId = null;
      if (!widget.masterDetail) widget.onDetailIdChanged?.call(null);
      return;
    }
    if (widget.masterDetail) {
      if (_selectedId == null || !_items.any((a) => a.id == _selectedId)) _selectedId = _items.first.id;
      return;
    }
    if (widget.detailId != null && !_items.any((a) => a.id == widget.detailId)) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
      _bindActive();
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  SitePaymentAccountDraft? _find(String? id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _bindActive() {
    final item = _find(_activeId);
    _suppress = true;
    _editingId = item?.id;
    _bankCtrl.text = item?.bank ?? '';
    _nameCtrl.text = item?.accountName ?? '';
    _numberCtrl.text = item?.accountNumber ?? '';
    _qrisCtrl.text = item?.qrisPic ?? '';
    _suppress = false;
  }

  void _onField() {
    if (_loading || _suppress) return;
    final id = _editingId;
    if (id == null) return;
    final i = _items.indexWhere((a) => a.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(
      bank: _bankCtrl.text,
      accountName: _nameCtrl.text,
      accountNumber: _numberCtrl.text,
      qrisPic: _qrisCtrl.text,
    );
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () => unawaited(_save()));
  }

  Future<void> _save() async {
    await SiteEditorSaveScope.run(context, () async {
      final draft = await widget.api.draftGet(widget.siteIid);
      final next = draft.clone();
      final doc = next.doc.clone();
      doc.metaJson = siteDraftExtrasMerge(doc.metaJson, paymentAccounts: List<SitePaymentAccountDraft>.from(_items));
      next.doc = doc;
      await widget.api.draftPut(next);
      widget.onDraftSaved?.call();
    });
  }

  void _add() {
    final item = SitePaymentAccountDraft(id: siteDraftNewId('pa'), bank: 'BCA');
    _items.add(item);
    _searchCtrl.clear();
    setState(() => _search = '');
    _select(item.id);
    _scheduleSave();
  }

  Future<void> _delete(String id) async {
    _items.removeWhere((a) => a.id == id);
    _editingId = null;
    if (widget.masterDetail) {
      _pickDefault();
      _bindActive();
    } else {
      widget.onDetailIdChanged?.call(null);
    }
    setState(() {});
    await _save();
  }

  String _titleOf(SitePaymentAccountDraft a) {
    final bank = a.bank.trim();
    final name = a.accountName.trim();
    if (bank.isNotEmpty && name.isNotEmpty) return '$bank · $name';
    if (bank.isNotEmpty) return bank;
    if (name.isNotEmpty) return name;
    return 'Payment account';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_error != null && _items.isEmpty) {
      return Center(child: Text(_error!, style: const TextStyle(color: _muted, fontSize: 13)));
    }
    final detailId = _activeId;
    if (widget.masterDetail) {
      if (_items.isEmpty) return _listPane(selectedId: null);
      final selected = detailId ?? _items.first.id;
      if (_editingId != selected) _bindActive();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: siteCatalogMasterListW, child: _listPane(selectedId: selected)),
          siteCatalogMasterDivider(context),
          Expanded(child: _detail(selected)),
        ],
      );
    }
    if (detailId != null && _find(detailId) != null) {
      if (_editingId != detailId) _bindActive();
      return _detail(detailId);
    }
    return _listPane(selectedId: null);
  }

  Widget _listPane({required String? selectedId}) {
    final items = _filtered;
    final searching = _search.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: _searchCtrl,
          hintText: 'Search accounts',
          onSearchChanged: (v) => setState(() => _search = v),
          onAdd: _add,
          addTooltip: 'Add account',
        ),
        Expanded(
          child: items.isEmpty
              ? UiEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: searching ? 'No matching accounts' : 'No payment accounts',
                  subtitle: searching ? 'Try a different search.' : 'Add a bank account or QRIS picture for checkout.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final a = items[i];
                    final selected = a.id == selectedId;
                    return Material(
                      color: selected ? const Color(0xFF34D399).withValues(alpha: 0.12) : const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: selected ? const Color(0xFF34D399).withValues(alpha: 0.35) : const Color(0xFF27272A)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _select(a.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_outlined, size: 20, color: _muted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_titleOf(a), style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
                                    if (a.accountNumber.trim().isNotEmpty)
                                      Text(a.accountNumber.trim(), style: const TextStyle(color: _muted, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint) => UiSiteEditorLabeledField(
        label: label,
        child: TextField(controller: ctrl, style: const TextStyle(color: _text, fontSize: 14), decoration: siteEditorInputDecoration(hintText: hint)),
      );

  Widget _detail(String id) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        UiSiteCatalogDetailHeader(
          title: 'Payment account',
          icon: Icons.account_balance_outlined,
          onDelete: () => _delete(id),
          deleteLabel: 'Delete',
          deleteConfirmTitle: 'Delete this account?',
        ),
        const SizedBox(height: 16),
        _field('Bank', _bankCtrl, 'BCA'),
        _field('Account name', _nameCtrl, 'Account holder'),
        _field('Account number', _numberCtrl, 'Account number'),
        _field('QRIS picture', _qrisCtrl, 'Picture path or URL'),
      ],
    );
  }
}
