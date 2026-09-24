import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiConnWifi extends StatefulWidget {
  const UiConnWifi({super.key, required this.conn});

  final ChatConn conn;

  @override
  State<UiConnWifi> createState() => _UiConnWifiState();
}

class _UiConnWifiState extends State<UiConnWifi> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(begin: 0.35, end: 1).animate(CurvedAnimation(parent: _blink, curve: Curves.easeInOut));

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChatConnStatus>(
        valueListenable: widget.conn.status,
        builder: (_, s, __) {
          if (s == ChatConnStatus.connected) return const SizedBox.shrink();
          final color = s == ChatConnStatus.disconnected ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
          final tooltip = switch (s) {
            ChatConnStatus.disconnected => 'Offline',
            ChatConnStatus.connecting => 'Connecting…',
            ChatConnStatus.reconnecting => 'Reconnecting…',
            ChatConnStatus.connected => '',
          };
          return uiTooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FadeTransition(
                opacity: _opacity,
                child: Icon(Icons.wifi_rounded, size: 17, color: color),
              ),
            ),
          );
        },
      );
}
