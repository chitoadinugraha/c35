import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class ChatMessageMenuStyle {
  static const panelBg = Color(0xFF18181B);
  static const panelBorder = Color(0xFF27272A);
  static const rowHover = Color(0xFF27272A);
  static const rowText = Color(0xFFF4F4F5);
  static const rowMuted = Color(0xFFA1A1AA);
  static const rowIconHover = rowMuted;
  static const minWidth = 184.0;
  static const maxWidth = 240.0;
}

sealed class ChatMessageMenuItem {
  const ChatMessageMenuItem();
}

class ChatMessageMenuAction extends ChatMessageMenuItem {
  const ChatMessageMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.shortcut,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? shortcut;
}

class ChatMessageMenuDivider extends ChatMessageMenuItem {
  const ChatMessageMenuDivider();
}

class ChatMessageMenuButtonRow extends ChatMessageMenuItem {
  const ChatMessageMenuButtonRow({required this.actions});

  final List<ChatMessageMenuAction> actions;
}

class ChatMessageContextMenu extends StatelessWidget {
  const ChatMessageContextMenu({super.key, required this.anchors, required this.items});

  final TextSelectionToolbarAnchors anchors;
  final List<ChatMessageMenuItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final preferAbove = switch (Theme.of(context).platform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    return CustomSingleChildLayout(
      delegate: _ChatMenuLayoutDelegate(
        anchor: anchors.primaryAnchor,
        fallbackAnchor: anchors.secondaryAnchor,
        preferAbove: preferAbove,
      ),
      child: TapRegion(
        onTapOutside: (_) => ContextMenuController.removeAny(),
        child: _ChatMessageMenuPanel(items: items),
      ),
    );
  }
}

class _ChatMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _ChatMenuLayoutDelegate({required this.anchor, this.fallbackAnchor, this.preferAbove = false});

  final Offset anchor;
  final Offset? fallbackAnchor;
  final bool preferAbove;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxW = math.min(constraints.maxWidth, ChatMessageMenuStyle.maxWidth);
    return BoxConstraints(minWidth: ChatMessageMenuStyle.minWidth, maxWidth: maxW, maxHeight: constraints.maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gap = 8.0;
    const pad = 8.0;
    final secondary = fallbackAnchor;
    final selectionTop = secondary != null ? math.min(anchor.dy, secondary.dy) : anchor.dy;
    final selectionBottom = secondary != null ? math.max(anchor.dy, secondary.dy) : anchor.dy;
    final centerX = secondary != null ? (anchor.dx + secondary.dx) / 2 : anchor.dx;
    final belowTop = selectionBottom + gap;
    final aboveTop = selectionTop - childSize.height - gap;
    final fitsBelow = belowTop + childSize.height <= size.height - pad;
    final fitsAbove = aboveTop >= pad;
    final useAbove = preferAbove ? fitsAbove || !fitsBelow : !fitsBelow && fitsAbove;
    final top = (useAbove ? aboveTop : belowTop).clamp(pad, math.max(pad, size.height - childSize.height - pad)).toDouble();
    var left = centerX - childSize.width / 2;
    if (left + childSize.width > size.width - pad) left = size.width - childSize.width - pad;
    if (left < pad) left = pad;
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant _ChatMenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.fallbackAnchor != fallbackAnchor || oldDelegate.preferAbove != preferAbove;
}

class _ChatMessageMenuPanel extends StatelessWidget {
  const _ChatMessageMenuPanel({required this.items});

  final List<ChatMessageMenuItem> items;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          constraints: const BoxConstraints(minWidth: ChatMessageMenuStyle.minWidth, maxWidth: ChatMessageMenuStyle.maxWidth),
          decoration: BoxDecoration(
            color: ChatMessageMenuStyle.panelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ChatMessageMenuStyle.panelBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 28, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items)
                  if (item is ChatMessageMenuDivider)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Divider(height: 1, thickness: 1, color: ChatMessageMenuStyle.panelBorder),
                    )
                  else if (item is ChatMessageMenuAction)
                    _ChatMessageMenuRow(action: item)
                  else if (item is ChatMessageMenuButtonRow && item.actions.length == 2)
                    Row(
                      children: [
                        for (final action in item.actions) Expanded(child: _ChatMessageMenuHalfButton(action: action)),
                      ],
                    ),
              ],
            ),
          ),
        ),
      );
}

class _ChatMessageMenuHalfButton extends StatefulWidget {
  const _ChatMessageMenuHalfButton({required this.action});

  final ChatMessageMenuAction action;

  @override
  State<_ChatMessageMenuHalfButton> createState() => _ChatMessageMenuHalfButtonState();
}

class _ChatMessageMenuHalfButtonState extends State<_ChatMessageMenuHalfButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final act = widget.action;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? ChatMessageMenuStyle.rowHover : Colors.transparent,
        child: InkWell(
          onTap: act.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(act.icon, size: 16, color: ChatMessageMenuStyle.rowText),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    act.label,
                    style: const TextStyle(color: ChatMessageMenuStyle.rowText, fontSize: 13, fontWeight: FontWeight.w500, height: 1.2),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessageMenuRow extends StatefulWidget {
  const _ChatMessageMenuRow({required this.action});

  final ChatMessageMenuAction action;

  @override
  State<_ChatMessageMenuRow> createState() => _ChatMessageMenuRowState();
}

class _ChatMessageMenuRowState extends State<_ChatMessageMenuRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final act = widget.action;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? ChatMessageMenuStyle.rowHover : Colors.transparent,
        child: InkWell(
          onTap: act.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(act.icon, size: 16, color: _hovered ? ChatMessageMenuStyle.rowIconHover : ChatMessageMenuStyle.rowMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    act.label,
                    style: const TextStyle(color: ChatMessageMenuStyle.rowText, fontSize: 13, fontWeight: FontWeight.w500, height: 1.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (act.shortcut != null)
                  Text(act.shortcut!, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showChatListMenu({required BuildContext context, required Offset global, required List<ChatMessageMenuItem> items}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (ctx) {
      final wrapped = [
        for (final item in items)
          if (item is ChatMessageMenuAction)
            ChatMessageMenuAction(
              label: item.label,
              icon: item.icon,
              shortcut: item.shortcut,
              onPressed: () {
                Navigator.of(ctx).pop();
                item.onPressed();
              },
            )
          else
            item,
      ];
      return Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: () => Navigator.of(ctx).pop(), behavior: HitTestBehavior.opaque)),
          ChatMessageContextMenu(anchors: TextSelectionToolbarAnchors(primaryAnchor: global), items: wrapped),
        ],
      );
    },
  );
}
