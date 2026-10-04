import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiConnWifi extends StatefulWidget {
  const UiConnWifi({super.key, required this.conn, this.onReconnect});

  final ChatConn conn;
  final Future<void> Function()? onReconnect;

  @override
  State<UiConnWifi> createState() => _UiConnWifiState();
}

class _UiConnWifiState extends State<UiConnWifi> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _opacity = Tween<double>(begin: 0.35, end: 1).animate(CurvedAnimation(parent: _blink, curve: Curves.easeInOut));
  var _reconnectBusy = false;

  @override
  void initState() {
    super.initState();
    widget.conn.status.addListener(_syncBlink);
    _syncBlink();
  }

  void _syncBlink() {
    final offline = widget.conn.status.value != ChatConnStatus.connected;
    if (offline) {
      if (!_blink.isAnimating) _blink.repeat(reverse: true);
    } else {
      _blink.stop();
      _blink.value = 1;
    }
  }

  @override
  void dispose() {
    widget.conn.status.removeListener(_syncBlink);
    _blink.dispose();
    super.dispose();
  }

  Future<void> _reconnect() async {
    if (_reconnectBusy) return;
    _reconnectBusy = true;
    try {
      final fn = widget.onReconnect ?? widget.conn.reconnect;
      await fn();
    } catch (_) {}
    if (mounted) _reconnectBusy = false;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChatConnStatus>(
        valueListenable: widget.conn.status,
        builder: (_, s, __) {
          if (s == ChatConnStatus.connected) return const SizedBox.shrink();
          final color = s == ChatConnStatus.disconnected ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
          final tooltip = switch (s) {
            ChatConnStatus.disconnected => 'Offline — tap to reconnect',
            ChatConnStatus.connecting => 'Connecting… — tap to retry',
            ChatConnStatus.reconnecting => 'Reconnecting… — tap to retry',
            ChatConnStatus.connected => '',
          };
          return uiTooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => unawaited(_reconnect()),
                  child: FadeTransition(
                    opacity: _opacity,
                    child: Icon(Icons.wifi_rounded, size: 17, color: color),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
