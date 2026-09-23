import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/bot/bot_api.dart';
import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/channel/channel_api.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:alienai_c35/widgets/bots/io_channel_pick_grid.dart';
import 'package:alienai_c35/widgets/bots/io_channel_telegram_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_meta_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_pair.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);
const _dialogW = 400.0;
const _dialogH = 520.0;
const _stepTotal = 3;

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
  var _step = 0;
  var _saving = false;
  var _canceling = false;
  var _pic = '';
  var _finished = false;
  String? _error;
  int? _botIid;
  final _channels = <BotChannelDoc>[];
  final _assets = <String>[];

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
    if (!_finished && _botIid != null) {
      unawaited(_cleanupDraft());
    }
    super.dispose();
  }

  String get _stepTitle => switch (_step) {
        0 => 'New Chat Bot',
        1 => 'Connect channels',
        _ => 'Assets',
      };

  bool get _canStepForward => _step == 0 ? _name.text.trim().isNotEmpty : true;

  Future<void> _cleanupDraft() async {
    if (_finished) return;
    final iid = _botIid;
    if (iid == null) return;
    for (final ch in List<BotChannelDoc>.from(_channels)) {
      if (ch.id.isEmpty) continue;
      try {
        await widget.onChannelDisconnect(botIid: iid, channelId: ch.id);
      } catch (e) {
        lError('bot create cleanup channel ${ch.id}: $e');
      }
    }
    try {
      await widget.onIdentityDelete(iid);
    } catch (e) {
      lError('bot create cleanup bot $iid: $e');
    }
  }

  Future<void> _cancel() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _canceling = true;
    });
    await _cleanupDraft();
    if (!mounted) return;
    _finished = true;
    Navigator.pop(context);
  }

  Future<void> _next() async {
    if (_step == 0) {
      final name = _name.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'Name is required');
        return;
      }
      setState(() {
        _error = null;
        _saving = true;
      });
      try {
        final meta = jsonEncode({'inst_base': _instructions.text.trim(), 'channels': [], 'assets': []});
        final req = ReqIdentityPut(kind: 'bot', type: 'chat', name: name, pic: _pic, metaJson: meta);
        if (_botIid != null) req.iid = Int64(_botIid!);
        final res = await widget.onIdentityPut(req);
        final iid = res.row.identity.iid.toInt();
        if (iid <= 0) throw StateError('invalid bot iid');
        setState(() {
          _botIid = iid;
          _step = 1;
          _saving = false;
        });
      } catch (e) {
        lError('bot create step1: $e');
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = 'Could not create bot — try again';
        });
      }
      return;
    }
    if (_step == 1) {
      setState(() {
        _error = null;
        _step = 2;
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
      final meta = jsonEncode({'inst_base': _instructions.text.trim(), 'assets': _assets});
      await widget.onIdentityPut(ReqIdentityPut(iid: Int64(iid), kind: 'bot', type: 'chat', name: _name.text.trim(), pic: _pic, metaJson: meta));
      if (!mounted) return;
      _finished = true;
      Navigator.pop(context, InBotCreateResult(botIid: iid, name: _name.text.trim()));
    } catch (e) {
      lError('bot create finish: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save bot — try again';
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

  Widget _stepNav() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: _saving ? null : _back,
            icon: Icon(Icons.chevron_left, size: 20, color: _step > 0 ? _title : _muted.withValues(alpha: 0.35)),
          ),
          Text('Step ${_step + 1} / $_stepTotal', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500)),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: _saving || !_canStepForward || _step >= _stepTotal - 1 ? null : _next,
            icon: Icon(Icons.chevron_right, size: 20, color: _canStepForward && _step < _stepTotal - 1 ? _title : _muted.withValues(alpha: 0.35)),
          ),
        ],
      );

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

  Widget _stepInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            style: const TextStyle(color: _title, fontSize: 14),
            decoration: UiInputDecoration.of(context, labelText: 'Name', hintText: 'Customer service', floatingLabel: true),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructions,
            maxLines: 5,
            minLines: 4,
            style: const TextStyle(color: _title, fontSize: 13, height: 1.4),
            decoration: UiInputDecoration.of(context, labelText: 'Instructions', hintText: 'You are a helpful assistant for…', floatingLabel: true, alignLabelWithHint: true),
          ),
        ],
      );

  Widget _stepChannels() => IoChannelListPanel(channels: _channels, onPick: _onPick, onRemove: _removeChannel, busy: _saving);

  Widget _stepAssets() => IoAssetListPanel(
        assets: _assets,
        onAdd: (id) => setState(() => _assets.add(id)),
        onRemove: (id) => setState(() => _assets.remove(id)),
        busy: _saving,
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_stepTitle, style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      uiIconButton(
                        tooltip: 'Cancel setup',
                        visualDensity: VisualDensity.compact,
                        onPressed: _saving ? null : _cancel,
                        icon: const Icon(Icons.close, color: _muted, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _stepNav(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(child: switch (_step) { 0 => _stepInfo(), 1 => _stepChannels(), _ => _stepAssets() }),
                  ),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _saving ? null : _cancel,
                        child: Text(_canceling ? 'Canceling…' : _step == 0 ? 'Cancel' : 'Cancel setup'),
                      ),
                      const Spacer(),
                      if (_step >= 1) ...[
                        TextButton(onPressed: _saving ? null : _finish, child: const Text('Skip for now')),
                        const SizedBox(width: 8),
                      ],
                      FilledButton(
                        onPressed: _saving ? null : _next,
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                        child: Text(_canceling ? 'Canceling…' : _saving ? 'Saving…' : _step == _stepTotal - 1 ? 'Finish' : 'Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
