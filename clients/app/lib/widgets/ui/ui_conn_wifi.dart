import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiConnWifi extends StatefulWidget {
  const UiConnWifi({
    super.key,
    required this.conn,
    this.onReconnect,
    this.showLabel = false,
    this.alwaysVisible = false,
  });

  final ChatConn conn;
  final Future<void> Function()? onReconnect;
  final bool showLabel;
  final bool alwaysVisible;

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
    } catch (_) {
    } finally {
      if (mounted) _reconnectBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChatConnStatus>(
        valueListenable: widget.conn.status,
        builder: (_, s, __) {
          if (s == ChatConnStatus.connected) {
            if (!widget.alwaysVisible) return const SizedBox.shrink();
            return uiTooltip(
              message: 'Online',
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => unawaited(_reconnect()),
                    child: const Icon(Icons.wifi_rounded, size: 17, color: Color(0xFF10B981)),
                  ),
                ),
              ),
            );
          }
          final color = s == ChatConnStatus.disconnected ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
          final label = switch (s) {
            ChatConnStatus.disconnected => 'Offline Mode',
            ChatConnStatus.connecting => 'Connecting…',
            ChatConnStatus.reconnecting => 'Reconnecting…',
            ChatConnStatus.connected => 'Online',
          };
          final tooltip = switch (s) {
            ChatConnStatus.disconnected => 'Offline Mode — tap to reconnect',
            ChatConnStatus.connecting => 'Connecting… — tap to retry',
            ChatConnStatus.reconnecting => 'Reconnecting… — tap to retry',
            ChatConnStatus.connected => '',
          };
          final icon = (s == ChatConnStatus.disconnected && widget.showLabel)
              ? Icons.wifi_off_rounded
              : Icons.wifi_rounded;

          return uiTooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => unawaited(_reconnect()),
                  child: widget.showLabel
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FadeTransition(
                                opacity: _opacity,
                                child: Icon(icon, size: 14, color: color),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : FadeTransition(
                          opacity: _opacity,
                          child: Icon(icon, size: 17, color: color),
                        ),
                ),
              ),
            ),
          );
        },
      );
}
