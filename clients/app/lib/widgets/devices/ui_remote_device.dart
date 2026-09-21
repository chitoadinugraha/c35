import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _panel = Color(0xFF111114);

class UiRemoteDevice extends StatelessWidget {
  const UiRemoteDevice({super.key, required this.deviceName, this.online = false});

  final String deviceName;
  final bool online;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFF08080A),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Remote control — coming soon', style: TextStyle(color: _muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  _statusBadge(online),
                ],
              ),
              const SizedBox(height: 16),
              _toolbar(),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                  child: const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(child: Icon(Icons.desktop_windows_outlined, size: 64, color: Color(0xFF3F3F46))),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statusBadge(bool online) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: online ? const Color(0xFF14532D) : const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: online ? const Color(0xFF22C55E) : const Color(0xFF3F3F46)),
        ),
        child: Text(
          online ? 'Online' : 'Offline',
          style: TextStyle(color: online ? const Color(0xFF86EFAC) : _muted, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );

  Widget _toolbar() => Row(
        children: [
          _toolBtn(Icons.mouse_outlined, 'Mouse'),
          const SizedBox(width: 8),
          _toolBtn(Icons.keyboard_outlined, 'Keyboard'),
          const SizedBox(width: 8),
          _toolBtn(Icons.fullscreen_outlined, 'Fullscreen'),
        ],
      );

  Widget _toolBtn(IconData icon, String tooltip) => Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: null,
          icon: Icon(icon, size: 20, color: const Color(0xFF52525B)),
          style: IconButton.styleFrom(
            backgroundColor: _panel,
            disabledBackgroundColor: _panel,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
          ),
        ),
      );
}
