import 'dart:async';

import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_trace_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showMsgTraceBottomSheet(BuildContext context, {required String reqId, required ChatConn conn, int msgId = 0}) async {
  if (reqId.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No trace available'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    }
    return;
  }
  await showMsgTraceSheet(context, reqId: reqId.trim(), conn: conn, msgId: msgId);
}

List<ChatMessageMenuItem> msgBubbleMenuItems(
  BuildContext context, {
  required String plainText,
  String? selectedText,
  required bool viewerIsRoot,
  required bool isAssistant,
  required String reqId,
  int msgId = 0,
  VoidCallback? onSpeak,
  bool showRetry = false,
  VoidCallback? onRetryLastTurn,
  VoidCallback? onImageUpgradeHd,
  ChatConn? conn,
  VoidCallback? onGoodAnswer,
  VoidCallback? onBadAnswer,
}) {
  final loc = MaterialLocalizations.of(context);
  final text = plainText.trim();
  final selected = selectedText?.trim() ?? '';
  final copyOut = selected.isNotEmpty ? selectedText! : text;
  final traceConn = conn;
  final canTrace = msgCanTrace(viewerIsRoot: viewerIsRoot, isAssistant: isAssistant, reqId: reqId);
  final traceAction = canTrace
      ? ChatMessageMenuAction(
          label: 'Trace',
          icon: Icons.bolt_rounded,
          onPressed: () {
            ContextMenuController.removeAny();
            final opened = traceConn;
            if (opened == null || !context.mounted) return;
            unawaited(showMsgTraceBottomSheet(context, reqId: reqId, conn: opened, msgId: msgId));
          },
        )
      : null;
  final copyIdAction = (msgId > 0 || reqId.trim().isNotEmpty)
      ? ChatMessageMenuAction(
          label: msgId > 0 ? 'Copy message ID' : 'Copy request ID',
          icon: Icons.tag_rounded,
          onPressed: () {
            ContextMenuController.removeAny();
            final label = msgId > 0 ? 'Message ID' : 'Request ID';
            final rawId = msgId > 0 ? '$msgId' : reqId.trim();
            final copyId = msgCopyClipboardId(label, rawId);
            Clipboard.setData(ClipboardData(text: copyId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copied'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)),
            );
          },
        )
      : null;
  final good = onGoodAnswer;
  final bad = onBadAnswer;
  final showFeedback = good != null && bad != null && isAssistant && msgId > 0;

  final showCopyShortcut = switch (Theme.of(context).platform) {
    TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux => true,
    _ => false,
  };

  final items = <ChatMessageMenuItem>[
    ChatMessageMenuAction(
      label: loc.copyButtonLabel,
      icon: Icons.content_copy_rounded,
      shortcut: showCopyShortcut ? 'Ctrl+C' : null,
      onPressed: () {
        ContextMenuController.removeAny();
        if (copyOut.isEmpty) return;
        Clipboard.setData(ClipboardData(text: copyOut));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
        );
      },
    ),
    if (text.isNotEmpty || (showRetry && onRetryLastTurn != null)) ...[
      const ChatMessageMenuDivider(),
      if (text.isNotEmpty && onSpeak != null)
        ChatMessageMenuAction(
          label: 'Read aloud',
          icon: Icons.record_voice_over_rounded,
          onPressed: onSpeak,
        ),
      if (showRetry && onRetryLastTurn != null)
        ChatMessageMenuAction(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () {
            ContextMenuController.removeAny();
            onRetryLastTurn();
          },
        ),
    ],
    if (onImageUpgradeHd != null) ...[
      const ChatMessageMenuDivider(),
      ChatMessageMenuAction(
        label: catalogT('chat.image.upgrade_hd'),
        icon: Icons.hd_rounded,
        onPressed: () {
          ContextMenuController.removeAny();
          onImageUpgradeHd();
        },
      ),
    ],
  ];

  final idActions = <ChatMessageMenuAction>[
    if (traceAction != null) traceAction,
    if (copyIdAction != null) copyIdAction,
  ];
  if (idActions.isNotEmpty || showFeedback) {
    if (items.isEmpty || items.last is! ChatMessageMenuDivider) items.add(const ChatMessageMenuDivider());
    if (idActions.length == 2) {
      items.add(ChatMessageMenuButtonRow(actions: idActions));
    } else if (idActions.length == 1) {
      items.add(idActions.single);
    }
    if (showFeedback) {
      items.add(ChatMessageMenuButtonRow(actions: [
        ChatMessageMenuAction(
          label: 'Good',
          icon: Icons.thumb_up_alt_outlined,
          onPressed: () {
            ContextMenuController.removeAny();
            good();
          },
        ),
        ChatMessageMenuAction(
          label: 'Bad',
          icon: Icons.thumb_down_alt_outlined,
          onPressed: () {
            ContextMenuController.removeAny();
            bad();
          },
        ),
      ]));
    }
  }
  return items;
}

