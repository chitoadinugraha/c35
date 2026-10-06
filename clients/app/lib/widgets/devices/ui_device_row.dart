import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);

class UiDeviceRow extends StatelessWidget {
  const UiDeviceRow({
    super.key,
    required this.name,
    this.kind = 'remote',
    this.type = '',
    this.browserEngine = '',
    this.pinned = false,
    this.clusterOnline = false,
    this.webrtcConnected = false,
    this.webrtcConnecting = false,
    this.webrtcFailed = false,
    this.selected = false,
    this.onTap,
  });

  final String name;
  final String kind;
  final String type;
  /// `extension` | `playwright` for `type=browser`; empty otherwise.
  final String browserEngine;
  final bool pinned;
  /// Agent session: device ↔ Alien AI Cloud (control plane, presence, tasks).
  final bool clusterOnline;
  /// WebRTC data plane: app ↔ device (screen, files, media — P2P or TURN).
  final bool webrtcConnected;
  final bool webrtcConnecting;
  /// Last WebRTC attempt failed (idle until user taps Connect / Retry).
  final bool webrtcFailed;
  final bool selected;
  final VoidCallback? onTap;

  String get _typeSubtitle => switch (type.toLowerCase()) {
        'browser' => browserEngine.toLowerCase() == 'extension' ? 'Chrome Extension' : 'Remote browser',
        'android' => 'Android',
        'windows' => 'Windows',
        _ => type,
      };

  /// Remote rows: Alien AI Cloud down replaces the type line.
  String get _subtitle =>
      kind.toLowerCase() == 'remote' && !clusterOnline ? 'Device is offline' : _typeSubtitle;

  String? get _engineBadge => type.toLowerCase() == 'browser'
      ? (browserEngine.toLowerCase() == 'extension' ? 'Extension' : 'Automated')
      : null;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF18181B) : Colors.transparent;
    final titleColor = selected ? const Color(0xFFF4F4F5) : const Color(0xFFA1A1AA);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: selected ? const BorderSide(color: _border) : BorderSide.none),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFF1C1C22),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _kindIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (pinned) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 12, color: Color(0xFFA1A1AA))),
                        Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w500))),
                      ],
                    ),
                    if (_subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(_subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                          ),
                          if (_engineBadge != null) ...[
                            const SizedBox(width: 6),
                            _engineBadgeChip(_engineBadge!),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(height: 36, child: Center(child: _connectionDots())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _connectionDots() {
    if (kind.toLowerCase() != 'remote') {
      return _dot(clusterOnline, clusterOnline ? 'Online' : 'Device is offline');
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(clusterOnline, clusterOnline ? 'Alien AI Cloud' : 'Device is offline'),
        const SizedBox(width: 5),
        _webrtcDot(),
      ],
    );
  }

  Widget _webrtcDot() {
    final (color, border, tooltip) = webrtcConnected
        ? (const Color(0xFF22C55E), const Color(0xFF14532D), 'Connected (WebRTC)')
        : webrtcConnecting
            ? (const Color(0xFFF59E0B), const Color(0xFF78350F), 'Connecting (WebRTC)')
            : webrtcFailed
                ? (const Color(0xFFEF4444), const Color(0xFF7F1D1D), 'Could not connect (WebRTC)')
                : (const Color(0xFF3F3F46), const Color(0xFF27272A), 'Not connected — tap Connect in device view');
    return uiTooltip(
      message: tooltip,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: border)),
      ),
    );
  }

  Widget _dot(bool on, String tooltip) => uiTooltip(
        message: tooltip,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? const Color(0xFF22C55E) : const Color(0xFF3F3F46),
            border: Border.all(color: on ? const Color(0xFF14532D) : const Color(0xFF27272A)),
          ),
        ),
      );

  Widget _engineBadgeChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _border),
        ),
        child: Text(label, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 10, fontWeight: FontWeight.w500)),
      );

  Widget _kindIcon() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
        child: Center(child: _kindIconInner()),
      );

  Widget _kindIconInner() {
    final t = type.toLowerCase();
    if (t == 'browser' && browserEngine.toLowerCase() == 'extension') {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            'https://www.google.com/s2/favicons?domain=chrome.google.com&sz=64',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 18, color: Color(0xFFA1A1AA)),
          ),
        ),
      );
    }
    if (t == 'android') {
      return Padding(padding: const EdgeInsets.all(6), child: UiIcon('logos:android-icon', size: 22, recolor: false));
    }
    if (t == 'windows') {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: SvgPicture.asset('assets/icons/windows.svg', width: 24, height: 24, fit: BoxFit.contain),
      );
    }
    return Icon(_iconForKind(kind, type), size: 18, color: const Color(0xFFA1A1AA));
  }

  IconData _iconForKind(String k, String deviceType) => switch (deviceType.toLowerCase()) {
        'browser' => Icons.public_outlined,
        _ => switch (k.toLowerCase()) {
            'iot' => Icons.sensors_outlined,
            'remote' => Icons.laptop_mac_outlined,
            _ => Icons.devices_other_outlined,
          },
      };
}
