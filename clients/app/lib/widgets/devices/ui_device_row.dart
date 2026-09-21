import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);

class UiDeviceRow extends StatelessWidget {
  const UiDeviceRow({
    super.key,
    required this.name,
    this.kind = 'remote',
    this.type = '',
    this.pinned = false,
    this.online = false,
    this.selected = false,
    this.onTap,
  });

  final String name;
  final String kind;
  final String type;
  final bool pinned;
  final bool online;
  final bool selected;
  final VoidCallback? onTap;

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
            children: [
              _kindIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (pinned) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 12, color: Color(0xFFA1A1AA))),
                        Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w500))),
                      ],
                    ),
                    if (type.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(type, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _onlineDot(online),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kindIcon() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
        child: Icon(_iconForKind(kind), size: 18, color: const Color(0xFFA1A1AA)),
      );

  Widget _onlineDot(bool online) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: online ? const Color(0xFF22C55E) : const Color(0xFF3F3F46),
          border: Border.all(color: online ? const Color(0xFF14532D) : const Color(0xFF27272A)),
        ),
      );

  IconData _iconForKind(String k) => switch (k.toLowerCase()) {
        'iot' => Icons.sensors_outlined,
        'remote' => Icons.laptop_mac_outlined,
        _ => Icons.devices_other_outlined,
      };
}
