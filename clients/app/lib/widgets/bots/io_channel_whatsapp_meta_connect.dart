import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/widgets/bots/io_channel_telegram_connect.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ChannelWhatsappMetaConnectFn = Future<ChannelWhatsappMetaConnectResult?> Function({
  required int botIid,
  required String accessToken,
  required String phoneNumberId,
  String wabaId,
  String verifyToken,
  ChannelConnectLogCallback? onLog,
});

class ChannelWhatsappMetaConnectResult {
  const ChannelWhatsappMetaConnectResult({required this.channel, this.webhookUrl, this.verifyToken});

  final BotChannelDoc channel;
  final String? webhookUrl;
  final String? verifyToken;
}

Future<ChannelWhatsappMetaConnectResult?> ioChannelWhatsappMetaConnectShow(
  BuildContext context, {
  required int botIid,
  ChannelWhatsappMetaConnectFn? onConnect,
}) =>
    showDialog<ChannelWhatsappMetaConnectResult>(
      context: context,
      builder: (_) => IoChannelWhatsappMetaConnect(botIid: botIid, onConnect: onConnect ?? _stubWhatsappMetaConnect),
    );

Future<ChannelWhatsappMetaConnectResult?> _stubWhatsappMetaConnect({
  required int botIid,
  required String accessToken,
  required String phoneNumberId,
  String wabaId = '',
  String verifyToken = '',
  ChannelConnectLogCallback? onLog,
}) async {
  l('stub whatsappMetaConnect bot=$botIid');
  const total = 5;
  for (var i = 1; i <= total; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    onLog?.call(line: 'Step $i/$total…', step: i, total: total, done: false, ok: true);
  }
  onLog?.call(line: 'Connected', step: total, total: total, done: true, ok: true);
  return ChannelWhatsappMetaConnectResult(
    channel: BotChannelDoc(id: 'wa-meta-stub', platform: 'whatsapp', provider: 'meta_api', status: 'connected', phone: phoneNumberId),
    webhookUrl: 'https://api.example.com/webhook/whatsapp/$botIid',
    verifyToken: verifyToken.isNotEmpty ? verifyToken : 'stub-verify-token',
  );
}

class IoChannelWhatsappMetaConnect extends StatefulWidget {
  const IoChannelWhatsappMetaConnect({super.key, required this.botIid, required this.onConnect});

  final int botIid;
  final ChannelWhatsappMetaConnectFn onConnect;

  @override
  State<IoChannelWhatsappMetaConnect> createState() => _IoChannelWhatsappMetaConnectState();
}

class _IoChannelWhatsappMetaConnectState extends State<IoChannelWhatsappMetaConnect> {
  late final _accessToken = TextEditingController();
  late final _phoneNumberId = TextEditingController();
  late final _wabaId = TextEditingController();
  late final _verifyTokenInput = TextEditingController();
  var _connecting = false;
  var _connected = false;
  String? _error;
  String? _webhookUrl;
  String? _verifyToken;
  BotChannelDoc? _channel;
  final _logs = <String>[];
  var _step = 0;
  var _total = 6;
  var _pulse = false;

  @override
  void dispose() {
    _accessToken.dispose();
    _phoneNumberId.dispose();
    _wabaId.dispose();
    _verifyTokenInput.dispose();
    super.dispose();
  }

  void _logPut({required String line, required int step, required int total, required bool done, required bool ok}) {
    if (!mounted || line.isEmpty) return;
    setState(() {
      if (!_logs.contains(line)) _logs.add(line);
      if (total > 0) _total = total;
      if (step >= 0) _step = step.clamp(0, total > 0 ? total : _total);
      _pulse = !done;
      if (done && !ok) _error = line;
    });
  }

