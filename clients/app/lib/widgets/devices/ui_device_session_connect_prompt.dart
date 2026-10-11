import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter/material.dart';

/// Shared copy for Remote and Files connect prompts.
const kDeviceSessionWebrtcDesc =
    'Streams directly to your device over WebRTC — nothing passes through the server.';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

enum UiDeviceSessionConnectAction { none, connect, refresh }

/// Idle / offline connect UI for device Remote and Files tabs.
class UiDeviceSessionConnectPrompt extends StatelessWidget {
  const UiDeviceSessionConnectPrompt({
    super.key,
    required this.icon,
    required this.title,
    this.description = '',
    this.action = UiDeviceSessionConnectAction.none,
    this.connecting = false,
    this.onConnect,
    this.presenceRefreshing = false,
    this.onPresenceRefresh,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String description;
  final UiDeviceSessionConnectAction action;
  final bool connecting;
  final VoidCallback? onConnect;
  final bool presenceRefreshing;
  final VoidCallback? onPresenceRefresh;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Icon(icon, size: 28, color: _muted),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.45),
                ),
              ],
              if (extra != null) ...[const SizedBox(height: 12), extra!],
              if (action != UiDeviceSessionConnectAction.none) ...[
                const SizedBox(height: 20),
                _primaryAction(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryAction() {
    if (action == UiDeviceSessionConnectAction.connect) {
      return FilledButton.icon(
        onPressed: connecting ? null : onConnect,
        icon: connecting
            ? const UILoadingIndicator(size: 16, strokeWidth: 2, color: _text)
            : const Icon(Icons.link, size: 18),
        label: Text(connecting ? 'Connecting…' : 'Connect'),
      );
    }
    return FilledButton.icon(
      onPressed: presenceRefreshing ? null : onPresenceRefresh,
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF27272A), foregroundColor: _text),
      icon: presenceRefreshing
          ? const UILoadingIndicator(size: 16, strokeWidth: 2, color: _muted)
          : const Icon(Icons.refresh_rounded, size: 18),
      label: Text(presenceRefreshing ? 'Checking…' : 'Refresh'),
    );
  }
}
