import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_feedback_thread.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bad vote shows reason, comment, and Alien AI thank-you', (tester) async {
    const reason = 'Tidak mengikuti instruksi';
    const comment = 'harusnya 3 slide';
    const thanks = 'Terima kasih. Catatanmu kami simpan untuk jawaban berikutnya.';
    final feedback = ChatMsgFeedback(
      id: Int64(1),
      msgId: Int64(42),
      chatId: Int64(7),
      vote: ChatFeedbackVote.CHAT_FEEDBACK_VOTE_BAD,
      reasonLabel: reason,
      comment: comment,
      posts: [
        ChatFeedbackPost(
          id: Int64(2),
          authorRole: ChatFeedbackAuthorRole.CHAT_FEEDBACK_AUTHOR_ROLE_SYSTEM,
          text: thanks,
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: UiMsgFeedbackThread(feedback: feedback))));

    expect(find.text('Bad answer · $reason'), findsOneWidget);
    expect(find.text(comment), findsOneWidget);
    expect(find.textContaining(thanks), findsOneWidget);
    expect(find.textContaining('Alien AI'), findsOneWidget);
  });
}
