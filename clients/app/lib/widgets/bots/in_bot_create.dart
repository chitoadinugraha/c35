import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/bot/bot_billing_catalog.dart';
import 'package:alienai_c35/c/bot/bot_api.dart';
import 'package:alienai_c35/c/bot/bot_meta.dart';
import 'package:alienai_c35/c/bot/data_source_api.dart';
import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/channel/channel_api.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:alienai_c35/widgets/bots/io_bot_package_pick.dart';
import 'package:alienai_c35/widgets/bots/io_channel_pick_grid.dart';
import 'package:alienai_c35/widgets/bots/io_google_asset_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_telegram_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_meta_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_pair.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);
const _dialogW = 400.0;
const _dialogH = 580.0;
const _stepTotal = 4;

class InBotCreateResult {
  const InBotCreateResult({required this.botIid, required this.name});

  final int botIid;
  final String name;
}

typedef IdentityPutFn = Future<ResIdentityPut> Function(ReqIdentityPut req);
typedef IdentityDeleteFn = Future<void> Function(int iid);

Future<InBotCreateResult?> inBotCreateShow(
  BuildContext context, {
  required BotStore store,
  int? editBotIid,
  IdentityPutFn? onIdentityPut,
  IdentityDeleteFn? onIdentityDelete,
  ChannelDisconnectFn? onChannelDisconnect,
  ChannelTelegramConnectFn? onTelegramConnect,
  ChannelWhatsappMetaConnectFn? onWhatsappMetaConnect,
  ChannelWhatsappPairStartFn? onWhatsappPairStart,
  ChannelWhatsappPairWatchFn? onWhatsappPairWatch,
  ChannelWhatsappPairAbortFn? onWhatsappPairAbort,
}) {
  final conn = store.conn;
  return showDialog<InBotCreateResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => InBotCreate(
      store: store,
      editBotIid: editBotIid,
      onIdentityPut: onIdentityPut ?? ((ReqIdentityPut req) => identityPut(conn, req)),
      onIdentityDelete: onIdentityDelete ?? ((int iid) => identityDelete(conn, iid)),
      onChannelDisconnect: onChannelDisconnect ?? channelDisconnectFn(conn),
      onTelegramConnect: onTelegramConnect ?? channelTelegramConnectFn(conn),
      onWhatsappMetaConnect: onWhatsappMetaConnect ?? channelWhatsappMetaConnectFn(conn),
      onWhatsappPairStart: onWhatsappPairStart ?? channelWhatsappPairStartFn(conn),
      onWhatsappPairWatch: onWhatsappPairWatch ?? channelWhatsappPairWatchFn(conn),
      onWhatsappPairAbort: onWhatsappPairAbort ?? channelWhatsappPairAbortFn(conn),
    ),
  );
}

class InBotCreate extends StatefulWidget {
  const InBotCreate({
    super.key,
    required this.store,
    this.editBotIid,
    required this.onIdentityPut,
    required this.onIdentityDelete,
    required this.onChannelDisconnect,
    required this.onTelegramConnect,
    required this.onWhatsappMetaConnect,
    required this.onWhatsappPairStart,
    required this.onWhatsappPairWatch,
    required this.onWhatsappPairAbort,
  });

  final BotStore store;
  final int? editBotIid;
  final IdentityPutFn onIdentityPut;
  final IdentityDeleteFn onIdentityDelete;
  final ChannelDisconnectFn onChannelDisconnect;
  final ChannelTelegramConnectFn onTelegramConnect;
  final ChannelWhatsappMetaConnectFn onWhatsappMetaConnect;
  final ChannelWhatsappPairStartFn onWhatsappPairStart;
  final ChannelWhatsappPairWatchFn onWhatsappPairWatch;
  final ChannelWhatsappPairAbortFn onWhatsappPairAbort;

  @override
  State<InBotCreate> createState() => _InBotCreateState();
}

