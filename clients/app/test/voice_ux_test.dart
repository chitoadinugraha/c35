import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('context menu includes Read aloud when onSpeak provided', (tester) async {
    late List<ChatMessageMenuItem> items;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        items = msgBubbleMenuItems(
          ctx,
          plainText: 'Hello',
          onSpeak: () {},
          viewerIsRoot: false,
          isAssistant: true,
          reqId: '',
        );
        return const SizedBox.shrink();
      }),
    ));
    expect(
      items.any((i) => i is ChatMessageMenuAction && i.label == 'Read aloud'),
      isTrue,
    );
  });

  testWidgets('context menu omits Read aloud when onSpeak is null', (tester) async {
    late List<ChatMessageMenuItem> items;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        items = msgBubbleMenuItems(
          ctx,
          plainText: 'Hello',
          viewerIsRoot: false,
          isAssistant: true,
          reqId: '',
        );
        return const SizedBox.shrink();
      }),
    ));
    expect(
      items.any((i) => i is ChatMessageMenuAction && i.label == 'Read aloud'),
      isFalse,
    );
  });
}
