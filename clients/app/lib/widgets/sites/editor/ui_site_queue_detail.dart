import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_editor_autosave.dart';
import 'package:alienai_c35/c/site/site_queue_meta.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_queue_operator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _muted = Color(0xFF71717A);

class UiSiteQueueDetail extends StatefulWidget {
  const UiSiteQueueDetail({
    super.key,
    required this.api,
    required this.siteIid,
    required this.queueId,
    required this.queue,
    required this.busy,
    required this.onPatch,
    required this.onDelete,
    required this.onSaved,
  });

  final SiteApi api;
  final int siteIid;
  final String queueId;
  final SiteQueue queue;
  final bool busy;
  final void Function(void Function(SiteQueue q) fn) onPatch;
  final Future<void> Function() onDelete;
  final ValueChanged<SiteQueue> onSaved;

  @override
  State<UiSiteQueueDetail> createState() => _UiSiteQueueDetailState();
}

class _UiSiteQueueDetailState extends State<UiSiteQueueDetail> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late final TextEditingController _name;
  late final TextEditingController _prefix;
  late final TextEditingController _description;
  late SiteQueueMeta _meta;
  var _fields = <_FieldRow>[];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _name = TextEditingController();
    _prefix = TextEditingController();
    _description = TextEditingController();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant UiSiteQueueDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queueId != widget.queueId || oldWidget.queue != widget.queue) _syncFromWidget();
  }

  void _syncFromWidget() {
    final q = widget.queue;
    _name.text = q.name;
    _prefix.text = q.prefix;
    _meta = siteQueueMetaOf(q);
    _description.text = _meta.description;
    for (final row in _fields) {
      row.label.dispose();
    }
    _fields = _meta.fields
        .map(
          (f) => _FieldRow(
            id: f.id,
            type: f.type,
            required: f.required,
            label: TextEditingController(text: f.label),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    _prefix.dispose();
    _description.dispose();
    for (final row in _fields) {
      row.label.dispose();
    }
    super.dispose();
  }

  void _applyMetaToQueue(SiteQueue q) {
    final fields = _fields
        .where((r) => r.label.text.trim().isNotEmpty)
        .map((r) => SiteQueueFieldDef(id: r.id, label: r.label.text.trim(), type: r.type, required: r.required))
        .toList();
    final meta = _meta.copyWith(description: _description.text.trim(), fields: fields);
    siteQueueApplyMeta(q, meta);
  }

  void _debouncedSave() {
    siteEditorScheduleSave(
      context,
      key: 'queue:${widget.queueId}',
      debounce: const Duration(milliseconds: 450),
      save: _saveNow,
    );
  }

  Future<void> _saveNow() async {
    widget.onPatch((q) {
      q.name = _name.text.trim();
      q.prefix = _prefix.text.trim().toUpperCase();
      _applyMetaToQueue(q);
    });
  }

  void _onFieldChanged() => _debouncedSave();

  void _addField() {
    setState(() {
      _fields.add(
        _FieldRow(
          id: 'field-${DateTime.now().millisecondsSinceEpoch}',
          type: 'text',
          label: TextEditingController(),
        ),
      );
    });
    _debouncedSave();
  }

  void _removeField(int index) {
    final row = _fields.removeAt(index);
    row.label.dispose();
    setState(() {});
    _debouncedSave();
  }

  Future<void> _confirmDelete() async {
    final ok = await siteCatalogConfirmDelete(
      context,
      title: 'Remove counter?',
      body: 'Guests will no longer see this queue. Tickets already issued are kept on the server.',
    );
    if (ok) await widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.queue;
    final preview = siteQueueTicketPreview(q, ticketNo: q.servingTicketNo > 0 ? q.servingTicketNo : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.name.isNotEmpty ? q.name : 'Queue', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('Prefix ${q.prefix.isEmpty ? '—' : q.prefix}', style: const TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active', style: TextStyle(color: _muted, fontSize: 12)),
                  Switch(
                    value: q.isActive,
                    onChanged: widget.busy ? null : (v) => widget.onPatch((row) => row.isActive = v),
                    activeThumbColor: siteEditorFormAccent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Remove counter',
                onPressed: widget.busy ? null : () => unawaited(_confirmDelete()),
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Settings'),
            Tab(text: 'Board'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              UiSiteEditorFormScroll(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: siteEditorCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: siteEditorFieldBorder),
                    ),
                    child: Column(
                      children: [
                        const Text('Ticket preview', style: TextStyle(color: _muted, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(
                          preview,
                          style: const TextStyle(
                            color: siteEditorFormAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  UiSiteEditorLabeledField(
                    label: 'Counter name',
                    child: TextField(
                      controller: _name,
                      enabled: !widget.busy,
                      decoration: siteEditorInputDecoration(hintText: 'e.g. Cashier 1'),
                      onChanged: (_) => _onFieldChanged(),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: UiSiteEditorLabeledField(
                          label: 'Description',
                          child: TextField(
                            controller: _description,
                            enabled: !widget.busy,
                            minLines: 2,
                            maxLines: 3,
                            decoration: siteEditorInputDecoration(hintText: 'Shown to staff'),
                            onChanged: (_) => _onFieldChanged(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: UiSiteEditorLabeledField(
                          label: 'Prefix',
                          child: TextField(
                            controller: _prefix,
                            enabled: !widget.busy,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [LengthLimitingTextInputFormatter(6)],
                            decoration: siteEditorInputDecoration(hintText: 'A'),
                            onChanged: (_) => _onFieldChanged(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  UiSiteEditorSwitchRow(
                    label: 'Take numbers online',
                    value: _meta.takeOnline,
                    onChanged: widget.busy
                        ? null
                        : (v) {
                            setState(() => _meta = _meta.copyWith(takeOnline: v));
                            _onFieldChanged();
                          },
                  ),
                  UiSiteEditorSwitchRow(
                    label: 'Reset ticket numbers daily',
                    value: _meta.resetDaily,
                    onChanged: widget.busy
                        ? null
                        : (v) {
                            setState(() => _meta = _meta.copyWith(resetDaily: v));
                            _onFieldChanged();
                          },
                  ),
                  UiSiteEditorFormSection(
                    title: 'Guest fields',
                    children: [
                      if (_fields.isEmpty)
                        const Text(
                          'No extra fields. Guests only get a ticket number.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        )
                      else
                        ...List.generate(_fields.length, (i) => _fieldEditor(i)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: widget.busy ? null : _addField,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add field'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              UiSiteQueueOperator(
                api: widget.api,
                siteIid: widget.siteIid,
                queue: q,
                onQueueRowChanged: widget.onSaved,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldEditor(int index) {
    final row = _fields[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.label,
              enabled: !widget.busy,
              decoration: siteEditorInputDecoration(hintText: 'Label'),
              onChanged: (_) => _onFieldChanged(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: row.type,
              decoration: siteEditorInputDecoration(),
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Text', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'phone', child: Text('Phone', style: TextStyle(fontSize: 13))),
              ],
              onChanged: widget.busy
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => row.type = v);
                      _onFieldChanged();
                    },
            ),
          ),
          Checkbox(
            value: row.required,
            onChanged: widget.busy
                ? null
                : (v) {
                    setState(() => row.required = v ?? false);
                    _onFieldChanged();
                  },
          ),
          const Text('Req.', style: TextStyle(color: _muted, fontSize: 11)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: widget.busy ? null : () => _removeField(index),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FieldRow {
  _FieldRow({required this.id, required this.label, this.type = 'text', this.required = false});

  final String id;
  final TextEditingController label;
  String type;
  bool required;
}
