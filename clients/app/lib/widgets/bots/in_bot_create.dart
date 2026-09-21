import 'dart:convert';

import 'package:alienai_c35/c/bot/bot_api.dart';
import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/channel/channel_api.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/widgets/bots/io_channel_pick_grid.dart';
import 'package:alienai_c35/widgets/bots/io_channel_telegram_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_meta_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_pair.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);

class InBotCreateResult {
  const InBotCreateResult({required this.botIid, required this.name});

  final int botIid;
  final String name;
}

typedef IdentityPutFn = Future<ResIdentityPut> Function(ReqIdentityPut req);

Future<InBotCreateResult?> inBotCreateShow(
  BuildContext context, {
  required BotStore store,
  IdentityPutFn? onIdentityPut,
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
    required this.onTelegramConnect,
    required this.onWhatsappMetaConnect,
    required this.onWhatsappPairStart,
    required this.onWhatsappPairWatch,
    required this.onWhatsappPairAbort,
  });

  final BotStore store;
  final IdentityPutFn onIdentityPut;
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
  var _pic = '';
  String? _error;
  int? _botIid;
  final _channels = <BotChannelDoc>[];

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
    super.dispose();
  }

  bool get _hasConnectedChannel => _channels.any((c) => c.status == 'connected');

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
        final meta = jsonEncode({'inst_base': _instructions.text.trim(), 'channels': []});
        final res = await widget.onIdentityPut(ReqIdentityPut(kind: 'bot', type: 'chat', name: name, pic: _pic, metaJson: meta));
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
    _finish();
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _step = 0;
      _error = null;
    });
  }

  void _finish() {
    final iid = _botIid;
    if (iid == null) return;
    Navigator.pop(context, InBotCreateResult(botIid: iid, name: _name.text.trim()));
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
    setState(() {
      final i = _channels.indexWhere((c) => c.platform == channel!.platform);
      if (i >= 0) {
        _channels[i] = channel!;
      } else {
        _channels.add(channel!);
      }
    });
  }

  Widget _stepHeader() => Row(
        children: [
          Expanded(child: Text(_step == 0 ? 'New Chat Bot' : 'Connect channels', style: const TextStyle(color: _title, fontSize: 16, fontWeight: FontWeight.w600))),
          Text('Step ${_step + 1}/2', style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _stepInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _saving ? null : _pickPic,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  UiUserAvatar(name: _name.text.trim().isEmpty ? 'Bot' : _name.text.trim(), pic: _pic, size: 64),
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
            decoration: UiInputDecoration.of(context, labelText: 'Name', hintText: 'Support bot', floatingLabel: true),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
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

  Widget _stepChannels() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_channels.isNotEmpty) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [for (final c in _channels) ioChannelChip(c)]),
            const SizedBox(height: 12),
          ],
          IoChannelPickGrid(channels: _channels, onPick: _onPick),
        ],
      );

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _stepHeader(),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(child: _step == 0 ? _stepInfo() : _stepChannels()),
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(onPressed: _saving ? null : _back, child: Text(_step == 0 ? 'Cancel' : 'Back')),
                    const Spacer(),
                    if (_step == 1) ...[
                      TextButton(onPressed: _saving ? null : _finish, child: const Text('Skip for now')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saving ? null : _finish,
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                        child: Text(_hasConnectedChannel ? 'Finish' : 'Done'),
                      ),
                    ] else ...[
                      FilledButton(
                        onPressed: _saving ? null : _next,
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                        child: Text(_saving ? 'Creating…' : 'Next'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
