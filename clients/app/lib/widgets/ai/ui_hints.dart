import 'package:alienai_c35/c/chat/space_hints.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:flutter/material.dart';

const _chipBg = Color(0xFF18181B);
const _chipBorder = Color(0xFF27272A);
const _chipText = Color(0xFFE4E4E7);
const _menuIcon = Color(0xFFA1A1AA);

class UiHints extends StatelessWidget {
  const UiHints({super.key, required this.hints, required this.onPick});

  final List<HintItem> hints;
  final ValueChanged<HintItem> onPick;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [for (final h in hints) _hintChip(context, h)],
      );

  Widget _hintChip(BuildContext context, HintItem item) {
    if (item.items.isNotEmpty) {
      return MenuAnchor(
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xFF18181B)),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(6),
        ),
        menuChildren: _menuChildren(item.items),
        builder: (context, controller, child) => ActionChip(
          label: _chipLabel(item),
          backgroundColor: _chipBg,
          side: const BorderSide(color: _chipBorder),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        ),
      );
    }
    return ActionChip(
      label: _chipLabel(item),
      backgroundColor: _chipBg,
      side: const BorderSide(color: _chipBorder),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () => onPick(item),
    );
  }

  List<Widget> _menuChildren(List<HintItem> items) => [
        for (final child in items)
          if (child.items.isNotEmpty)
            SubmenuButton(
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
              menuChildren: _menuChildren(child.items),
              child: _menuRow(child),
            )
          else
            MenuItemButton(
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
              onPressed: () => onPick(child),
              child: _menuRow(child),
            ),
      ];

  Widget _chipLabel(HintItem item) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hintMenuIcon(item), size: 15, color: const Color(0xFF71717A)),
          const SizedBox(width: 6),
          Text(item.label, style: const TextStyle(color: _chipText, fontSize: 13)),
          if (item.items.isNotEmpty) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF71717A)),
          ],
        ],
      );

  Widget _menuRow(HintItem item) => Row(
        children: [
          Icon(hintMenuIcon(item), size: 18, color: _menuIcon),
          const SizedBox(width: 10),
          Expanded(child: Text(item.label, style: const TextStyle(color: _chipText, fontSize: 13))),
        ],
      );
}
