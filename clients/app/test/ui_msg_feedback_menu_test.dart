import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('trace and copy message id share one row; good and bad share the next', (tester) async {
    late List<ChatMessageMenuItem> items;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      items = msgBubbleMenuItems(
        context,
        plainText: 'hello',
        viewerIsRoot: true,
        isAssistant: true,
        reqId: 'req-1',
        msgId: 42,
        onGoodAnswer: () {},
        onBadAnswer: () {},
      );
      return const SizedBox.shrink();
    })));

    final rows = items.whereType<ChatMessageMenuButtonRow>().toList();
    expect(rows, hasLength(2));
    expect(rows[0].actions.map((a) => a.label).toList(), ['Trace', 'Copy message ID']);
    expect(rows[1].actions.map((a) => a.label).toList(), ['Good Answer', 'Bad Answer']);
    final traceIndex = items.indexOf(rows[0]);
    final feedbackIndex = items.indexOf(rows[1]);
    expect(items[traceIndex - 1], isA<ChatMessageMenuDivider>());
    expect(items.sublist(traceIndex + 1, feedbackIndex).whereType<ChatMessageMenuDivider>(), isEmpty);
  });

  testWidgets('good and bad hidden when msg id is missing', (tester) async {
    late List<ChatMessageMenuItem> items;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      items = msgBubbleMenuItems(
        context,
        plainText: 'hello',
        viewerIsRoot: true,
        isAssistant: true,
        reqId: 'req-1',
        msgId: 0,
        onGoodAnswer: () {},
        onBadAnswer: () {},
      );
      return const SizedBox.shrink();
    })));
    expect(items.whereType<ChatMessageMenuButtonRow>().length, 1);
    expect(items.any((i) => i is ChatMessageMenuAction && i.label == 'Good Answer'), isFalse);
  });
}