class _InBotCreateState extends State<InBotCreate> {
  late final _name = TextEditingController();
  late final _instructions = TextEditingController();
  late final _welcomeMessage = TextEditingController();
  late final _bodyScrollCtrl = ScrollController();
  var _step = 0;
  var _saving = false;
  var _pic = '';
  String? _error;
  int? _botIid;
  final _channels = <BotChannelDoc>[];
  final _assetDrafts = <BotAssetDraft>[];
  var _strictMode = true;
  var _autoBlockSpammer = true;
  var _webSearch = false;
  BotBillingPackage? _billingPackage;
  var _billingYearly = true;
  var _botPlans = <BillingPlanDoc>[];
  var _isEdit = false;
  var _hydrating = false;
  int? _planExpiresTsMs;
  final _initialDataSourceIds = <int>{};
  final _initialAssetFingerprints = <int, String>{};
  var _step0SavedFingerprint = '';

  String _step0Fingerprint() =>
      '${_name.text.trim()}\u0000$_pic\u0000${_billingPackage?.slug ?? ''}\u0000$_billingYearly';

  bool get _step0Changed => _step0Fingerprint() != _step0SavedFingerprint;

  void _markStep0Saved() => _step0SavedFingerprint = _step0Fingerprint();

  String _assetFingerprint(BotAssetDraft a) => '${a.sourceKind}\u0000${a.name}\u0000${a.configJson}';

  bool _assetDraftNeedsSave(BotAssetDraft a) {
    if (!_isEditing) return true;
    final id = a.dataSourceId ?? 0;
    if (id <= 0) return true;
    return _initialAssetFingerprints[id] != _assetFingerprint(a);
  }

  bool get _isEditing => _isEdit || widget.editBotIid != null;

  BotBillingPackage _packageFromSlug(String? slug) {
    for (final p in BotBillingPackage.values) {
      if (p.slug == slug) return p;
    }
    return BotBillingPackage.shared;
  }