/// Pointer-anchored message menu ([SelectionArea] context menu and overlays).
Widget msgBubbleContextMenuAt(
  BuildContext context,
  Offset primaryAnchor, {
  Offset? secondaryAnchor,
  required List<ChatMessageMenuItem> items,
}) {
  return ChatMessageContextMenu(
    anchors: TextSelectionToolbarAnchors(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor ?? primaryAnchor,
    ),
    items: items,
  );
}

/// One-shot overlay menu; dismisses on outside tap or when [onDismiss] runs.
OverlayEntry showMsgBubbleContextMenuOverlay({
  required BuildContext context,
  required Offset anchor,
  required List<ChatMessageMenuItem> items,
  VoidCallback? onDismiss,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  var open = true;
  void dismiss() {
    if (!open) return;
    open = false;
    entry.remove();
    onDismiss?.call();
  }

  entry = OverlayEntry(
    builder: (ctx) => Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => dismiss(),
          child: const SizedBox.expand(),
        ),
        msgBubbleContextMenuAt(ctx, anchor, items: items),
      ],
    ),
  );
  overlay.insert(entry);
  return entry;
}

List<ChatMessageMenuItem> msgBubbleMenuItemsWithDismiss(
  List<ChatMessageMenuItem> items,
  VoidCallback dismiss,
) {
  ChatMessageMenuAction wrapAction(ChatMessageMenuAction a) => ChatMessageMenuAction(
        label: a.label,
        icon: a.icon,
        shortcut: a.shortcut,
        onPressed: () {
          dismiss();
          a.onPressed();
        },
      );
  return [
    for (final item in items)
      switch (item) {
        ChatMessageMenuAction a => wrapAction(a),
        ChatMessageMenuDivider d => d,
        ChatMessageMenuButtonRow r => ChatMessageMenuButtonRow(actions: [for (final a in r.actions) wrapAction(a)]),
      },
  ];
}

Widget msgBubbleContextMenu(
  BuildContext context,
  SelectableRegionState selectableRegionState, {
  required String plainText,
  String? selectedText,
  required bool viewerIsRoot,
  required bool isAssistant,
  required String reqId,
  int msgId = 0,
  VoidCallback? onSpeak,
  bool showRetry = false,
  VoidCallback? onRetryLastTurn,
  VoidCallback? onImageUpgradeHd,
  ChatConn? conn,
  VoidCallback? onGoodAnswer,
  VoidCallback? onBadAnswer,
}) {
  final items = msgBubbleMenuItems(
    context,
    plainText: plainText,
    selectedText: selectedText,
    viewerIsRoot: viewerIsRoot,
    isAssistant: isAssistant,
    reqId: reqId,
    msgId: msgId,
    onSpeak: onSpeak,
    showRetry: showRetry,
    onRetryLastTurn: onRetryLastTurn,
    onImageUpgradeHd: onImageUpgradeHd,
    conn: conn,
    onGoodAnswer: onGoodAnswer,
    onBadAnswer: onBadAnswer,
  );

  return msgBubbleContextMenuAt(
    context,
    selectableRegionState.contextMenuAnchors.primaryAnchor,
    secondaryAnchor: selectableRegionState.contextMenuAnchors.secondaryAnchor,
    items: items,
  );
}
