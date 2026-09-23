import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _panelBg = Color(0xFF100F12);
const _title = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);
const _accent = Color(0xFF34D399);

enum ChannelPickKind { whatsappMeta, whatsappPair, telegram }

const _channelPickItems = [
  IoAskItem(id: 'telegram', title: 'Telegram', subtitle: 'Bot API token from @BotFather', icon: Icons.send_rounded, accent: Color(0xFF38BDF8)),
  IoAskItem(id: 'whatsapp_meta', title: 'WhatsApp Meta Cloud API', subtitle: 'Business API credentials', icon: Icons.cloud_outlined, accent: Color(0xFF25D366)),
  IoAskItem(id: 'whatsapp_pair', title: 'WhatsApp Scan QR', subtitle: 'Link your phone', icon: Icons.qr_code_2_rounded, accent: Color(0xFF25D366)),
];

ChannelPickKind? channelPickKindFromId(String id) => switch (id) {
      'telegram' => ChannelPickKind.telegram,
      'whatsapp_meta' => ChannelPickKind.whatsappMeta,
      'whatsapp_pair' => ChannelPickKind.whatsappPair,
      _ => null,
    };

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

class IoChannelListPanel extends StatelessWidget {
  const IoChannelListPanel({super.key, required this.channels, required this.onPick, required this.onRemove, this.busy = false});

  final List<BotChannelDoc> channels;
  final ValueChanged<ChannelPickKind> onPick;
  final ValueChanged<BotChannelDoc> onRemove;
  final bool busy;

  Future<void> _addChannel(BuildContext context) async {
    final picked = await ioAskItemsShow(context, title: 'Add channel', items: _channelPickItems, searchHint: 'Search channels…');
    final kind = picked == null ? null : channelPickKindFromId(picked.id);
    if (kind != null) onPick(kind);
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 320,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(color: _panelBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: channels.isEmpty
                  ? const Center(child: Text('No channels yet', style: TextStyle(color: _muted, fontSize: 13)))
                  : ListView.separated(
                      itemCount: channels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) => IoChannelRow(channel: channels[i], onRemove: busy ? null : () => onRemove(channels[i])),
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _addChannel(context),
              icon: const Icon(Icons.add, size: 16, color: _accent),
              label: const Text('Add channel', style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: _border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      );
}

class IoChannelRow extends StatelessWidget {
  const IoChannelRow({super.key, required this.channel, this.onRemove});

  final BotChannelDoc channel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final (label, icon, accent) = channelDisplay(channel);
    final status = channel.status.isNotEmpty ? channel.status : 'pending';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(status, style: TextStyle(color: status == 'connected' ? _accent : _muted, fontSize: 11)),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16, color: _muted),
            ),
        ],
      ),
    );
  }
}

const _assetPickItems = [
  IoAskItem(id: 'google_sheets', title: 'Google Sheets', subtitle: 'Read and write spreadsheet data', icon: Icons.table_chart_outlined, accent: Color(0xFF34A853)),
  IoAskItem(id: 'google_drive', title: 'Google Drive', subtitle: 'Access files and folders', icon: Icons.folder_outlined, accent: Color(0xFF4285F4)),
];

class IoAssetListPanel extends StatelessWidget {
  const IoAssetListPanel({super.key, required this.assets, required this.onAdd, required this.onRemove, this.busy = false});

  final List<String> assets;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final bool busy;

  Future<void> _addAsset(BuildContext context) async {
    final picked = await ioAskItemsShow(context, title: 'Add asset', items: _assetPickItems, searchHint: 'Search assets…');
    if (picked != null && !assets.contains(picked.id)) onAdd(picked.id);
  }

  IoAskItem? _item(String id) {
    for (final item in _assetPickItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 320,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(color: _panelBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: assets.isEmpty
                  ? const Center(child: Text('No assets yet', style: TextStyle(color: _muted, fontSize: 13)))
                  : ListView.separated(
                      itemCount: assets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final id = assets[i];
                        final item = _item(id);
                        return Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                          decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                          child: Row(
                            children: [
                              if (item?.icon != null)
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(color: (item!.accent ?? _accent).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(item.icon, size: 16, color: item.accent ?? _accent),
                                ),
                              if (item?.icon != null) const SizedBox(width: 10),
                              Expanded(child: Text(item?.title ?? id, style: const TextStyle(color: _title, fontSize: 13, fontWeight: FontWeight.w600))),
                              if (!busy)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () => onRemove(id),
                                  icon: const Icon(Icons.close, size: 16, color: _muted),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _addAsset(context),
              icon: const Icon(Icons.add, size: 16, color: _accent),
              label: const Text('Add asset', style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: _border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      );
}
