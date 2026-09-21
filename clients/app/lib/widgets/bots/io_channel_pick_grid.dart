import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _panelBg = Color(0xFF100F12);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);

enum ChannelPickKind { whatsappMeta, whatsappPair, telegram }

Widget ioPickTile({
  required Key key,
  required IconData icon,
  required Color accent,
  required String title,
  required String subtitle,
  String? badge,
  VoidCallback? onTap,
}) =>
    Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: _title, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (badge != null) Text(badge, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );

class IoChannelPickGrid extends StatelessWidget {
  const IoChannelPickGrid({
    super.key,
    required this.channels,
    required this.onPick,
    this.onAddChannel,
  });

  final List<BotChannelDoc> channels;
  final ValueChanged<ChannelPickKind> onPick;
  final VoidCallback? onAddChannel;

  bool _hasPlatform(String platform) => channels.any((c) => c.platform == platform && c.status == 'connected');

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;
          final whatsapp = _panel(
            title: 'WhatsApp',
            accent: const Color(0xFF25D366),
            children: [
              ioPickTile(
                key: const Key('channel-pick-wa-meta'),
                icon: Icons.cloud_outlined,
                accent: const Color(0xFF25D366),
                title: 'Meta Cloud API',
                subtitle: _hasPlatform('whatsapp') ? 'Already connected' : 'Business API credentials',
                onTap: _hasPlatform('whatsapp') ? null : () => onPick(ChannelPickKind.whatsappMeta),
              ),
              ioPickTile(
                key: const Key('channel-pick-wa-qr'),
                icon: Icons.qr_code_2_rounded,
                accent: const Color(0xFF25D366),
                title: 'Scan QR',
                subtitle: _hasPlatform('whatsapp') ? 'Already connected' : 'Link your phone',
                onTap: _hasPlatform('whatsapp') ? null : () => onPick(ChannelPickKind.whatsappPair),
              ),
            ],
          );
          final telegram = _panel(
            title: 'Telegram',
            accent: const Color(0xFF38BDF8),
            children: [
              ioPickTile(
                key: const Key('channel-pick-tg'),
                icon: Icons.send_rounded,
                accent: const Color(0xFF38BDF8),
                title: 'Bot API token',
                subtitle: _hasPlatform('telegram') ? 'Already connected' : 'Paste token from @BotFather',
                onTap: _hasPlatform('telegram') ? null : () => onPick(ChannelPickKind.telegram),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stacked) ...[whatsapp, const SizedBox(height: 12), telegram] else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: whatsapp), const SizedBox(width: 12), Expanded(child: telegram)]),
              if (onAddChannel != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(onPressed: onAddChannel, icon: const Icon(Icons.add, size: 18, color: Color(0xFF34D399)), label: const Text('Add another channel', style: TextStyle(color: Color(0xFF34D399)))),
              ],
            ],
          );
        },
      );

  Widget _panel({required String title, required Color accent, required List<Widget> children}) => Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
        decoration: BoxDecoration(color: _panelBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text(title, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            ),
            ...children,
          ],
        ),
      );
}

Widget ioChannelChip(BotChannelDoc channel) {
  final (icon, accent) = switch (channel.platform) {
    'whatsapp' => (Icons.chat_rounded, const Color(0xFF25D366)),
    'telegram' => (Icons.send_rounded, const Color(0xFF38BDF8)),
    _ => (Icons.link_rounded, const Color(0xFFA1A1AA)),
  };
  final status = channel.status.isNotEmpty ? channel.status : 'pending';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(99), border: Border.all(color: _border)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 6),
        Text('${channel.platform} · $status', style: const TextStyle(color: _title, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}
