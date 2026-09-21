import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ChannelConnectLogCallback = void Function({required String line, required int step, required int total, required bool done, required bool ok});

typedef ChannelTelegramConnectFn = Future<BotChannelDoc?> Function({
  required int botIid,
  required String botToken,
  ChannelConnectLogCallback? onLog,
});

Future<BotChannelDoc?> ioChannelTelegramConnectShow(
  BuildContext context, {
  required int botIid,
  ChannelTelegramConnectFn? onConnect,
}) =>
    showDialog<BotChannelDoc>(
      context: context,
      builder: (_) => IoChannelTelegramConnect(botIid: botIid, onConnect: onConnect ?? _stubTelegramConnect),
    );

Future<BotChannelDoc?> _stubTelegramConnect({
  required int botIid,
  required String botToken,
  ChannelConnectLogCallback? onLog,
}) async {
  l('stub telegramConnect bot=$botIid');
  const total = 4;
  for (var i = 1; i <= total; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    onLog?.call(line: 'Step $i/$total…', step: i, total: total, done: false, ok: true);
  }
  onLog?.call(line: 'Connected', step: total, total: total, done: true, ok: true);
  return BotChannelDoc(id: 'tg-stub', platform: 'telegram', provider: 'bot_api', status: 'connected', botUsername: '@stub_bot');
}

class IoChannelTelegramConnect extends StatefulWidget {
  const IoChannelTelegramConnect({super.key, required this.botIid, required this.onConnect});

  final int botIid;
  final ChannelTelegramConnectFn onConnect;

  @override
  State<IoChannelTelegramConnect> createState() => _IoChannelTelegramConnectState();
}

class _IoChannelTelegramConnectState extends State<IoChannelTelegramConnect> {
  late final _token = TextEditingController();
  var _connecting = false;
  String? _error;
  final _logs = <String>[];
  var _step = 0;
  var _total = 6;
  var _pulse = false;

  @override
  void dispose() {
    _token.dispose();
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

  Future<void> _openBotFather() async {
    final uri = Uri.parse('https://t.me/BotFather');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _connect() async {
    final token = _token.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Paste your bot token from @BotFather');
      return;
    }
    setState(() {
      _error = null;
      _connecting = true;
      _logs.clear();
      _step = 0;
      _pulse = true;
      _logs.add('Starting…');
    });
    try {
      final channel = await widget.onConnect(botIid: widget.botIid, botToken: token, onLog: _logPut);
      if (!mounted) return;
      if (channel == null) {
        setState(() {
          _connecting = false;
          _pulse = false;
          _error = 'Connect failed — check token and try again';
        });
        return;
      }
      Navigator.pop(context, channel);
    } catch (e) {
      lError('telegram connect: $e');
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _pulse = false;
        _error = 'Connect failed — check token and try again';
      });
    }
  }

  Widget _logPanel() {
    if (!_connecting && _logs.isEmpty) return const SizedBox.shrink();
    final progress = _total <= 0 ? null : (_step / _total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        key: const Key('tg-connect-log'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF100F12), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF27272A))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, value: _connecting && progress == null ? null : progress, color: const Color(0xFF38BDF8))),
                const SizedBox(width: 8),
                Expanded(child: Text(_connecting ? 'Connecting to Telegram…' : 'Connection log', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(minHeight: 3, value: progress, backgroundColor: const Color(0xFF27272A), color: const Color(0xFF38BDF8))),
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
                        child: Text(line, style: TextStyle(color: line == _logs.last && _pulse ? const Color(0xFF38BDF8) : const Color(0xFF71717A), fontSize: 11, height: 1.35, fontFamily: 'monospace')),
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
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Connect Telegram', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Chat ', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.35)),
                    GestureDetector(key: const Key('tg-botfather'), onTap: _openBotFather, child: const Text('@BotFather', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600, height: 1.35))),
                    const Text(' to create a bot, then paste the API token here.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.35)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('tg-api-key'),
                  controller: _token,
                  autofocus: true,
                  maxLines: 4,
                  minLines: 3,
                  style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFF4F4F5), fontSize: 12),
                  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                  decoration: UiInputDecoration.of(context, hintText: '123456789:ABCdefGHIjklMNOpqrsTUVwxyz', floatingLabel: false).copyWith(hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 12, fontFamily: 'monospace')),
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11))),
                _logPanel(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _connecting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _connecting ? null : _connect, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black), child: Text(_connecting ? 'Connecting…' : 'Connect')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
