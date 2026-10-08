import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _fieldBorder = Color(0xFF3F3F46);
const _fieldFill = Color(0xFF18181B);

class UiSiteContactsEditor extends StatefulWidget {
  const UiSiteContactsEditor({
    super.key,
    required this.api,
    required this.siteIid,
    required this.masterDetail,
    this.detailId,
    this.onDetailIdChanged,
  });

  final SiteApi api;
  final int siteIid;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;

  @override
  State<UiSiteContactsEditor> createState() => _UiSiteContactsEditorState();
}

class _UiSiteContactsEditorState extends State<UiSiteContactsEditor> {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  String? _selectedId;
  final _byId = <String, SiteContact>{};
  final _debounceTimers = <String, Timer>{};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteContactsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (_selectedId != null && _byId[_selectedId] == null) _pickDefault();
  }

  List<SiteContact> get _ordered {
    final items = _byId.values.toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  String? get _firstId => _ordered.isEmpty ? null : '${_ordered.first.contactId}';

  String? get _activeId => widget.masterDetail ? (_selectedId ?? _firstId) : widget.detailId;

  void _pickDefault() {
    if (_byId.isEmpty) {
      _selectedId = null;
      if (!widget.masterDetail) widget.onDetailIdChanged?.call(null);
      return;
    }
    if (widget.masterDetail) {
      if (_selectedId == null || _byId[_selectedId] == null) _selectedId = _firstId;
      return;
    }
    if (widget.detailId != null && _byId[widget.detailId] == null) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.contactList(widget.siteIid);
      _byId
        ..clear()
        ..addEntries(items.map((c) => MapEntry('${c.contactId}', c)));
      _pickDefault();
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final c = await widget.api.contactPut(widget.siteIid, widget.api.contactNew(widget.siteIid));
      final id = '${c.contactId}';
      _byId[id] = c;
      _searchCtrl.clear();
      setState(() => _search = '');
      _select(id);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _debouncedPut(String id, SiteContact draft) {
    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 450), () => unawaited(_put(id, draft)));
  }

  Future<void> _put(String id, SiteContact draft) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.contactPut(widget.siteIid, draft);
      if (!mounted) return;
      final savedId = '${saved.contactId}';
      setState(() {
        _byId.remove(id);
        _byId[savedId] = saved;
        if (_selectedId == id) _selectedId = savedId;
        _error = null;
      });
      if (!widget.masterDetail && widget.detailId == id && widget.detailId != savedId) {
        widget.onDetailIdChanged?.call(savedId);
      }
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _patch(String id, void Function(SiteContact c) fn) {
    final base = _byId[id];
    if (base == null) return;
    final next = base.clone();
    fn(next);
    setState(() => _byId[id] = next);
    _debouncedPut(id, next);
  }

  List<SiteContact> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _ordered;
    return _ordered
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Widget _listPane({required String? selectedId}) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: _searchCtrl,
          hintText: 'Search contacts',
          onSearchChanged: (v) => setState(() => _search = v),
          onAdd: _add,
          addBusy: _busy,
        ),
        Expanded(
          child: filtered.isEmpty
              ? const UiEmptyState(icon: Icons.people_outline, title: 'No contacts', subtitle: 'Add a contact to get started')
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    final id = '${c.contactId}';
                    final active = selectedId == id;
                    return Material(
                      color: active ? const Color(0xFF1F2937) : Colors.transparent,
                      child: InkWell(
                        onTap: () => _select(id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.6)))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name.isEmpty ? 'Contact' : c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              if (c.phone.isNotEmpty || c.email.isNotEmpty)
                                Text(
                                  [c.phone, c.email].where((s) => s.isNotEmpty).join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: _muted, fontSize: 11),
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

  Widget _detailPane(String id) {
    final contact = _byId[id];
    if (contact == null) {
      return const Center(child: Text('Contact not found', style: TextStyle(color: _muted)));
    }
    return _UiSiteContactDetailForm(contactId: id, contact: contact, onPatch: _patch);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    if (_error != null && _byId.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final detailId = _activeId;
    final Widget body;
    if (widget.masterDetail && _byId.isNotEmpty) {
      final selected = detailId ?? _firstId!;
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: siteCatalogMasterListW, child: _listPane(selectedId: selected)),
          siteCatalogMasterDivider(context),
          Expanded(child: _detailPane(selected)),
        ],
      );
    } else {
      body = widget.masterDetail || detailId == null ? _listPane(selectedId: detailId) : _detailPane(detailId);
    }

    if (_error == null || _error!.isEmpty) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0x33F87171),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _UiSiteContactDetailForm extends StatefulWidget {
  const _UiSiteContactDetailForm({required this.contactId, required this.contact, required this.onPatch});

  final String contactId;
  final SiteContact contact;
  final void Function(String id, void Function(SiteContact c) fn) onPatch;

  @override
  State<_UiSiteContactDetailForm> createState() => _UiSiteContactDetailFormState();
}

