import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:alienai_c35/widgets/bots/ui_channel_platform_icon.dart';
import 'package:alienai_c35/widgets/bots/io_google_asset_connect.dart';
import 'package:alienai_c35/widgets/io/ask_confirm.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:easy_localization/easy_localization.dart';
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

Widget channelStatusLine(String status) {
  final raw = status.isNotEmpty ? status : 'pending';
  if (raw.toLowerCase() == 'connected') {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('botCreate.channelStatusConnected'.tr(), style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
  final label = raw.length <= 1 ? raw.toUpperCase() : '${raw[0].toUpperCase()}${raw.substring(1)}';
  return Text(label, style: const TextStyle(color: _muted, fontSize: 11));
}

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

  Future<void> _confirmRemove(BuildContext context) async {
    final remove = onRemove;
    if (remove == null) return;
    final (label, _, _) = channelDisplay(channel);
    final isId = Localizations.maybeLocaleOf(context)?.languageCode == 'id';
    final ok = await askConfirm(
      context,
      title: 'botCreate.channelRemoveTitle'.tr(),
      message: 'botCreate.channelRemoveMessage'.tr(namedArgs: {'name': label}),
      isDestructive: true,
      confirmLabel: isId ? 'Hapus' : 'Remove',
    );
    if (ok && context.mounted) remove();
  }

  @override
  Widget build(BuildContext context) {
    final (label, _, accent) = channelDisplay(channel);
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
            child: UiChannelPlatformIcon(platform: channel.platform, size: 16, accent: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontSize: 13, fontWeight: FontWeight.w600)),
                channelStatusLine(status),
              ],
            ),
          ),
          if (onRemove != null)
            uiIconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              onPressed: () => _confirmRemove(context),
              icon: const Icon(Icons.close, color: _muted, size: 20),
            ),
        ],
      ),
    );
  }
}

const _assetPickItems = [
  IoAskItem(id: 'google_sheets', title: 'Google Sheets', subtitle: 'Read and write spreadsheet data', icon: Icons.table_chart_outlined, accent: Color(0xFF34A853)),
  IoAskItem(id: 'google_docs', title: 'Google Docs', subtitle: 'Read document content', icon: Icons.description_outlined, accent: Color(0xFF4285F4)),
  IoAskItem(id: 'google_slides', title: 'Google Slides', subtitle: 'Read slide deck content', icon: Icons.slideshow_outlined, accent: Color(0xFFFBBC04)),
];

@Deprecated('Use BotAssetDraft')
typedef BotSheetDraft = BotAssetDraft;

class IoAssetListPanel extends StatelessWidget {
  const IoAssetListPanel({
    super.key,
    required this.conn,
    required this.assets,
    required this.onAdd,
    required this.onRemove,
    this.onUpdate,
    this.busy = false,
  });

  final ChatConn conn;
  final List<BotAssetDraft> assets;
  final ValueChanged<BotAssetDraft> onAdd;
  final ValueChanged<BotAssetDraft> onRemove;
  final void Function(int index, BotAssetDraft draft)? onUpdate;
  final bool busy;

  Future<void> _addAsset(BuildContext context) async {
    final picked = await ioAskItemsShow(context, title: 'Add asset', items: _assetPickItems, searchHint: 'Search assets…');
    if (!context.mounted) return;
    final kind = picked == null ? null : googleAssetConnectKindFromPickId(picked.id);
    if (kind == null) return;
    final draft = await ioGoogleAssetConnectShow(context, conn: conn, kind: kind);
    if (draft != null) onAdd(draft);
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
                      itemBuilder: (context, i) => IoAssetRow(
                        conn: conn,
                        asset: assets[i],
                        onUpdated: busy || onUpdate == null ? null : (d) => onUpdate!(i, d),
                        onRemove: busy ? null : () => onRemove(assets[i]),
                      ),
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

class IoAssetRow extends StatefulWidget {
  const IoAssetRow({super.key, required this.conn, required this.asset, this.onUpdated, this.onRemove});

  final ChatConn conn;
  final BotAssetDraft asset;
  final ValueChanged<BotAssetDraft>? onUpdated;
  final VoidCallback? onRemove;

  @override
  State<IoAssetRow> createState() => _IoAssetRowState();
}

class _IoAssetRowState extends State<IoAssetRow> {
  var _refreshing = false;

  BotAssetDraft get asset => widget.asset;

  ({IconData icon, Color accent}) _assetStyle(String sourceKind) => switch (sourceKind) {
        'google_doc' => (icon: Icons.description_outlined, accent: const Color(0xFF4285F4)),
        'google_slide' => (icon: Icons.slideshow_outlined, accent: const Color(0xFFFBBC04)),
        _ => (icon: Icons.table_chart_outlined, accent: const Color(0xFF34A853)),
      };

  Future<void> _confirmRemove(BuildContext context) async {
    final remove = widget.onRemove;
    if (remove == null) return;
    final isId = Localizations.maybeLocaleOf(context)?.languageCode == 'id';
    final ok = await askConfirm(
      context,
      title: 'botCreate.assetRemoveTitle'.tr(),
      message: 'botCreate.assetRemoveMessage'.tr(namedArgs: {'name': asset.name}),
      isDestructive: true,
      confirmLabel: isId ? 'Hapus' : 'Remove',
    );
    if (ok && context.mounted) remove();
  }

  Future<void> _refreshAsset() async {
    final onUpdated = widget.onUpdated;
    if (onUpdated == null || _refreshing || asset.viewUrl.isEmpty) return;
    setState(() => _refreshing = true);
    try {
      final next = await botAssetDraftRefresh(widget.conn, asset);
      if (mounted) onUpdated(next);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _assetStyle(asset.sourceKind);
    final sheetNames = asset.includedSheetNames;
    const sheetAccent = Color(0xFF34A853);
    const metaStyle = TextStyle(color: _muted, fontSize: 11, height: 1.35);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: style.accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
            child: Icon(style.icon, size: 16, color: style.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(asset.accessLabel, style: metaStyle),
                if (sheetNames.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...sheetNames.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.table_chart_outlined, size: 14, color: sheetAccent),
                          const SizedBox(width: 6),
                          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _title, fontSize: 12, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  ),
                ] else if (asset.viewUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(asset.viewUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: metaStyle),
                  ),
              ],
            ),
          ),
          if (widget.onUpdated != null && asset.viewUrl.isNotEmpty)
            uiIconButton(
              tooltip: 'Refresh',
              visualDensity: VisualDensity.compact,
              onPressed: _refreshing ? null : _refreshAsset,
              icon: _refreshing
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _muted.withValues(alpha: 0.9)))
                  : const Icon(Icons.refresh, color: _muted, size: 20),
            ),
          if (widget.onRemove != null)
            uiIconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              onPressed: _refreshing ? null : () => _confirmRemove(context),
              icon: const Icon(Icons.close, color: _muted, size: 20),
            ),
        ],
      ),
    );
  }
}
