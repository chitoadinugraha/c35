import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:flutter/material.dart';

class UiMsgFeedbackThread extends StatelessWidget {
  const UiMsgFeedbackThread({super.key, required this.feedback});

  final ChatMsgFeedback feedback;

  static const _reason = TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.35);
  static const _body = TextStyle(color: Color(0xFFF4F4F5), fontSize: 13, height: 1.35);

  String get _voteLabel => switch (feedback.vote) {
        ChatFeedbackVote.CHAT_FEEDBACK_VOTE_GOOD => 'Good answer',
        ChatFeedbackVote.CHAT_FEEDBACK_VOTE_BAD => 'Bad answer',
        _ => '',
      };

  String? _prefix(ChatFeedbackAuthorRole role) => switch (role) {
        ChatFeedbackAuthorRole.CHAT_FEEDBACK_AUTHOR_ROLE_SYSTEM || ChatFeedbackAuthorRole.CHAT_FEEDBACK_AUTHOR_ROLE_STAFF => 'Alien AI',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final comment = feedback.comment.trim();
    final vote = _voteLabel;
    final reasonLine = vote.isEmpty ? feedback.reasonLabel : '$vote · ${feedback.reasonLabel}';
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 8),
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF3F3F46), width: 2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reasonLine, style: _reason),
          if (comment.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(comment, style: _body)),
          for (final post in feedback.posts) Padding(padding: const EdgeInsets.only(top: 4), child: _post(post)),
        ],
      ),
    );
  }

  Widget _post(ChatFeedbackPost post) {
    final prefix = _prefix(post.authorRole);
    if (prefix == null) return Text(post.text, style: _body);
    return Text.rich(TextSpan(style: _body, children: [TextSpan(text: '$prefix '), TextSpan(text: post.text)]));
  }
}
