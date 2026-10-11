import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/widgets/bots/io_google_asset_connect.dart';
import 'package:alienai_c35/widgets/sites/in_site_create.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const botSiteAssetSourceKind = 'alien_site';

const _border = Color(0xFF27272A);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);
const _accent = Color(0xFF34D399);
const _panelBg = Color(0xFF18181B);

const _capAnswerProducts = 'answer_product_questions';
const _capTakeOrders = 'take_orders';
const _capShareOrderStatus = 'share_order_status';

bool botAssetDraftIsSite(BotAssetDraft asset) => asset.sourceKind == botSiteAssetSourceKind;

int? botSiteAssetSiteIid(BotAssetDraft asset) {
  if (!botAssetDraftIsSite(asset)) return null;
  try {
    final m = jsonDecode(asset.configJson) as Map<String, dynamic>;
    final raw = m['site_iid'];
    if (raw is int) return raw > 0 ? raw : null;
    if (raw is num) return raw.toInt() > 0 ? raw.toInt() : null;
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    return int.tryParse(s);
  } catch (_) {
    return null;
  }
}

bool _capFromConfig(Map<String, dynamic> m, String key) => m[key] as bool? ?? true;

List<String> botSiteAssetCapabilityLabels(BotAssetDraft asset) {
  if (!botAssetDraftIsSite(asset)) return const [];
  try {
    final m = jsonDecode(asset.configJson) as Map<String, dynamic>;
    final out = <String>[];
    if (_capFromConfig(m, _capAnswerProducts)) out.add('botCreate.siteCapAnswerProducts'.tr());
    if (_capFromConfig(m, _capTakeOrders)) out.add('botCreate.siteCapTakeOrders'.tr());
    if (_capFromConfig(m, _capShareOrderStatus)) out.add('botCreate.siteCapShareOrderStatus'.tr());
    return out;
  } catch (_) {
    return const [];
  }
}

String botSiteAssetConfigJson({
  required int siteIid,
  required bool answerProductQuestions,
  required bool takeOrders,
  required bool shareOrderStatus,
}) =>
    jsonEncode({
      'site_iid': siteIid,
      _capAnswerProducts: answerProductQuestions,
      _capTakeOrders: takeOrders,
      _capShareOrderStatus: shareOrderStatus,
    });

Future<void> ioBotSiteNeedSiteShow(BuildContext context, {required ChatConn conn}) async {
  final store = SiteStore(conn: conn);
  await uiDialogShow<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _panelBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
      title: Text('botCreate.siteNeedTitle'.tr(), style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w600)),
      content: Text('botCreate.siteNeedMessage'.tr(), style: const TextStyle(color: _muted, fontSize: 13, height: 1.45)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.cancel'.tr(), style: const TextStyle(color: _muted))),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            if (!context.mounted) return;
            final created = await inSiteCreateShow(context, store: store);
            if (created != null) await store.refresh();
          },
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
          child: Text('botCreate.siteNeedAdd'.tr()),
        ),
      ],
    ),
  );
}

Future<BotAssetDraft?> ioBotSiteAssetConnectShow(
  BuildContext context, {
  required ChatConn conn,
  BotAssetDraft? initial,
}) =>
    uiDialogShow<BotAssetDraft>(
      context: context,
      builder: (_) => _IoBotSiteAssetConnectDialog(conn: conn, initial: initial),
    );

class _IoBotSiteAssetConnectDialog extends StatefulWidget {
  const _IoBotSiteAssetConnectDialog({required this.conn, this.initial});

  final ChatConn conn;
  final BotAssetDraft? initial;

  @override
  State<_IoBotSiteAssetConnectDialog> createState() => _IoBotSiteAssetConnectDialogState();
}

