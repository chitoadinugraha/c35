import 'package:flutter/material.dart';

const _menuPadH = 16.0;

class UiSpeakToggleRow extends StatelessWidget {
  const UiSpeakToggleRow({super.key, required this.enabled, this.onChanged});

  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(_menuPadH, 10, _menuPadH, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Speak', style: TextStyle(color: Color(0xFFE4E4E7), fontSize: 14, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('Shorter response and read aloud', style: TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.25)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            UiAppToggle(value: enabled, onChanged: onChanged),
          ],
        ),
      );
}

class UiAppToggle extends StatelessWidget {
  const UiAppToggle({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 38,
          height: 22,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: value ? const Color(0xFF22C55E) : const Color(0xFF27272A),
            border: Border.all(color: value ? const Color(0xFF16A34A) : const Color(0xFF3F3F46)),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFFFFF),
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      );
}
