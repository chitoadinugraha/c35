import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/chat/space_hints.dart';
import 'package:alienai_c35/c/hint/hint_chip_theme.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:alienai_c35/widgets/ai/ui_hint_chip.dart';
import 'package:flutter/material.dart';

const _chipText = Color(0xFFE4E4E7);
const _menuIcon = Color(0xFFA1A1AA);

class UiHints extends StatelessWidget {
  const UiHints({super.key, required this.hints, required this.onPick});

  final List<HintItem> hints;
  final ValueChanged<HintItem> onPick;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: catalogTranslationTick,
        builder: (context, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [for (final h in hints) _hintChip(context, h)],
        ),
      );

  Widget _hintChip(BuildContext context, HintItem item) {
    final theme = HintChipTheme.forKey(item.theme);
    if (item.items.isNotEmpty) {
      return MenuAnchor(
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xFF18181B)),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(6),
        ),
        menuChildren: _menuChildren(item.items),
        builder: (context, controller, child) => UiHintChip(
          theme: theme,
          icon: hintMenuIcon(item),
          showChevron: true,
          label: Text(hintItemLabel(item)),
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
    return UiHintChip(
      theme: theme,
      icon: hintMenuIcon(item),
      label: Text(hintItemLabel(item)),
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

  Widget _menuRow(HintItem item) => Row(
        children: [
          Icon(hintMenuIcon(item), size: 18, color: _menuIcon),
          const SizedBox(width: 10),
          Expanded(child: Text(hintItemLabel(item), style: const TextStyle(color: _chipText, fontSize: 13))),
        ],
      );
}
