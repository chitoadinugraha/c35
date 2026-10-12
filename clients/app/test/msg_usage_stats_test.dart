import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasMetrics ignores model-only rows (thinking / streaming)', () {
    const modelOnly = MsgUsageStats(model: 'alienai');
    expect(modelOnly.hasData, isTrue);
    expect(modelOnly.hasMetrics, isFalse);
    expect(msgUsageStreaming(busy: true, msgReqId: 'a', liveReqId: 'a'), isTrue);
  });

  test('msgUsageNeedsTraceBackfill when tokens present but model empty', () {
    final row = MsgRow(
      id: 1,
      chatId: 2,
      role: 'assistant',
      content: 'answer',
      reqId: 'r1',
      tokensIn: 100,
      tokensOut: 20,
      durationMs: 500,
      costUsd: 0.01,
    );
    expect(msgUsageStats(row).hasData, isTrue);
    expect(msgUsageNeedsTraceBackfill(row), isTrue);
    expect(msgUsageNeedsTraceBackfill(row.copyWith(model: 'alienai')), isFalse);
  });
}