  Future<void> _openMetaDocs() async {
    final uri = Uri.parse('https://developers.facebook.com/docs/whatsapp/cloud-api/get-started');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _connect() async {
    final accessToken = _accessToken.text.trim();
    final phoneNumberId = _phoneNumberId.text.trim();
    if (accessToken.isEmpty || phoneNumberId.isEmpty) {
      setState(() => _error = 'Access token and phone number ID are required');
      return;
    }
    setState(() {
      _error = null;
      _webhookUrl = null;
      _connecting = true;
      _logs.clear();
      _step = 0;
      _pulse = true;
      _logs.add('Starting…');
    });
    try {
      final res = await widget.onConnect(
        botIid: widget.botIid,
        accessToken: accessToken,
        phoneNumberId: phoneNumberId,
        wabaId: _wabaId.text.trim(),
        verifyToken: _verifyTokenInput.text.trim(),
        onLog: _logPut,
      );
      if (!mounted) return;
      if (res == null) {
        setState(() {
          _connecting = false;
          _pulse = false;
          _error = 'Connect failed — check credentials and try again';
        });
        return;
      }
      setState(() {
        _connecting = false;
        _pulse = false;
        _connected = true;
        _channel = res.channel;
        _webhookUrl = res.webhookUrl;
        _verifyToken = res.verifyToken;
      });
    } catch (e) {
      lError('whatsapp meta connect: $e');
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _pulse = false;
        _error = 'Connect failed — check credentials and try again';
      });
    }
  }

  Widget _field(String label, TextEditingController controller, {Key? key, int maxLines = 1, String hint = ''}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          key: key,
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines > 1 ? maxLines : 1,
          style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFF4F4F5), fontSize: 12),
          decoration: UiInputDecoration.of(context, labelText: label, hintText: hint, floatingLabel: true).copyWith(hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 12, fontFamily: 'monospace')),
        ),
      );

  Widget _logPanel() {
    if (!_connecting && _logs.isEmpty) return const SizedBox.shrink();
    final progress = _total <= 0 ? null : (_step / _total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        key: const Key('wa-connect-log'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF100F12), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF27272A))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, value: _connecting && progress == null ? null : progress, color: const Color(0xFF25D366))),
                const SizedBox(width: 8),
                Expanded(child: Text(_connecting ? 'Connecting to WhatsApp…' : 'Connection log', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(minHeight: 3, value: progress, backgroundColor: const Color(0xFF27272A), color: const Color(0xFF25D366))),
            ],
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in _logs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(line, style: TextStyle(color: line == _logs.last && _pulse ? const Color(0xFF25D366) : const Color(0xFF71717A), fontSize: 11, height: 1.35, fontFamily: 'monospace')),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF27272A))),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Connect WhatsApp Cloud', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Use credentials from the ', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.35)),
                    GestureDetector(key: const Key('wa-meta-docs'), onTap: _openMetaDocs, child: const Text('Meta Cloud API', style: TextStyle(color: Color(0xFF25D366), fontSize: 12, fontWeight: FontWeight.w600, height: 1.35))),
                    const Text(' dashboard.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.35)),
                  ],
                ),
                const SizedBox(height: 14),
                _field('Access token', _accessToken, key: const Key('wa-access-token'), maxLines: 3, hint: 'EAA...'),
                _field('Phone number ID', _phoneNumberId, key: const Key('wa-phone-number-id'), hint: '123456789012345'),
                _field('WABA ID (optional)', _wabaId, hint: 'Business account ID'),
                _field('Verify token (optional)', _verifyTokenInput, hint: 'Defaults to webhook secret'),
                if (_connected && _webhookUrl != null) ...[
                  const Text('Add this webhook in Meta Developer Console → WhatsApp → Configuration.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.35)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF100F12), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF27272A))),
                    child: SelectableText('Callback URL:\n$_webhookUrl', style: const TextStyle(color: Color(0xFF25D366), fontSize: 11, fontFamily: 'monospace')),
                  ),
                  if (_verifyToken != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF100F12), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF27272A))),
                      child: SelectableText('Verify token:\n$_verifyToken', style: const TextStyle(color: Color(0xFF25D366), fontSize: 11, fontFamily: 'monospace')),
                    ),
                  ],
                ],
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
                _logPanel(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _connecting ? null : () => Navigator.pop(context), child: Text(_connected ? 'Close' : 'Cancel')),
                    if (!_connected) ...[
                      const SizedBox(width: 8),
                      FilledButton(onPressed: _connecting ? null : _connect, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.black), child: Text(_connecting ? 'Connecting…' : 'Connect')),
                    ] else ...[
                      const SizedBox(width: 8),
                      FilledButton(onPressed: _channel == null ? null : () => Navigator.pop(context, ChannelWhatsappMetaConnectResult(channel: _channel!, webhookUrl: _webhookUrl, verifyToken: _verifyToken)), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.black), child: const Text('Done')),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
