import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);

typedef UiSiteCatalogReorderBuilder = Widget Function(BuildContext context, int index, Widget dragHandle);

class UiSiteCatalogReorder extends StatelessWidget {
  const UiSiteCatalogReorder({
    super.key,
    required this.itemCount,
    required this.onReorder,
    required this.itemBuilder,
  });

  final int itemCount;
  final void Function(int oldIndex, int newIndex) onReorder;
  final UiSiteCatalogReorderBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: itemCount,
        onReorder: onReorder,
        proxyDecorator: (child, index, animation) => Material(
          color: const Color(0xFF18181B),
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
        itemBuilder: (ctx, i) {
          final handle = ReorderableDragStartListener(
            index: i,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.drag_handle, size: 20, color: Color(0xFF71717A)),
            ),
          );
          return Container(
            key: ValueKey(i),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.6)))),
            child: itemBuilder(ctx, i, handle),
          );
        },
      );
}