  bool _activeFromStore() {
    final iid = _botIid;
    if (iid == null) return true;
    return botActiveFromMetaJson(widget.store.botById(iid.toString())?.identity.metaJson ?? '{}');
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadBotPlans());
    final editId = widget.editBotIid;
    if (editId != null && editId > 0) {
      _botIid = editId;
      _isEdit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_hydrateFromExisting(editId));
      });
    }
  }

  Future<IdentityListRow?> _editBotRow(int iid) async {
    final cached = widget.store.botById(iid.toString());
    if (cached != null) return cached;
    await widget.store.ensureConnected();
    final res = await identityList(widget.store.conn, const ['bot']);
    for (final row in res.rows) {
      if (row.identity.iid.toInt() == iid) return row;
    }
    return null;
  }

  Future<void> _hydrateFromExisting(int iid) async {
    setState(() => _hydrating = true);
    try {
      final row = await _editBotRow(iid);
      if (row == null) return;
      final id = row.identity;
      Map<String, dynamic> meta = {};
      try {
        final decoded = jsonDecode(id.metaJson.isNotEmpty ? id.metaJson : '{}');
        if (decoded is Map<String, dynamic>) meta = decoded;
      } catch (_) {}
      _name.text = id.name;
      _pic = id.pic;
      _instructions.text = '${meta['inst_base'] ?? ''}';
      _welcomeMessage.text = '${meta['welcome_message'] ?? ''}';
      _strictMode = meta['strict_mode'] as bool? ?? true;
      _autoBlockSpammer = meta['auto_block_spammer'] as bool? ?? true;
      _webSearch = meta['web_search'] as bool? ?? false;
      _billingPackage = _packageFromSlug(meta['billing_plan_slug']?.toString());
      _billingYearly = meta['billing_period']?.toString() != 'monthly';
      final exp = meta['billing_expires_ts_ms'];
      if (exp is num && exp.toInt() > 0) _planExpiresTsMs = exp.toInt();
      _channels
        ..clear()
        ..addAll(botChannelsParse(id.metaJson).where(channelIsActive));
      final ds = await dataSourceList(widget.store.conn, botIid: iid);
      _assetDrafts.clear();
      _initialDataSourceIds.clear();
      for (final doc in ds.items) {
        final dsId = doc.id.toInt();
        if (dsId > 0) _initialDataSourceIds.add(dsId);
        _assetDrafts.add(BotAssetDraft(sourceKind: doc.sourceKind, name: doc.name, configJson: doc.configJson, dataSourceId: dsId > 0 ? dsId : null));
      }
      _initialAssetFingerprints.clear();
      for (final d in _assetDrafts) {
        final id = d.dataSourceId;
        if (id != null && id > 0) _initialAssetFingerprints[id] = _assetFingerprint(d);
      }
      if (mounted) setState(() {});
      _markStep0Saved();
    } catch (e) {
      lError('bot edit hydrate: $e');
    } finally {
      if (mounted) setState(() => _hydrating = false);
    }
  }

  Future<void> _loadBotPlans() async {
    try {
      final plans = await botBillingCatalogLoad(widget.store.conn);
      if (!mounted) return;
      setState(() => _botPlans = plans);
    } catch (e) {
      lError(e);
    }
  }

  bool get _welcomeFieldEditable => _billingPackage == null || !_billingPackage!.usesOwnerQuota;

  bool get _welcomeSavedToMeta => _billingPackage != null && !_billingPackage!.usesOwnerQuota;


  String _botMetaJson({required bool active}) {
    final map = <String, dynamic>{
      'inst_base': _instructions.text.trim(),
      'strict_mode': _strictMode,
      'auto_block_spammer': _strictMode && _autoBlockSpammer,
      'web_search': _webSearch,
      'billing_plan_slug': _billingPackage!.slug,
      'billing_period': _billingYearly ? 'yearly' : 'monthly',
      'active': active,
    };
    if (_welcomeSavedToMeta) {
      map['welcome_message'] = _welcomeMessage.text.trim();
    }
    return jsonEncode(map);
  }

  ReqIdentityPut _step0PutReq({required bool active, int? iid}) {
    final req = ReqIdentityPut(kind: 'bot', type: 'chat', name: _name.text.trim(), pic: _pic, metaJson: _botMetaJson(active: active));
    if (iid != null && iid > 0) req.iid = Int64(iid);
    return req;
  }

  Future<void> _saveStep0Basics() async {
    final iid = _botIid;
    if (iid == null || iid <= 0) throw StateError('bot iid missing');
    await widget.onIdentityPut(_step0PutReq(active: _activeFromStore(), iid: iid));
  }

  Future<void> _pickPic() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = picked?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    setState(() => _pic = 'local://${file.name}');
  }

  @override
  void dispose() {
    _name.dispose();
    _instructions.dispose();
    _welcomeMessage.dispose();
    _bodyScrollCtrl.dispose();
    super.dispose();
  }

  String get _stepTitle => switch (_step) {
        0 => _isEditing ? 'botCreate.editTitle'.tr() : 'New Chat Bot',
        1 => 'botCreate.stepChannels'.tr(),
        2 => 'botCreate.stepAssets'.tr(),
        _ => 'botCreate.stepBehavior'.tr(),
      };

  String _stepMenuLabel(int index) => switch (index) {
        0 => 'botCreate.stepInfo'.tr(),
        1 => 'botCreate.stepChannels'.tr(),
        2 => 'botCreate.stepAssets'.tr(),
        _ => 'botCreate.stepBehavior'.tr(),
      };

  bool get _canStepForward =>
      _step == 0 ? _name.text.trim().isNotEmpty && _billingPackage != null : true;

  bool _canGoToStep(int target) {
    if (target == _step) return false;
    if (target == 0) return true;
    if (_botIid == null) return false;
    if (_name.text.trim().isEmpty || _billingPackage == null) return false;
    return true;
  }

  void _goToStep(int target) {
    if (!_canGoToStep(target)) return;
    setState(() {
      _step = target;
      _error = null;
    });
  }

  Future<void> _cancel() async {
    if (_saving) return;
    final hadBot = _botIid != null;
    if (hadBot) unawaited(widget.store.refreshBots());
    if (!mounted) return;
    if (hadBot && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('botCreate.savedDraftHint'.tr())));
    }
    Navigator.pop(context);
  }

  Future<void> _next() async {
    if (_step == 0) {
      final name = _name.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'Name is required');
        return;
      }
      if (_billingPackage == null) {
        setState(() => _error = 'botCreate.packageRequired'.tr());
        return;
      }
      setState(() {
        _error = null;
        _saving = true;
      });
      try {
        if (_botIid != null && !_step0Changed) {
          if (!mounted) return;
          setState(() {
            _step = 1;
            _saving = false;
          });
          return;
        }
        if (_isEditing && _botIid != null) {
          await _saveStep0Basics();
          _markStep0Saved();
          if (!mounted) return;
          setState(() {
            _step = 1;
            _saving = false;
          });
          return;
        }
        final res = await widget.onIdentityPut(_step0PutReq(active: false));
        if (!res.hasRow()) throw StateError('empty identity put response');
        final iid = res.row.identity.iid.toInt();
        if (iid <= 0) throw StateError('invalid bot iid');
        if (!mounted) return;
        setState(() {
          _botIid = iid;
          _step = 1;
          _saving = false;
        });
        _markStep0Saved();
      } catch (e) {
        lError('bot wizard step0: $e');
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = _isEditing ? 'botCreate.saveFailed'.tr() : 'botCreate.createFailed'.tr();
        });
      }
      return;
    }
    if (_step == 1 || _step == 2) {
      setState(() {
        _error = null;
        _step += 1;
      });
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step == 0) {
      _cancel();
      return;
    }
    setState(() {
      _step -= 1;
      _error = null;
    });
  }

  Future<void> _finish() async {
    final iid = _botIid;
    if (iid == null) return;
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.store.ensureConnected();
      final active = _isEditing ? _activeFromStore() : true;
      final meta = _botMetaJson(active: active);
      await widget.onIdentityPut(ReqIdentityPut(iid: Int64(iid), kind: 'bot', type: 'chat', name: _name.text.trim(), pic: _pic, metaJson: meta));
      final conn = widget.store.conn;
      if (_isEditing) {
        final kept = _assetDrafts.map((a) => a.dataSourceId).whereType<int>().toSet();
        for (final id in _initialDataSourceIds) {
          if (!kept.contains(id)) {
            try {
              await dataSourceDelete(conn, id);
            } catch (e) {
              lError('bot edit asset delete $id: $e');
            }
          }
        }
      }
      for (final asset in _assetDrafts) {
        if (!_assetDraftNeedsSave(asset)) continue;
        final put = await dataSourcePut(
          conn,
          botIid: iid,
          sourceKind: asset.sourceKind,
          name: asset.name,
          configJson: asset.configJson,
          id: asset.dataSourceId ?? 0,
        );
        final dsId = put.id.toInt();
        if (dsId > 0 && asset.sourceKind == 'google_sheet') {
          try {
            await dataSourceSync(conn, dsId);
          } catch (e) {
            lError('bot create asset sync $dsId: $e');
          }
        }
      }
      if (!mounted) return;
      Navigator.pop(context, InBotCreateResult(botIid: iid, name: _name.text.trim()));
    } catch (e) {
      lError('bot create finish: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'botCreate.saveFailed'.tr();
      });
    }
  }

  void _upsertChannel(BotChannelDoc channel) {
    final key = channelExternalKey(channel);
    final i = _channels.indexWhere((c) => channelExternalKey(c) == key);
    if (i >= 0) {
      _channels[i] = channel;
    } else {
      _channels.add(channel);
    }
  }

  Future<void> _onPick(ChannelPickKind kind) async {
    final botIid = _botIid;
    if (botIid == null) return;
    BotChannelDoc? channel;
    switch (kind) {
      case ChannelPickKind.telegram:
        channel = await ioChannelTelegramConnectShow(context, botIid: botIid, onConnect: widget.onTelegramConnect);
      case ChannelPickKind.whatsappMeta:
        final res = await ioChannelWhatsappMetaConnectShow(context, botIid: botIid, onConnect: widget.onWhatsappMetaConnect);
        channel = res?.channel;
      case ChannelPickKind.whatsappPair:
        channel = await ioChannelWhatsappPairShow(
          context,
          botIid: botIid,
          onStart: widget.onWhatsappPairStart,
          onWatch: widget.onWhatsappPairWatch,
          onAbort: widget.onWhatsappPairAbort,
        );
    }
    if (!mounted || channel == null) return;
    final key = channelExternalKey(channel);
    if (_channels.any((c) => channelExternalKey(c) == key && c.id != channel!.id && channelIsActive(c))) {
      setState(() => _error = 'This channel is already connected to this bot');
      return;
    }
    setState(() {
      _error = null;
      _upsertChannel(channel!);
    });
  }

  Future<void> _removeChannel(BotChannelDoc channel) async {
    final botIid = _botIid;
    if (botIid == null || channel.id.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onChannelDisconnect(botIid: botIid, channelId: channel.id);
      if (!mounted) return;
      setState(() {
        _channels.removeWhere((c) => c.id == channel.id);
        _saving = false;
      });
    } catch (e) {
      lError('bot create remove channel: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not remove channel';
      });
    }
  }

  Widget _stepNav() {
    final backEnabled = !_saving && !_hydrating && _step > 0;
    final forwardEnabled = !_saving && !_hydrating && _canStepForward && _step < _stepTotal - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        uiIconButton(
          tooltip: 'Previous step',
          visualDensity: VisualDensity.compact,
          onPressed: backEnabled ? _back : null,
          icon: Icon(Icons.chevron_left, size: 20, color: backEnabled ? _muted : _muted.withValues(alpha: 0.35)),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<int>(
          enabled: !_saving && !_hydrating,
          tooltip: 'Go to step',
          offset: const Offset(0, 28),
          color: const Color(0xFF27272A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: _border)),
          onSelected: _goToStep,
          itemBuilder: (ctx) => List.generate(
            _stepTotal,
            (i) => PopupMenuItem<int>(
              value: i,
              enabled: _canGoToStep(i),
              height: 40,
              child: Text(
                'Step ${i + 1} - ${_stepMenuLabel(i)}',
                style: TextStyle(
                  color: i == _step ? const Color(0xFF34D399) : _title,
                  fontSize: 13,
                  fontWeight: i == _step ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text('Step ${_step + 1} / $_stepTotal', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 4),
        uiIconButton(
          tooltip: 'Next step',
          visualDensity: VisualDensity.compact,
          onPressed: forwardEnabled ? _next : null,
          icon: Icon(Icons.chevron_right, size: 20, color: forwardEnabled ? _muted : _muted.withValues(alpha: 0.35)),
        ),
      ],
    );
  }

  Widget _avatarPreview() {
    final name = _name.text.trim();
    if (_pic.isNotEmpty) return UiUserAvatar(name: name, pic: _pic, size: 64);
    if (name.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF71717A), Color(0xFF3F3F46)]),
        ),
        child: const Icon(Icons.support_agent_outlined, size: 30, color: Color(0xFFF4F4F5)),
      );
    }
    return UiUserAvatar(name: name, pic: _pic, size: 64);
  }

  Widget _stepBasics() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepIntro('botCreate.basicsHint'.tr()),
          Center(
            child: GestureDetector(
              onTap: _saving ? null : _pickPic,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _avatarPreview(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF18181B), shape: BoxShape.circle, border: Border.all(color: _border)),
                    child: const Icon(Icons.camera_alt_outlined, size: 14, color: _muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            autofocus: true,
            style: const TextStyle(color: _title, fontSize: 14),
            textCapitalization: TextCapitalization.sentences,
            decoration: UiInputDecoration.of(
              context,
              labelText: 'botCreate.nameLabel'.tr(),
              hintText: 'botCreate.nameHint'.tr(),
              floatingLabel: true,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 16),
          IoBotPackagePick(
            value: _billingPackage,
            yearly: _billingYearly,
            botPlans: _botPlans,
            busy: _saving,
            planExpiresTsMs: _planExpiresTsMs,
            onChanged: (v) => setState(() {
              _billingPackage = v;
              if (!_welcomeFieldEditable) _welcomeMessage.clear();
              _error = null;
            }),
            onYearlyChanged: (v) => setState(() => _billingYearly = v),
          ),
          const SizedBox(height: 16),
          _stepIntro('botCreate.welcomeStepHint'.tr()),
          _welcomeMessageField(),
        ],
      );

  Widget _welcomeMessageField() {
    final editable = _welcomeFieldEditable;
    if (!editable) {
      return uiTooltip(
        message: 'botCreate.welcomeLockedHint'.tr(),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('botCreate.welcomeLockedSnack'.tr()),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: UiInputDecoration.of(
              context,
              labelText: 'botCreate.welcomeLabel'.tr(),
              floatingLabel: true,
              suffixIcon: const Icon(Icons.lock_outline, size: 18, color: _muted),
            ),
            child: Text(
              'botCreate.welcomeSharedNone'.tr(),
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.4),
            ),
          ),
        ),
      );
    }
    return TextField(
      controller: _welcomeMessage,
      enabled: !_saving,
      maxLines: 3,
      minLines: 2,
      style: const TextStyle(color: _title, fontSize: 13, height: 1.4),
      decoration: UiInputDecoration.of(
        context,
        labelText: 'botCreate.welcomeLabel'.tr(),
        hintText: 'botCreate.welcomeHint'.tr(),
        floatingLabel: true,
        alignLabelWithHint: true,
      ),
      onChanged: (_) => setState(() => _error = null),
    );
  }

  Widget _stepBehavior() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tell the bot how to reply. You can edit this anytime in bot settings.',
            style: TextStyle(color: _muted.withValues(alpha: 0.95), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructions,
            autofocus: true,
            maxLines: 5,
            minLines: 4,
            style: const TextStyle(color: _title, fontSize: 13, height: 1.4),
            decoration: UiInputDecoration.of(context, labelText: 'Instructions', hintText: 'You are a helpful assistant for…', floatingLabel: true, alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Strict mode', style: TextStyle(color: _title, fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: const Text(
              'Answer only about this business; politely decline unrelated questions.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
            ),
            value: _strictMode,
            activeThumbColor: const Color(0xFF34D399),
            onChanged: _saving ? null : (v) => setState(() => _strictMode = v),
          ),
          if (_strictMode)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Block Spammer Automatically', style: TextStyle(color: _title, fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text(
                'Block users who send 10+ unrelated messages.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
              ),
              value: _autoBlockSpammer,
              activeThumbColor: const Color(0xFF34D399),
              onChanged: _saving ? null : (v) => setState(() => _autoBlockSpammer = v),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Web search', style: TextStyle(color: _title, fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: const Text(
              'Search and visit websites for live factual answers.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
            ),
            value: _webSearch,
            activeThumbColor: const Color(0xFF34D399),
            onChanged: _saving ? null : (v) => setState(() => _webSearch = v),
          ),
        ],
      );

  Widget _stepIntro(String message) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(message, style: const TextStyle(color: _muted, fontSize: 12, height: 1.45)),
      );

  Widget _stepChannels() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepIntro('botCreate.channelsHint'.tr()),
          IoChannelListPanel(channels: _channels, onPick: _onPick, onRemove: _removeChannel, busy: _saving),
        ],
      );

  Widget _stepAssets() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepIntro('botCreate.assetsHint'.tr()),
          IoAssetListPanel(
            conn: widget.store.conn,
            assets: _assetDrafts,
            onAdd: (d) => setState(() => _assetDrafts.add(d)),
            onRemove: (d) => setState(() => _assetDrafts.remove(d)),
            onUpdate: (i, d) => setState(() => _assetDrafts[i] = d),
            busy: _saving,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _cancel();
        },
        child: Dialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
          child: SizedBox(
            width: _dialogW,
            height: _dialogH,
            child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_stepTitle, style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      _stepNav(),
                      uiIconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        onPressed: _saving || _hydrating ? null : _cancel,
                        icon: const Icon(Icons.close, color: _muted, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _bodyScrollCtrl,
                    child: SingleChildScrollView(
                      controller: _bodyScrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: switch (_step) {
                          0 => _stepBasics(),
                          1 => _stepChannels(),
                          2 => _stepAssets(),
                          _ => _stepBehavior(),
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
                      if (_error != null) const SizedBox(height: 8),
                      Row(
                        children: [
                          const Spacer(),
                          FilledButton(
                            onPressed: _saving || _hydrating || !_canStepForward ? null : _next,
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                            child: Text(
                              _saving
                                  ? 'Saving…'
                                  : _step == _stepTotal - 1
                                      ? (_isEditing ? 'botCreate.save'.tr() : 'botCreate.finishTurnOn'.tr())
                                      : 'Next',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
              if (_hydrating)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xCC18181B),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _muted.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
}
