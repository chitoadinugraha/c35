import 'package:flutter/material.dart';

/// Leading icon + label for [DropdownMenuItem] / [selectedItemBuilder] rows.
class UiDropdownItem extends StatelessWidget {
  const UiDropdownItem({super.key, required this.icon, required this.label, this.iconSize = 18});

  final IconData icon;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: iconSize, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
