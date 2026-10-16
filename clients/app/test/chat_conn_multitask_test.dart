import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/store/prompt_run_store.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PromptRunStore.instance.clear();
  });

  test('PromptDelta for child req_id appends to PromptRunStore', () {
    final conn = ChatConn();
    PromptRunStore.instance.put(
      PromptRunPush(
        reqId: 'child-99',
        parentReqId: 'parent-1',
        status: 'running',
        kind: 'computer_use',
      ),
    );

    conn.dispatchWsRes(
      WsRes(
        reqId: 'child-99',
        promptDelta: ResPromptDelta(text: 'Planning click...', thought: true),
      ),
    );

    expect(PromptRunStore.instance.liveThought('child-99'), 'Planning click...');
  });

  test('PromptDelta for parent req_id still goes to prompt stream', () async {
    final conn = ChatConn();
    final ctrl = conn.trackPromptStream('parent-stream');
    final events = <PromptStreamEvent>[];
    final sub = ctrl.stream.listen(events.add);

    conn.dispatchWsRes(
      WsRes(
        reqId: 'parent-stream',
        promptDelta: ResPromptDelta(text: 'answer bit', thought: false),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(events.where((e) => e.kind == 'delta').length, 1);
    expect(events.last.text, 'answer bit');
    expect(events.last.thought, isFalse);
    await sub.cancel();
    await ctrl.close();
  });

  test('orphan PromptEnd fanouts with chat_id for meter sync', () async {
    final conn = ChatConn();
    final events = <PromptEndFanout>[];
    final sub = conn.onPromptEndFanout.listen(events.add);

    conn.dispatchWsRes(
      WsRes(
        reqId: 'fanout-req',
        promptEnd: ResPromptEnd(
          chatId: Int64(42),
          promptTokens: 12000,
          contextWindow: 131072,
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(events.length, 1);
    expect(events.single.chatId, 42);
    expect(events.single.end.promptTokens, 12000);
    await sub.cancel();
  });

  test('PromptEnd with local stream does not fanout', () async {
    final conn = ChatConn();
    final ctrl = conn.trackPromptStream('local-req');
    final streamEvents = <PromptStreamEvent>[];
    final streamSub = ctrl.stream.listen(streamEvents.add);
    final fanouts = <PromptEndFanout>[];
    final fanoutSub = conn.onPromptEndFanout.listen(fanouts.add);

    conn.dispatchWsRes(
      WsRes(
        reqId: 'local-req',
        promptEnd: ResPromptEnd(chatId: Int64(7), promptTokens: 500),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fanouts, isEmpty);
    expect(streamEvents.where((e) => e.kind == 'end').length, 1);
    await streamSub.cancel();
    await fanoutSub.cancel();
  });

  test('unknown req_id PromptDelta is ignored', () {
    final conn = ChatConn();
    conn.dispatchWsRes(
      WsRes(
        reqId: 'orphan-1',
        promptDelta: ResPromptDelta(text: 'lost', thought: true),
      ),
    );
    expect(PromptRunStore.instance.liveThought('orphan-1'), isEmpty);
  });
}
