import 'dart:convert';

import 'package:alienai_c35/c/bot/data_source_api.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/data_source.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);
const _accent = Color(0xFF34D399);
const _panelBg = Color(0xFF18181B);

class BotAssetDraft {
  const BotAssetDraft({required this.sourceKind, required this.name, required this.configJson, this.dataSourceId});

  final String sourceKind;
  final String name;
  final String configJson;
  final int? dataSourceId;

  String get viewUrl {
    try {
      final m = jsonDecode(configJson) as Map<String, dynamic>;
      return m['view_url']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  bool get readWrite {
    try {
      final m = jsonDecode(configJson) as Map<String, dynamic>;
      return m['access_mode']?.toString() != 'read_only';
    } catch (_) {
      return true;
    }
  }

  String get accessLabel => readWrite ? 'Read & write' : 'Read only';

  List<String> get includedSheetNames {
    if (sourceKind != 'google_sheet') return const [];
    try {
      final m = jsonDecode(configJson) as Map<String, dynamic>;
      if (m['sync_scope']?.toString() == 'tabs') {
        final tabs = m['tabs'];
        if (tabs is List) {
          return tabs
              .map((t) => t is Map ? t['sheet_name']?.toString().trim() ?? '' : '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
      final single = m['sheet_name']?.toString().trim() ?? '';
      if (single.isNotEmpty) return [single];
    } catch (_) {}
    return const [];
  }
}

enum GoogleAssetConnectKind {
  sheet('google_sheet', 'Google Sheet', 'Sheet URL', 'https://docs.google.com/spreadsheets/d/...'),
  doc('google_doc', 'Google Docs', 'Document URL', 'https://docs.google.com/document/d/...'),
  slide('google_slide', 'Google Slides', 'Presentation URL', 'https://docs.google.com/presentation/d/...');

  const GoogleAssetConnectKind(this.sourceKind, this.dialogTitle, this.urlLabel, this.urlHint);

  final String sourceKind;
  final String dialogTitle;
  final String urlLabel;
  final String urlHint;
}

GoogleAssetConnectKind? googleAssetConnectKindFromPickId(String id) => switch (id) {
      'google_sheets' => GoogleAssetConnectKind.sheet,
      'google_docs' => GoogleAssetConnectKind.doc,
      'google_slides' => GoogleAssetConnectKind.slide,
      _ => null,
    };

bool _isPlaceholderTabTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) return true;
  final lower = t.toLowerCase();
  if (lower.startsWith('tab (gid')) return true;
  if (lower.startsWith('sheet (gid')) return true;
  if (lower.startsWith('gid ')) return true;
  if (lower == 'sheet') return true;
  return false;
}

String sheetTabName(DataSourceSheetTab tab, int index) {
  final title = tab.title.trim();
  if (title.isNotEmpty && !_isPlaceholderTabTitle(title)) return title;
  return 'Sheet ${index + 1}';
}

String sheetTabPrimaryTitle(DataSourceSheetTab tab, int index) => sheetTabName(tab, index);

String? sheetTabSubtitle(DataSourceSheetTab tab, int index) {
  final title = tab.title.trim();
  if (title.isNotEmpty && !_isPlaceholderTabTitle(title)) return 'Sheet ${index + 1}';
  return null;
}

String _sheetNameForGid(List<DataSourceSheetTab> tabs, String gid) {
  for (var i = 0; i < tabs.length; i++) {
    if (tabs[i].gid == gid) return sheetTabName(tabs[i], i);
  }
  throw StateError('Sheet tab no longer exists (gid $gid)');
}

BotAssetDraft botAssetDraftMergeCheck(BotAssetDraft asset, ResDataSourceCheck res) {
  final config = Map<String, dynamic>.from(jsonDecode(asset.configJson) as Map);
  if (res.configJson.isNotEmpty) {
    final checkCfg = jsonDecode(res.configJson) as Map<String, dynamic>;
    for (final k in ['spreadsheet_id', 'view_url']) {
      final v = checkCfg[k];
      if (v != null) config[k] = v;
    }
  }
  if (asset.sourceKind == 'google_sheet') {
    if (config['sync_scope']?.toString() == 'tabs') {
      final rawTabs = config['tabs'];
      if (rawTabs is List) {
        config['tabs'] = [
          for (final raw in rawTabs)
            if (raw is Map && raw['gid'] != null)
              {'gid': '${raw['gid']}', 'sheet_name': _sheetNameForGid(res.tabs, '${raw['gid']}')},
        ];
      }
    } else {
      final gid = '${config['gid'] ?? ''}'.trim();
      if (gid.isNotEmpty) config['sheet_name'] = _sheetNameForGid(res.tabs, gid);
    }
  }
  final title = res.title.trim();
  return BotAssetDraft(
    sourceKind: asset.sourceKind,
    name: title.isNotEmpty ? title : asset.name,
    configJson: jsonEncode(config),
    dataSourceId: asset.dataSourceId,
  );
}

Future<BotAssetDraft> botAssetDraftRefresh(ChatConn conn, BotAssetDraft asset) async {
  final url = asset.viewUrl.trim();
  if (url.isEmpty) throw StateError('Missing asset URL');
  final res = await dataSourceCheck(conn, sourceKind: asset.sourceKind, viewUrl: url);
  if (!res.ok) throw StateError(res.errorMsg.isNotEmpty ? res.errorMsg : 'Refresh failed');
  return botAssetDraftMergeCheck(asset, res);
}

Future<BotAssetDraft?> ioGoogleAssetConnectShow(
  BuildContext context, {
  required ChatConn conn,
  required GoogleAssetConnectKind kind,
}) =>
    showDialog<BotAssetDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IoGoogleAssetConnectDialog(conn: conn, kind: kind),
    );

class _IoGoogleAssetConnectDialog extends StatefulWidget {
  const _IoGoogleAssetConnectDialog({required this.conn, required this.kind});

  final ChatConn conn;
  final GoogleAssetConnectKind kind;

  @override
  State<_IoGoogleAssetConnectDialog> createState() => _IoGoogleAssetConnectDialogState();
}

class _IoGoogleAssetConnectDialogState extends State<_IoGoogleAssetConnectDialog> {
  late final _url = TextEditingController();
  late final _name = TextEditingController();
  var _busy = false;
  var _checked = false;
  var _readWrite = true;
  String? _error;
  String _baseConfigJson = '{}';
  List<DataSourceSheetTab> _tabs = [];
  final _selectedTabGids = <String>{};

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _check({bool refresh = false}) async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'URL is required');
      return;
    }
    final prevGids = refresh ? _selectedTabGids.toSet() : <String>{};
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await dataSourceCheck(widget.conn, sourceKind: widget.kind.sourceKind, viewUrl: url);
      if (!res.ok) {
        setState(() {
          _busy = false;
          _error = res.errorMsg.isNotEmpty ? res.errorMsg : 'Check failed';
        });
        return;
      }
      setState(() {
        _busy = false;
        _checked = true;
        _name.text = res.title;
        _baseConfigJson = res.configJson.isNotEmpty ? res.configJson : jsonEncode({'view_url': url});
        _tabs = res.tabs;
        _selectedTabGids
          ..clear()
          ..addAll(
            refresh
                ? res.tabs.where((t) => prevGids.contains(t.gid)).map((t) => t.gid)
                : (res.tabs.isNotEmpty ? {res.tabs.first.gid} : const <String>{}),
          );
        if (_selectedTabGids.isEmpty && res.tabs.isNotEmpty) {
          _selectedTabGids.add(res.tabs.first.gid);
        }
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refresh() => _check(refresh: true);

  void _add() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    final config = Map<String, dynamic>.from(jsonDecode(_baseConfigJson) as Map);
    if (widget.kind == GoogleAssetConnectKind.sheet) {
      if (_selectedTabGids.isEmpty) {
        setState(() => _error = 'Select at least one sheet');
        return;
      }
      final picked = _tabs.asMap().entries.where((e) => _selectedTabGids.contains(e.value.gid)).toList();
      if (picked.length == 1) {
        final tab = picked.first.value;
        final idx = picked.first.key;
        config['sync_scope'] = 'tab';
        config['gid'] = tab.gid;
        config['sheet_name'] = sheetTabName(tab, idx);
      } else {
        config['sync_scope'] = 'tabs';
        config['tabs'] = picked
            .map((e) => {'gid': e.value.gid, 'sheet_name': sheetTabName(e.value, e.key)})
            .toList();
        config['gid'] = picked.first.value.gid;
        config['sheet_name'] = sheetTabName(picked.first.value, picked.first.key);
      }
    } else {
      config['sync_scope'] = 'all';
    }
    config['access_mode'] =
        widget.kind == GoogleAssetConnectKind.sheet && _readWrite ? 'read_write' : 'read_only';
    Navigator.pop(
      context,
      BotAssetDraft(sourceKind: widget.kind.sourceKind, name: name, configJson: jsonEncode(config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSheet = widget.kind == GoogleAssetConnectKind.sheet;
    final headerName = _name.text.trim();
    final headerTitle = _checked && headerName.isNotEmpty ? headerName : widget.kind.dialogTitle;
    return Dialog(
      backgroundColor: _panelBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(headerTitle, style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  uiIconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _muted, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _url,
                enabled: !_busy,
                style: const TextStyle(color: _title, fontSize: 13),
                decoration: UiInputDecoration.of(
                  context,
                  labelText: widget.kind.urlLabel,
                  hintText: widget.kind.urlHint,
                  floatingLabel: true,
                  suffixIcon: _checked
                      ? uiIconButton(
                          tooltip: 'Refresh',
                          visualDensity: VisualDensity.compact,
                          onPressed: _busy ? null : _refresh,
                          icon: _busy
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _muted.withValues(alpha: 0.9)),
                                )
                              : const Icon(Icons.refresh, color: _muted, size: 20),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
              if (_checked) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  readOnly: true,
                  style: const TextStyle(color: _title, fontSize: 13),
                  decoration: UiInputDecoration.of(context, labelText: 'Name', floatingLabel: true),
                ),
                if (isSheet) ...[
                  const SizedBox(height: 12),
                  Text('Access', style: TextStyle(color: _muted.withValues(alpha: 0.95), fontSize: 12)),
                  const SizedBox(height: 6),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Read & write')),
                      ButtonSegment(value: false, label: Text('Read only')),
                    ],
                    selected: {_readWrite},
                    onSelectionChanged: _busy ? null : (s) => setState(() => _readWrite = s.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected) ? _title : _muted,
                      ),
                    ),
                  ),
                ],
                if (isSheet && _tabs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('botCreate.sheetsLabel'.tr(), style: TextStyle(color: _muted.withValues(alpha: 0.95), fontSize: 12)),
                  const SizedBox(height: 4),
                  ..._tabs.asMap().entries.map((e) {
                    final subtitle = sheetTabSubtitle(e.value, e.key);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF34A853), size: 22),
                      title: Text(
                        sheetTabPrimaryTitle(e.value, e.key),
                        style: const TextStyle(color: _title, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      subtitle: subtitle == null
                          ? null
                          : Text(subtitle, style: TextStyle(color: _muted.withValues(alpha: 0.9), fontSize: 11)),
                      trailing: Checkbox(
                        activeColor: _accent,
                        value: _selectedTabGids.contains(e.value.gid),
                        onChanged: _busy
                            ? null
                            : (on) => setState(() {
                                  if (on == true) {
                                    _selectedTabGids.add(e.value.gid);
                                  } else {
                                    _selectedTabGids.remove(e.value.gid);
                                  }
                                }),
                      ),
                      onTap: _busy
                          ? null
                          : () => setState(() {
                                if (_selectedTabGids.contains(e.value.gid)) {
                                  _selectedTabGids.remove(e.value.gid);
                                } else {
                                  _selectedTabGids.add(e.value.gid);
                                }
                              }),
                    );
                  }),
                ],
              ],
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _busy ? null : (_checked ? _add : _check),
                  style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
                  child: Text(_busy ? 'Checking...' : _checked ? 'Add' : 'Check'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}