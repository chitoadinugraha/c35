import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/log.pb.dart';

class TraceLogDoc {
  const TraceLogDoc({
    this.id = 0,
    this.reqId = '',
    this.kind = '',
    this.topic = '',
    this.text = '',
    this.model = '',
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.durationMs = 0,
    this.costUsd = 0,
    this.metaJson = '{}',
    this.tsMs = 0,
  });

  final int id;
  final String reqId;
  final String kind;
  final String topic;
  final String text;
  final String model;
  final int tokensIn;
  final int tokensOut;
  final int durationMs;
  final double costUsd;
  final String metaJson;
  final int tsMs;

  Map<String, dynamic> get meta {
    final raw = metaJson.trim();
    if (raw.isEmpty || raw == '{}') return const {};
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return d.map((k, v) => MapEntry('$k', v));
    } catch (_) {}
    return const {};
  }

  factory TraceLogDoc.fromLog(Log l) => TraceLogDoc(
        id: l.id.toInt(),
        reqId: l.reqId,
        kind: l.kind,
        topic: l.topic,
        text: l.text,
        model: l.model,
        tokensIn: l.tokensIn,
        tokensOut: l.tokensOut,
        durationMs: l.durationMs,
        costUsd: l.costUsd,
        metaJson: l.metaJson,
        tsMs: l.createdTsMs.toInt(),
      );
}
