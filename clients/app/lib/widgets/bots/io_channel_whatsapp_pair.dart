import 'dart:async';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

typedef ChannelWhatsappPairStartFn = Future<ResChannelWhatsappPair?> Function({
  required int botIid,
  String channelId,
  void Function(ChannelPairPush push)? onUpdate,
});

typedef ChannelWhatsappPairWatchFn = Future<void> Function({
  required int botIid,
  required String channelId,
});

typedef ChannelWhatsappPairAbortFn = Future<void> Function({
  required int botIid,
  required String channelId,
});

Future<BotChannelDoc?> ioChannelWhatsappPairShow(
  BuildContext context, {
  required int botIid,
  ChannelWhatsappPairStartFn? onStart,
  ChannelWhatsappPairWatchFn? onWatch,
  ChannelWhatsappPairAbortFn? onAbort,
}) =>
    showDialog<BotChannelDoc>(
      context: context,
      builder: (_) => IoChannelWhatsappPair(
        botIid: botIid,
        onStart: onStart ?? _stubWhatsappPairStart,
        onWatch: onWatch ?? _stubWhatsappPairWatch,
        onAbort: onAbort ?? _stubWhatsappPairAbort,
      ),
    );

Timer? _stubWatchTimer;
String _stubChannelId = '';

Future<ResChannelWhatsappPair?> _stubWhatsappPairStart({
  required int botIid,
  String channelId = '',
  void Function(ChannelPairPush push)? onUpdate,
}) async {
  l('stub whatsappPairStart bot=$botIid');
  _stubChannelId = channelId.isNotEmpty ? channelId : 'wa-pair-stub';
  await Future<void>.delayed(const Duration(milliseconds: 600));
  final qr = 'https://wa.me/qr/STUB${DateTime.now().millisecondsSinceEpoch}';
  final push = ChannelPairPush(botIid: Int64(botIid), channelId: _stubChannelId, status: 'pairing', qrRaw: qr);
  onUpdate?.call(push);
  _stubWatchTimer?.cancel();
  _stubWatchTimer = Timer(const Duration(seconds: 8), () {
    onUpdate?.call(ChannelPairPush(botIid: Int64(botIid), channelId: _stubChannelId, status: 'connected', phone: '+15551234567'));
  });
  return ResChannelWhatsappPair(ok: true, botIid: Int64(botIid), qrRaw: qr, channel: BotChannelDoc(id: _stubChannelId, platform: 'whatsapp', provider: 'linked_device', status: 'pairing'));
}

Future<void> _stubWhatsappPairWatch({required int botIid, required String channelId}) async {
  l('stub whatsappPairWatch bot=$botIid channel=$channelId');
}

Future<void> _stubWhatsappPairAbort({required int botIid, required String channelId}) async {
  l('stub whatsappPairAbort bot=$botIid channel=$channelId');
  _stubWatchTimer?.cancel();
  _stubWatchTimer = null;
}

class IoChannelWhatsappPair extends StatefulWidget {
  const IoChannelWhatsappPair({
    super.key,
    required this.botIid,
    required this.onStart,
    required this.onWatch,
    required this.onAbort,
  });

  final int botIid;
  final ChannelWhatsappPairStartFn onStart;
  final ChannelWhatsappPairWatchFn onWatch;
  final ChannelWhatsappPairAbortFn onAbort;

  @override
  State<IoChannelWhatsappPair> createState() => _IoChannelWhatsappPairState();
}

class _IoChannelWhatsappPairState extends State<IoChannelWhatsappPair> {
  var _starting = true;
  var _connected = false;
  var _aborted = false;
  String? _error;
  String _status = 'pairing';
  String _qrRaw = '';
  String _phone = '';
  String _channelId = '';
  Timer? _watchTimer;

  @override
  void initState() {
    super.initState();
    _pairStart();
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    if (!_connected && !_aborted && _channelId.isNotEmpty) {
      widget.onAbort(botIid: widget.botIid, channelId: _channelId);
    }
    super.dispose();
  }

  void _applyPair(ResChannelWhatsappPair res) {
    if (!mounted) return;
    if (!res.ok) {
      setState(() {
        _starting = false;
        _error = res.error.isEmpty ? 'Pair start failed' : res.error;
      });
      return;
    }
    if (res.channel.id.isNotEmpty) _channelId = res.channel.id;
    _applyUpdate(ChannelPairPush(botIid: res.botIid, channelId: _channelId, status: res.channel.status.isNotEmpty ? res.channel.status : 'pairing', qrRaw: res.qrRaw, phone: res.phone));
    setState(() => _starting = false);
  }

  void _applyUpdate(ChannelPairPush update) {
    if (!mounted || update.botIid.toInt() != widget.botIid) return;
    if (update.channelId.isNotEmpty) _channelId = update.channelId;
    final status = update.status;
    final connected = status == 'connected' || status == 'active';
    final failed = status == 'error' || status == 'disconnected';
    setState(() {
      _status = status;
      if (update.qrRaw.isNotEmpty) _qrRaw = update.qrRaw;
      if (update.phone.isNotEmpty) _phone = update.phone;
      if (update.errorMessage.isNotEmpty) _error = update.errorMessage;
      if (connected) {
        _connected = true;
        _watchTimer?.cancel();
      }
      if (failed && !connected) _error = update.errorMessage.isEmpty ? 'Pairing failed' : update.errorMessage;
    });
    if (connected) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        Navigator.pop(
          context,
          BotChannelDoc(id: _channelId, platform: 'whatsapp', provider: 'linked_device', status: 'connected', phone: _phone),
        );
      });
    }
  }

  Future<void> _pairStart() async {
    final res = await widget.onStart(botIid: widget.botIid, onUpdate: _applyUpdate);
    if (res != null) _applyPair(res);
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_channelId.isEmpty || _connected) return;
      widget.onWatch(botIid: widget.botIid, channelId: _channelId);
    });
  }

  Future<void> _cancel() async {
    _aborted = true;
    _watchTimer?.cancel();
    if (_channelId.isNotEmpty) await widget.onAbort(botIid: widget.botIid, channelId: _channelId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _cancel();
        },
        child: Dialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF27272A))),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Link WhatsApp', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Open WhatsApp on your phone → Linked devices → Link a device, then scan this QR.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.4)),
                  const SizedBox(height: 16),
                  if (_starting)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF25D366))))
                  else if (_qrRaw.isNotEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: QrImageView(data: _qrRaw, size: 220, backgroundColor: Colors.white),
                      ),
                    )
                  else
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Waiting for QR…', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)))),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
                  if (_phone.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Phone: $_phone', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11))),
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text('Status: $_status', style: const TextStyle(color: Color(0xFF52525B), fontSize: 10))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: _cancel, child: const Text('Cancel')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
