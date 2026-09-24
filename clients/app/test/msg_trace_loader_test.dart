import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/trace/trace_log.dart';
import 'package:alienai_c35/widgets/ai/msg_trace_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<TraceLogDoc> _visitLogs() => [
      TraceLogDoc(
        topic: 'tool_result',
        text: jsonEncode({
          'ok': true,
          'tool': 'web.visit',
          'url': 'https://jadwalnonton.com/bioskop/di-malang/',
          'title': 'Jadwal Bioskop Malang',
        }),
        metaJson: jsonEncode({'tool': 'web.visit'}),
      ),
    ];

void main() {
  test('traceCachePut notifies listeners for req id', () async {
    final conn = ChatConn();
    const reqId = 'req-citation-test';
    final seen = <String>[];
    final sub = conn.onTraceCachePut.listen(seen.add);

    conn.traceCachePut(reqId, _visitLogs());
    await Future<void>.delayed(Duration.zero);

    expect(seen, [reqId]);
    await sub.cancel();
  });

  testWidgets('UiMsgTraceLoader renders cached citations below answer', (tester) async {
    final conn = ChatConn();
    const reqId = 'req-citation-test';
    conn.traceCachePut(reqId, _visitLogs());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiMsgTraceLoader(conn: conn, reqId: reqId, part: MsgTracePart.citations),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('jadwalnonton.com'), findsOneWidget);
  });
}
