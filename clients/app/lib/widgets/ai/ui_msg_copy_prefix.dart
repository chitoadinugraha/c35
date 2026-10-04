import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:flutter/material.dart';
const _msgCopyMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String msgCopyTimestamp(DateTime dt) => '${dt.day} ${_msgCopyMonths[dt.month - 1]} ${dt.year} ${msgCopyPad2(dt.hour)}:${msgCopyPad2(dt.minute)}';

String msgCopyPad2(int n) => n.toString().padLeft(2, '0');

String? msgCopyModelProvider(String modelId, List<AgentModel> models) {
  final id = modelId.trim();
  if (id.isEmpty) return null;
  for (final m in models) {
    if (m.id == id) return m.provider;
  }
  final lower = id.toLowerCase();
  if (lower.startsWith('gpt-') || lower.contains('openai')) return 'openai';
  return null;
}

String msgCopySenderLabel({
  required String role,
  required String userName,
  String modelId = '',
  List<AgentModel> models = const [],
  String assistantName = '',
}) {
  if (role == 'user') {
    final who = userName.trim();
    return who.isEmpty ? 'Account' : who;
  }
  final custom = assistantName.trim();
  if (custom.isNotEmpty) return custom;
  if (msgCopyModelProvider(modelId, models) == 'openai') return 'Alien AI (ChatGPT)';
  return 'Alien AI';
}

String msgCopyHeader({
  required String role,
  required String userName,
  required int createdAtMs,
  String modelId = '',
  List<AgentModel> models = const [],
  String assistantName = '',
  DateTime? now,
}) {
  final ms = createdAtMs > 0 ? createdAtMs : (now ?? DateTime.now()).millisecondsSinceEpoch;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  final stamp = msgCopyTimestamp(dt);
  final who = msgCopySenderLabel(role: role, userName: userName, modelId: modelId, models: models, assistantName: assistantName);
  return '[$who $stamp]';
}

String msgCopyPrefix({
  required String role,
  required String userName,
  required int createdAtMs,
  String modelId = '',
  List<AgentModel> models = const [],
  String assistantName = '',
  DateTime? now,
}) =>
    msgCopyHeader(
      role: role,
      userName: userName,
      createdAtMs: createdAtMs,
      modelId: modelId,
      models: models,
      assistantName: assistantName,
      now: now,
    );

String msgCopyBody({required String header, int leadingNewlines = 0}) {
  final gap = leadingNewlines > 0 ? '\n' * leadingNewlines : '';
  return '$gap$header\n';
}

String msgCopyBlock({
  required String role,
  required String userName,
  required int createdAtMs,
  required String body,
  String modelId = '',
  List<AgentModel> models = const [],
  String assistantName = '',
}) {
  final text = body.trim();
  if (text.isEmpty) return '';
  final header = msgCopyHeader(
    role: role,
    userName: userName,
    createdAtMs: createdAtMs,
    modelId: modelId,
    models: models,
    assistantName: assistantName,
  );
  return '$header\n$text';
}

String msgCopyTranscript({
  required List<MsgRow> messages,
  required String Function(MsgRow) plainText,
  required String userName,
  List<AgentModel> models = const [],
  String Function(MsgRow msg)? userNameFor,
  String Function(MsgRow msg, String plain)? assistantName,
  String Function(MsgRow msg)? modelId,
}) {
  final parts = <String>[];
  for (final m in messages) {
    final body = plainText(m).trim();
    if (body.isEmpty) continue;
    final block = msgCopyBlock(
      role: m.role,
      userName: userNameFor?.call(m) ?? userName,
      createdAtMs: m.createdAtMs,
      body: body,
      modelId: modelId?.call(m) ?? (m.role == 'assistant' ? m.model : ''),
      models: models,
      assistantName: assistantName?.call(m, body) ?? '',
    );
    if (block.isNotEmpty) parts.add(block);
  }
  return parts.join('\n\n');
}

class UiMsgCopyPrefix extends StatelessWidget {
  const UiMsgCopyPrefix({super.key, required this.text, this.leadingNewlines = 0});

  final String text;
  final int leadingNewlines;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: 0,
          child: Text(msgCopyBody(header: text, leadingNewlines: leadingNewlines), style: const TextStyle(color: Colors.transparent, fontSize: 1, height: 0)),
        ),
      );
}
