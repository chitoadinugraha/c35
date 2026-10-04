import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_feedback_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reasons = [
    ChatFeedbackReason(id: 6, slug: 'wrong', vote: ChatFeedbackVote.CHAT_FEEDBACK_VOTE_BAD, label: 'Wrong answer'),
    ChatFeedbackReason(id: 12, slug: 'other', vote: ChatFeedbackVote.CHAT_FEEDBACK_VOTE_BAD, label: 'Other'),
  ];

  Future<void> pump(WidgetTester tester, void Function(int reasonId, String comment) onSave) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MsgFeedbackSheet(
              vote: ChatFeedbackVote.CHAT_FEEDBACK_VOTE_BAD,
              reasons: reasons,
              onSave: onSave,
            ),
          ),
        ),
      );

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));

  testWidgets('save stays off until a reason is picked; other needs a comment; wrong allows an empty comment', (tester) async {
    int? savedId;
    String? savedComment;
    await pump(tester, (reasonId, comment) {
      savedId = reasonId;
      savedComment = comment;
    });

    expect(find.text('Bad Answer'), findsOneWidget);
    expect(find.text('Wrong answer'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);

    await tester.tap(find.text('Other'));
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  should be 3 slides  ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Wrong answer'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.enterText(find.byType(TextField), '  note  ');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(savedId, 6);
    expect(savedComment, 'note');
  });

  testWidgets('good answer title and saving disables save', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MsgFeedbackSheet(
            vote: ChatFeedbackVote.CHAT_FEEDBACK_VOTE_GOOD,
            reasons: [
              ChatFeedbackReason(id: 1, slug: 'accurate', vote: ChatFeedbackVote.CHAT_FEEDBACK_VOTE_GOOD, label: 'Correct'),
            ],
            initialReasonId: 1,
            saving: true,
            onSave: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.text('Good Answer'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Saving')).onPressed, isNull);
  });
}