class _UiSiteContactDetailFormState extends State<_UiSiteContactDetailForm> {
  late final _nameCtrl = TextEditingController(text: widget.contact.name);
  late final _phoneCtrl = TextEditingController(text: widget.contact.phone);
  late final _emailCtrl = TextEditingController(text: widget.contact.email);
  late final _addressCtrl = TextEditingController(text: widget.contact.address);
  late final _noteCtrl = TextEditingController(text: widget.contact.note);
  late final _picCtrl = TextEditingController(text: _contactPic(widget.contact));
  late String _featured = _contactFeatured(widget.contact);

  @override
  void didUpdateWidget(covariant _UiSiteContactDetailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contactId != widget.contactId) {
      _nameCtrl.text = widget.contact.name;
      _phoneCtrl.text = widget.contact.phone;
      _emailCtrl.text = widget.contact.email;
      _addressCtrl.text = widget.contact.address;
      _noteCtrl.text = widget.contact.note;
      _picCtrl.text = _contactPic(widget.contact);
      _featured = _contactFeatured(widget.contact);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _picCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _fieldFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _fieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF34D399))),
      );

  Widget _field(String label, TextEditingController ctrl, void Function(String v) onChanged,
      {TextInputType? keyboard, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: ctrl,
              onChanged: onChanged,
              keyboardType: keyboard,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 13, color: _text),
              decoration: _decoration(),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final id = widget.contactId;
    final c = widget.contact;
    return UiSiteEditorFormScroll(
      children: [
        Text(c.name.isEmpty ? 'Contact' : c.name, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('ID ${c.contactId}', style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 16),
        _field('Name', _nameCtrl, (v) => widget.onPatch(id, (c) => c.name = v)),
        _field('Phone', _phoneCtrl, (v) => widget.onPatch(id, (c) => c.phone = v), keyboard: TextInputType.phone),
        _field('Email', _emailCtrl, (v) => widget.onPatch(id, (c) => c.email = v), keyboard: TextInputType.emailAddress),
        _field('Address', _addressCtrl, (v) => widget.onPatch(id, (c) => c.address = v), maxLines: 2),
        _field('Note', _noteCtrl, (v) => widget.onPatch(id, (c) => c.note = v), maxLines: 3),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Featured', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                key: ValueKey('featured-$id-$_featured'),
                initialValue: _featured,
                decoration: _decoration(),
                dropdownColor: _fieldFill,
                style: const TextStyle(fontSize: 13, color: _text),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: 'partners', child: Text('Partner')),
                  DropdownMenuItem(value: 'clients', child: Text('Client')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _featured = v);
                  widget.onPatch(id, (c) => _contactSetFeatured(c, v));
                },
              ),
            ],
          ),
        ),
        _field(
          'Picture URL',
          _picCtrl,
          (v) => widget.onPatch(id, (c) => _contactSetPic(c, v)),
          keyboard: TextInputType.url,
        ),
      ],
    );
  }
}

Map<String, dynamic> _contactMeta(SiteContact contact) {
  final raw = contact.metaJson.trim();
  if (raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
  } catch (_) {}
  return {};
}

void _contactWriteMeta(SiteContact contact, Map<String, dynamic> meta) {
  contact.metaJson = meta.isEmpty ? '' : jsonEncode(meta);
}

String _contactFeatured(SiteContact contact) {
  final value = _contactMeta(contact)['featured']?.toString() ?? '';
  if (value == 'partners' || value == 'clients') return value;
  return 'none';
}

void _contactSetFeatured(SiteContact contact, String featured) {
  final meta = _contactMeta(contact);
  if (featured == 'partners' || featured == 'clients') {
    meta['featured'] = featured;
  } else {
    meta.remove('featured');
  }
  _contactWriteMeta(contact, meta);
}

String _contactPic(SiteContact contact) => _contactMeta(contact)['pic']?.toString() ?? '';

void _contactSetPic(SiteContact contact, String pic) {
  final meta = _contactMeta(contact);
  final trimmed = pic.trim();
  if (trimmed.isEmpty) {
    meta.remove('pic');
  } else {
    meta['pic'] = trimmed;
  }
  _contactWriteMeta(contact, meta);
}
