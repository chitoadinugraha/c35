import 'dart:math' show min;

import 'package:alienai_c35/c/site/guest_assistant_api.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_i18n.dart';
import 'package:alienai_c35/widgets/sites/ui_powered_by_alien.dart';
import 'package:flutter/material.dart';

Map<String, dynamic>? guestCartPayloadForChat(GuestSiteCartController? cart) {
  if (cart == null || cart.count <= 0) return null;
  final lines = [for (final l in cart.lines) l.orderItemJson()];
  if (lines.isEmpty) return null;
  return {'lines': lines};
}

class GuestSiteChatPanel extends StatefulWidget {
  const GuestSiteChatPanel({
    super.key,
    required this.siteIid,
    required this.title,
    required this.intro,
    required this.placeholder,
    required this.i18n,
    required this.accent,
    this.showPoweredBy = true,
    required this.onClose,
    this.cartPayload,
    this.bootMode = 'published',
  });

  final int siteIid;
  final String bootMode;
  final String title;
  final String intro;
  final String placeholder;
  final GuestSiteI18n i18n;
  final Color accent;
  final bool showPoweredBy;
  final VoidCallback onClose;
  final Map<String, dynamic>? cartPayload;

  @override
  State<GuestSiteChatPanel> createState() => _GuestSiteChatPanelState();
}

class _GuestSiteChatPanelState extends State<GuestSiteChatPanel> {
  final _controller = TextEditingController();
  final _messages = <_ChatMsg>[];
  String? _visitorId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final intro = widget.intro.trim();
    if (intro.isNotEmpty) {
      _messages.add(_ChatMsg(role: _ChatRole.assistant, text: intro));
    }
    GuestAssistantApi.visitorIdForSite(widget.siteIid).then((id) {
      if (mounted) setState(() => _visitorId = id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final visitorId = _visitorId;
    if (visitorId == null || visitorId.isEmpty) return;
    setState(() {
      _sending = true;
      _messages.add(_ChatMsg(role: _ChatRole.user, text: text));
      _controller.clear();
    });
    try {
      final reply = await GuestAssistantApi.sendChat(
        siteIid: widget.siteIid,
        visitorId: visitorId,
        message: text,
        cart: widget.cartPayload,
        bootMode: widget.bootMode,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMsg(
            role: _ChatRole.assistant,
            text: reply.trim().isEmpty ? '…' : reply,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMsg(role: _ChatRole.assistant, text: e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = widget.title.trim().isEmpty ? 'Chat' : widget.title.trim();

    return Container(
      width: min(360, MediaQuery.sizeOf(context).width - 32),
      height: min(480, MediaQuery.sizeOf(context).height * 0.72),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.i18n.assistantChatSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.isEmpty && widget.intro.trim().isEmpty ? 1 : _messages.length,
              itemBuilder: (context, i) {
                if (_messages.isEmpty && widget.intro.trim().isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                    child: Text(
                      widget.i18n.assistantChatEmpty(widget.title.trim().isEmpty ? 'Chat' : widget.title.trim()),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  );
                }
                final m = _messages[i];
                final isUser = m.role == _ChatRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUser ? widget.accent : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.showPoweredBy)
            const Center(child: UiPoweredByAlien(fontSize: 11)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_sending,
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send_rounded, color: widget.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChatRole { user, assistant }

class _ChatMsg {
  const _ChatMsg({required this.role, required this.text});
  final _ChatRole role;
  final String text;
}
