import 'package:alienai_c35/c/site/site_ai_assistant.dart';
import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_i18n.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_chat_panel.dart';
import 'package:alienai_c35/guest_site/guest_site_live_call.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Guest storefront chat / call chrome (preview + published parity target).
class GuestSiteAssistantLayer extends StatefulWidget {
  const GuestSiteAssistantLayer({
    super.key,
    required this.boot,
    required this.child,
    this.callController,
    this.httpClient,
  });

  final GuestSiteBoot boot;
  final Widget child;
  final GuestSiteLiveCallController? callController;
  final http.Client? httpClient;

  @override
  State<GuestSiteAssistantLayer> createState() => _GuestSiteAssistantLayerState();
}

class _GuestSiteAssistantLayerState extends State<GuestSiteAssistantLayer> {
  var _chatOpen = false;
  late final GuestSiteLiveCallController _callController;
  late final bool _ownsCallController;

  SiteAiAssistantDraft get _ai => siteAiAssistantRead(widget.boot.meta['ai_assistant']);

  GuestSiteI18n get _i18n => GuestSiteI18n.fromMeta(widget.boot.meta);

  String _resolveChatTitle() {
    final custom = _ai.chatTitle.trim();
    if (custom.isNotEmpty) return custom;
    final name = widget.boot.name.trim();
    if (name.isNotEmpty) return name;
    return 'Chat';
  }

  String _chatPlaceholder() {
    final raw = _ai.chatPlaceholder.trim();
    if (raw.isNotEmpty) return raw;
    return _i18n.assistantPlaceholderDefault;
  }

  @override
  void initState() {
    super.initState();
    if (widget.callController != null) {
      _callController = widget.callController!;
      _ownsCallController = false;
    } else {
      _callController = GuestSiteLiveCallController();
      _ownsCallController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsCallController) {
      _callController.dispose();
    }
    super.dispose();
  }

  void _toggleChat() => setState(() => _chatOpen = !_chatOpen);

  void _startCall() {
    _callController.start(
      siteIid: widget.boot.siteIid,
      bootMode: widget.boot.mode,
      client: widget.httpClient,
    );
  }


  @override
  Widget build(BuildContext context) {
    final cart = GuestSiteCartScope.maybeOf(context);
    final showChat = _ai.featureChatEnabled;
    final showCall = _ai.featureCallEnabled;
    if (!showChat && !showCall) return widget.child;

    return ListenableBuilder(
      listenable: _callController,
      builder: (context, _) {
        final isConnecting = _callController.state == GuestSiteLiveCallState.connecting;
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
                          title: _resolveChatTitle(),
                          intro: _ai.chatIntro,
                          placeholder: _chatPlaceholder(),
                          i18n: _i18n,
                          accent: widget.boot.commerceAccent,
                          showPoweredBy: _ai.showPoweredBy,
                          onClose: _toggleChat,
                          cartPayload: guestCartPayloadForChat(cart),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            GuestSiteLiveCallOverlay(
              controller: _callController,
              intro: _ai.callIntro,
            ),
            if (showChat || showCall)
              ListenableBuilder(
                listenable: cart ?? _callController,
                builder: (context, _) {
                  final cartBarUp = cart != null && cart.count > 0 && !cart.sheetOpen;
                  return Positioned(
                    right: 16,
                    bottom: cartBarUp ? 88 : 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showChat)
                          Padding(
                            padding: EdgeInsets.only(bottom: showCall ? 10 : 0),
                            child: _AssistantFab(
                              key: const Key('guest-assistant-chat'),
                              icon: Icons.chat_bubble_outline,
                              color: widget.boot.commerceAccent,
                              onTap: _toggleChat,
                            ),
                          ),
                        if (showCall)
                          _AssistantFab(
                            key: const Key('guest-assistant-call'),
                            icon: Icons.phone_in_talk_outlined,
                            color: widget.boot.commerceAccent,
                            busy: isConnecting,
                            onTap: isConnecting ? null : _startCall,
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _AssistantFab extends StatelessWidget {
  const _AssistantFab({
    super.key,
    required this.icon,
    required this.color,
    this.busy = false,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 6,
        shadowColor: color.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        color: color,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      );
}
