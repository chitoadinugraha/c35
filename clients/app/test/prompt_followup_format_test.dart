import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/widgets/ai/prompt_followup_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reject labels map plan_cap', () {
    expect(promptFollowupRejectLabel('plan_cap'), contains('Lite'));
    expect(promptFollowupRejectLabel('plan_cap', localeCode: 'id'), contains('Lite'));
  });

  test('queue rows filter steer', () {
    final rows = [
      PromptFollowupRow(kind: PromptFollowupKind.PROMPT_FOLLOWUP_KIND_QUEUE, text: 'q'),
      PromptFollowupRow(kind: PromptFollowupKind.PROMPT_FOLLOWUP_KIND_STEER, text: 's'),
    ];
    expect(promptFollowupQueueRows(rows), hasLength(1));
    expect(promptFollowupQueueRows(rows).first.text, 'q');
  });
}
