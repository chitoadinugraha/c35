import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_trace_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showMsgTraceBottomSheet(BuildContext context, {required String reqId, required ChatConn conn}) async {
  if (reqId.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No trace available'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    }
    return;
  }
  await showMsgTraceSheet(context, reqId: reqId.trim(), conn: conn);
}

List<ChatMessageMenuItem> msgBubbleMenuItems(
  BuildContext context, {
  required String plainText,
  String? selectedText,
  VoidCallback? onSelectAll,
  required bool viewerIsRoot,
  required bool isAssistant,
  required String reqId,
  int msgId = 0,
  VoidCallback? onSpeak,
  bool showRetry = false,
  VoidCallback? onRetryLastTurn,
  ChatConn? conn,
}) {
  final loc = MaterialLocalizations.of(context);
  final text = plainText.trim();
  final selected = selectedText?.trim() ?? '';
  final copyOut = selected.isNotEmpty ? selectedText! : text;
  final traceConn = conn;
  final canTrace = msgCanTrace(viewerIsRoot: viewerIsRoot, isAssistant: isAssistant, reqId: reqId) && traceConn != null;

  return [
    ChatMessageMenuAction(
      label: loc.copyButtonLabel,
      icon: Icons.content_copy_rounded,
      shortcut: 'Ctrl+C',
      onPressed: () {
        ContextMenuController.removeAny();
        if (copyOut.isEmpty) return;
        Clipboard.setData(ClipboardData(text: copyOut));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
        );
      },
    ),
    if (onSelectAll != null)
      ChatMessageMenuAction(
        label: loc.selectAllButtonLabel,
        icon: Icons.select_all_rounded,
        shortcut: 'Ctrl+A',
        onPressed: onSelectAll,
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
          onPressed: onRetryLastTurn,
        ),
    ],
    if (canTrace) ...[
      const ChatMessageMenuDivider(),
      ChatMessageMenuAction(
        label: 'Trace',
        icon: Icons.bolt_rounded,
        onPressed: () {
          ContextMenuController.removeAny();
          if (!context.mounted) return;
          unawaited(showMsgTraceBottomSheet(context, reqId: reqId, conn: traceConn));
        },
      ),
    ],
    if (msgId > 0) ...[
      const ChatMessageMenuDivider(),
      ChatMessageMenuAction(
        label: 'Copy message ID',
        icon: Icons.tag_rounded,
        onPressed: () {
          ContextMenuController.removeAny();
          Clipboard.setData(ClipboardData(text: '$msgId'));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message ID copied: $msgId'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)),
          );
        },
      ),
    ],
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
  ChatConn? conn,
}) {
  void closeMenu() => ContextMenuController.removeAny();
  final items = msgBubbleMenuItems(
    context,
    plainText: plainText,
    selectedText: selectedText,
    onSelectAll: () {
      closeMenu();
      selectableRegionState.selectAll(SelectionChangedCause.toolbar);
    },
    viewerIsRoot: viewerIsRoot,
    isAssistant: isAssistant,
    reqId: reqId,
    msgId: msgId,
    onSpeak: onSpeak,
    showRetry: showRetry,
    onRetryLastTurn: onRetryLastTurn,
    conn: conn,
  );

  return SizedBox.expand(
    child: Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => ContextMenuController.removeAny(),
          ),
        ),
        ChatMessageContextMenu(anchors: selectableRegionState.contextMenuAnchors, items: items),
      ],
    ),
  );
}
