import 'package:alienai_c35/c/site/guest_assistant_api.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
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
    required this.intro,
    required this.placeholder,
    required this.onClose,
    this.cartPayload,
    this.bootMode = 'published',
  });

  final int siteIid;
  final String bootMode;
  final String intro;
  final String placeholder;
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
    return Container(
      width: 360,
      height: 480,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3F3F46)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                const Text('Alien AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == _ChatRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF3F3D39) : const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_sending,
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      filled: true,
                      fillColor: const Color(0xFF27272A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
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
                      : const Icon(Icons.send, color: Colors.white),
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
