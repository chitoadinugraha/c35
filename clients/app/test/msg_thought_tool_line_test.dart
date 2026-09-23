import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_thought.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('msgThoughtStripPlaceholders removes tool calling lines', () {
    expect(msgThoughtStripPlaceholders('Using consumption.add…'), '');
    expect(msgThoughtStripPlaceholders('Using consumption.add...'), '');
    expect(msgThoughtStripPlaceholders('Using consumption.add…\nNeed to estimate portions'), 'Need to estimate portions');
  });

  test('msgThoughtView hides tool-only thought when not thinking', () {
    final view = msgThoughtView(thought: 'Using consumption.add…', content: '', thinking: false);
    expect(view.thought, isNull);
  });
}