class _IoBotSiteAssetConnectDialogState extends State<_IoBotSiteAssetConnectDialog> {
  var _loading = true;
  var _busy = false;
  String? _error;
  List<SiteRow> _sites = [];
  int? _selectedSiteIid;
  var _answerProducts = true;
  var _takeOrders = true;
  var _shareOrderStatus = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null && botAssetDraftIsSite(initial)) {
      _selectedSiteIid = botSiteAssetSiteIid(initial);
      try {
        final m = jsonDecode(initial.configJson) as Map<String, dynamic>;
        _answerProducts = _capFromConfig(m, _capAnswerProducts);
        _takeOrders = _capFromConfig(m, _capTakeOrders);
        _shareOrderStatus = _capFromConfig(m, _capShareOrderStatus);
      } catch (_) {}
    }
    unawaited(_loadSites());
  }

  Future<void> _loadSites() async {
    try {
      final sites = await siteListFetch(widget.conn);
      final active = sites.where((s) => !s.isArchived).toList();
      if (!mounted) return;
      setState(() {
        _sites = active;
        _loading = false;
        if (_selectedSiteIid == null && active.isNotEmpty) {
          _selectedSiteIid = active.first.siteIid.toInt();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  SiteRow? _selectedSite() {
    final id = _selectedSiteIid;
    if (id == null) return null;
    for (final s in _sites) {
      if (s.siteIid.toInt() == id) return s;
    }
    return null;
  }

  void _save() {
    final site = _selectedSite();
    if (site == null) {
      setState(() => _error = 'botCreate.sitePickRequired'.tr());
      return;
    }
    final siteIid = site.siteIid.toInt();
    final name = site.name.isNotEmpty ? site.name : site.alienId;
    final initial = widget.initial;
    Navigator.pop(
      context,
      BotAssetDraft(
        sourceKind: botSiteAssetSourceKind,
        name: name,
        configJson: botSiteAssetConfigJson(
          siteIid: siteIid,
          answerProductQuestions: _answerProducts,
          takeOrders: _takeOrders,
          shareOrderStatus: _shareOrderStatus,
        ),
        dataSourceId: initial?.dataSourceId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Dialog(
      backgroundColor: _panelBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiDialogHeader(title: 'botCreate.siteConnectTitle'.tr(), closeEnabled: !_busy),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: UILoading())
              else ...[
                Text('botCreate.sitePickLabel'.tr(), style: TextStyle(color: _muted.withValues(alpha: 0.95), fontSize: 12)),
                const SizedBox(height: 6),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _sites.length,
                    itemBuilder: (context, i) {
                      final row = _sites[i];
                      final id = row.siteIid.toInt();
                      final label = row.name.isNotEmpty ? row.name : row.alienId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: UiUserAvatar(name: label, pic: row.pic, size: 32),
                        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: row.alienId.isNotEmpty && row.name.isNotEmpty
                            ? Text(row.alienId, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted.withValues(alpha: 0.9), fontSize: 11))
                            : null,
                        trailing: Radio<int>(
                          value: id,
                          groupValue: _selectedSiteIid,
                          activeColor: _accent,
                          onChanged: _busy ? null : (v) => setState(() => _selectedSiteIid = v),
                        ),
                        onTap: _busy ? null : () => setState(() => _selectedSiteIid = id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text('botCreate.siteCapabilitiesLabel'.tr(), style: TextStyle(color: _muted.withValues(alpha: 0.95), fontSize: 12)),
                const SizedBox(height: 4),
                _capTile('botCreate.siteCapAnswerProducts'.tr(), _answerProducts, (v) => _answerProducts = v),
                _capTile('botCreate.siteCapTakeOrders'.tr(), _takeOrders, (v) => _takeOrders = v),
                _capTile('botCreate.siteCapShareOrderStatus'.tr(), _shareOrderStatus, (v) => _shareOrderStatus = v),
              ],
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _loading || _busy || _sites.isEmpty ? null : _save,
                  style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
                  child: Text(editing ? 'common.save'.tr() : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _capTile(String label, bool value, ValueChanged<bool> onChanged) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeColor: _accent,
        title: Text(label, style: const TextStyle(color: _title, fontSize: 13)),
        value: value,
        onChanged: _busy ? null : (v) => setState(() => onChanged(v ?? false)),
        controlAffinity: ListTileControlAffinity.leading,
      );
}
