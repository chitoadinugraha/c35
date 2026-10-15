import 'dart:async';

import 'package:alienai_c35/c/channel/channel_api.dart';
import 'package:alienai_c35/c/device/device_api.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_assistant_bot.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:alienai_c35/widgets/bots/io_channel_telegram_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_meta_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_pair.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:fixnum/fixnum.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteAiChannelsSection extends StatefulWidget {
  const UiSiteAiChannelsSection({
    super.key,
    required this.api,
    required this.siteIid,
    required this.siteName,
    this.connectRequestNonce = 0,
  });

  final SiteApi api;
  final int siteIid;
  final String siteName;
  final int connectRequestNonce;

  @override
  State<UiSiteAiChannelsSection> createState() => _UiSiteAiChannelsSectionState();
}

class _UiSiteAiChannelsSectionState extends State<UiSiteAiChannelsSection> {
  var _loading = true;
  String? _error;
  List<BotChannelDoc> _channels = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void didUpdateWidget(covariant UiSiteAiChannelsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) {
      unawaited(_reload());
      return;
    }
    if (widget.connectRequestNonce != oldWidget.connectRequestNonce && widget.connectRequestNonce > 0) {
      unawaited(_connectChannel());
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await widget.api.configGet(widget.siteIid);
      final botIid = siteAssistantBotIidFromCapabilities(config.capabilitiesJson);
      if (botIid == null) {
        _channels = const [];
        return;
      }
      final list = await identityList(widget.api.conn, const ['bot']);
      var meta = '';
      for (final row in list.rows) {
        if (row.identity.iid == Int64(botIid)) {
          meta = row.identity.metaJson;
          break;
        }
      }
      _channels = botChannelsParse(meta);
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectChannel() async {
    try {
      final botIid = await siteAssistantBotEnsure(
        conn: widget.api.conn,
        api: widget.api,
        siteIid: widget.siteIid,
        siteName: widget.siteName,
      );
      if (!mounted) return;
      final picked = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => Material(
          color: const Color(0xFF18181B),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                leading: const Icon(Icons.telegram, color: _accent),
                title: const Text('Telegram', style: TextStyle(color: _text)),
                onTap: () => Navigator.pop(ctx, 'telegram'),
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: _accent),
                title: const Text('WhatsApp (QR device)', style: TextStyle(color: _text)),
                onTap: () => Navigator.pop(ctx, 'wa_pair'),
              ),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined, color: _accent),
                  title: const Text('WhatsApp (Meta API)', style: TextStyle(color: _text)),
                  onTap: () => Navigator.pop(ctx, 'wa_meta'),
                ),
              ],
            ),
          ),
        ),
      );
      if (picked == null || !mounted) return;
      switch (picked) {
        case 'telegram':
          await ioChannelTelegramConnectShow(context, botIid: botIid, onConnect: channelTelegramConnectFn(widget.api.conn));
        case 'wa_pair':
          await ioChannelWhatsappPairShow(
            context,
            botIid: botIid,
            onStart: channelWhatsappPairStartFn(widget.api.conn),
            onWatch: channelWhatsappPairWatchFn(widget.api.conn),
            onAbort: channelWhatsappPairAbortFn(widget.api.conn),
          );
        case 'wa_meta':
          await ioChannelWhatsappMetaConnectShow(context, botIid: botIid, onConnect: channelWhatsappMetaConnectFn(widget.api.conn));
      }
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Text(_error!, style: const TextStyle(color: _muted, fontSize: 12)),
      );
    }
    if (_channels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          children: [
            const UiEmptyState(
              icon: Icons.hub_outlined,
              title: 'No channels yet',
              subtitle: 'Connect Telegram or WhatsApp for this site.',
              actionHint: 'Use + then Connect channel',
            ),
            TextButton(onPressed: _connectChannel, child: const Text('Connect channel')),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          for (final ch in _channels) ...[
            _ChannelRow(channel: ch, onTap: () => unawaited(_reload())),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.onTap});

  final BotChannelDoc channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon, accent) = channelDisplay(channel);
    final active = channelIsActive(channel);
    return Material(
      color: siteEditorCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: siteEditorFieldBorder.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(active ? 'Connected' : channel.status, style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}
