import 'package:alienai_c35/c/chat/space_hints.dart';
import 'package:flutter/material.dart';

class UiHints extends StatelessWidget {
  const UiHints({super.key, required this.hints, required this.onPick});

  final List<SpaceHint> hints;
  final ValueChanged<SpaceHint> onPick;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final h in hints)
            ActionChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_hintIcon(h.icon), size: 15, color: const Color(0xFF71717A)),
                  const SizedBox(width: 6),
                  Text(h.label, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 13)),
                ],
              ),
              backgroundColor: const Color(0xFF18181B),
              side: const BorderSide(color: Color(0xFF27272A)),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              onPressed: () => onPick(h),
            ),
        ],
      );

  IconData _hintIcon(String icon) => hintIconFallback(icon) ?? Icons.lightbulb_outline;
}
