import 'dart:async';

import 'package:alienai_c35/c/site/site_ai_assistant.dart';
import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_chat_panel.dart';
import 'package:alienai_c35/widgets/ai/alien_icon_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Guest storefront chat / call chrome (preview + published parity target).
class GuestSiteAssistantLayer extends StatefulWidget {
  const GuestSiteAssistantLayer({super.key, required this.boot, required this.child});

  final GuestSiteBoot boot;
  final Widget child;

  @override
  State<GuestSiteAssistantLayer> createState() => _GuestSiteAssistantLayerState();
}

class _GuestSiteAssistantLayerState extends State<GuestSiteAssistantLayer> {
  var _chatOpen = false;
  var _callActive = false;
  Timer? _callTimer;
  var _callSeconds = 0;

  SiteAiAssistantDraft get _ai => siteAiAssistantRead(widget.boot.meta['ai_assistant']);

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  void _toggleChat() => setState(() => _chatOpen = !_chatOpen);

  void _startCall() {
    setState(() {
      _callActive = true;
      _callSeconds = 0;
    });
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    setState(() => _callActive = false);
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cart = GuestSiteCartScope.maybeOf(context);
    final showChat = _ai.featureChatEnabled;
    final showCall = _ai.featureCallEnabled;
    if (!showChat && !showCall) return widget.child;

    return Stack(
      children: [
        widget.child,
        if (_chatOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleChat,
              child: ColoredBox(
                color: Colors.black54,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: GuestSiteChatPanel(
                      siteIid: widget.boot.siteIid,
                      bootMode: widget.boot.mode,
                      intro: _ai.chatIntro,
                      placeholder: _ai.chatPlaceholder,
                      onClose: _toggleChat,
                      cartPayload: guestCartPayloadForChat(cart),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_callActive)
          Positioned.fill(
            child: Material(
              color: Colors.black87,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volume_up, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(_formatDuration(_callSeconds), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      _ai.callIntro.trim().isEmpty ? 'Alien AI call' : _ai.callIntro.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      onPressed: _endCall,
                      child: const Text('End call'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (cart != null && cart.count > 0 && !cart.sheetOpen && showChat)
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) => Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  _AssistantFab(
                    key: const Key('guest-assistant-chat-cart'),
                    alien: true,
                    icon: Icons.chat_bubble_outline,
                    onTap: _toggleChat,
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        if (!(cart != null && cart.count > 0 && !cart.sheetOpen) || !showChat)
          Positioned(
            right: 16,
            bottom: cart != null && cart.count > 0 && !cart.sheetOpen ? 88 : 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showChat && !(cart != null && cart.count > 0 && !cart.sheetOpen))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AssistantFab(
                      key: const Key('guest-assistant-chat'),
                      alien: true,
                      icon: Icons.chat_bubble_outline,
                      onTap: _toggleChat,
                    ),
                  ),
                if (showCall)
                  _AssistantFab(
                    key: const Key('guest-assistant-call'),
                    alien: false,
                    icon: Icons.phone_in_talk_outlined,
                    onTap: _startCall,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AssistantFab extends StatelessWidget {
  const _AssistantFab({super.key, required this.alien, required this.icon, required this.onTap});

  final bool alien;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 6,
        shape: const CircleBorder(),
        color: alien ? Colors.black : const Color(0xFF34D399),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: alien
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.string(alienIconSvg, fit: BoxFit.contain),
                  )
                : Icon(icon, color: Colors.white),
          ),
        ),
      );
}
