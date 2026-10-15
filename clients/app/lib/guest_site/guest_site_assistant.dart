import 'package:alienai_c35/c/site/site_ai_assistant.dart';
import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_chat_panel.dart';
import 'package:alienai_c35/guest_site/guest_site_live_call.dart';
import 'package:alienai_c35/widgets/ai/alien_icon_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            GuestSiteLiveCallOverlay(
              controller: _callController,
              intro: _ai.callIntro,
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
                        busy: isConnecting,
                        onTap: isConnecting ? null : _startCall,
                      ),
                  ],
                ),
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
    required this.alien,
    required this.icon,
    this.busy = false,
    this.onTap,
  });

  final bool alien;
  final IconData icon;
  final bool busy;
  final VoidCallback? onTap;

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
                : alien
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.string(alienIconSvg, fit: BoxFit.contain),
                      )
                    : Icon(icon, color: Colors.white),
          ),
        ),
      );
}
