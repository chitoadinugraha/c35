import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:flutter/material.dart';

Future<ChatMsgFeedback?> showMsgFeedbackSheet(
  BuildContext context, {
  required ChatConn conn,
  required int msgId,
  required int chatId,
  required ChatFeedbackVote vote,
  String locale = '',
}) async {
  final listed = await conn.chatFeedbackReasonList(locale: locale, vote: vote);
  if (!context.mounted) return null;
  return showModalBottomSheet<ChatMsgFeedback>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF18181B),
    barrierColor: const Color(0xE6000000),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => _MsgFeedbackSheetHost(
      conn: conn,
      msgId: msgId,
      chatId: chatId,
      vote: vote,
      locale: locale,
      reasons: listed.reasons,
    ),
  );
}

class MsgFeedbackSheet extends StatefulWidget {
  const MsgFeedbackSheet({
    super.key,
    required this.vote,
    required this.reasons,
    required this.onSave,
    this.initialReasonId = 0,
    this.initialComment = '',
    this.saving = false,
  });

  final ChatFeedbackVote vote;
  final List<ChatFeedbackReason> reasons;
  final int initialReasonId;
  final String initialComment;
  final bool saving;
  final void Function(int reasonId, String comment) onSave;

  @override
  State<MsgFeedbackSheet> createState() => _MsgFeedbackSheetState();
}

class _MsgFeedbackSheetState extends State<MsgFeedbackSheet> {
  late final TextEditingController _comment = TextEditingController(text: widget.initialComment);
  late int _reasonId = widget.initialReasonId;

  @override
  void initState() {
    super.initState();
    _comment.addListener(_onComment);
  }

  void _onComment() => setState(() {});

  @override
  void dispose() {
    _comment.removeListener(_onComment);
    _comment.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (widget.saving || _reasonId == 0) return false;
    final picked = widget.reasons.where((r) => r.id == _reasonId);
    if (picked.isEmpty) return false;
    if (picked.first.slug == 'other' && _comment.text.trim().isEmpty) return false;
    return true;
  }

  String get _title => widget.vote == ChatFeedbackVote.CHAT_FEEDBACK_VOTE_GOOD ? 'Good Answer' : 'Bad Answer';

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(child: Text(_title, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w600))),
                    IconButton(
                      onPressed: widget.saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF71717A), size: 20),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final reason in widget.reasons)
                      RadioListTile<int>(
                        value: reason.id,
                        groupValue: _reasonId,
                        onChanged: widget.saving ? null : (id) => setState(() => _reasonId = id ?? 0),
                        title: Text(reason.label, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14)),
                        activeColor: const Color(0xFFF4F4F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _comment,
                  enabled: !widget.saving,
                  minLines: 2,
                  maxLines: 4,
                  style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Comment',
                    hintStyle: TextStyle(color: Color(0xFF71717A)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3F3F46))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF71717A))),
                    disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3F3F46))),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: widget.saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _canSave ? () => widget.onSave(_reasonId, _comment.text.trim()) : null,
                      child: Text(widget.saving ? 'Saving' : 'Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MsgFeedbackSheetHost extends StatefulWidget {
  const _MsgFeedbackSheetHost({
    required this.conn,
    required this.msgId,
    required this.chatId,
    required this.vote,
    required this.locale,
    required this.reasons,
  });

  final ChatConn conn;
  final int msgId;
  final int chatId;
  final ChatFeedbackVote vote;
  final String locale;
  final List<ChatFeedbackReason> reasons;

  @override
  State<_MsgFeedbackSheetHost> createState() => _MsgFeedbackSheetHostState();
}

class _MsgFeedbackSheetHostState extends State<_MsgFeedbackSheetHost> {
  var _saving = false;

  Future<void> _save(int reasonId, String comment) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final res = await widget.conn.chatMsgFeedbackPut(
        msgId: widget.msgId,
        chatId: widget.chatId,
        vote: widget.vote,
        reasonId: reasonId,
        comment: comment,
        locale: widget.locale,
      );
      if (!mounted) return;
      Navigator.pop(context, res.feedback);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => MsgFeedbackSheet(
        vote: widget.vote,
        reasons: widget.reasons,
        saving: _saving,
        onSave: (reasonId, comment) => unawaited(_save(reasonId, comment)),
      );
}
