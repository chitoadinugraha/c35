import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/c/remote/remote_teach.dart';
import 'package:alienai_c35/c/settings/remote_prefs.dart';
import 'package:alienai_c35/c/skill/skill_md.dart';
import 'package:alienai_c35/widgets/devices/ui_remote_teach_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RemotePrefs.instance.load();
  });

  group('skillNeedsAttention', () {
    test('trips at max patches per day', () {
      final skill = Skill(patchCount: skillCircuitBreakerMaxPatchesPerDay);
      expect(skillNeedsAttention(skill), isTrue);
    });

    test('flags repeated patches without consecutive_ok recovery', () {
      final skill = Skill(patchCount: 2, consecutiveOk: 0);
      expect(skillNeedsAttention(skill), isTrue);
    });

    test('healthy skill with low patch count', () {
      final skill = Skill(patchCount: 1, consecutiveOk: 3);
      expect(skillNeedsAttention(skill), isFalse);
    });
  });

  testWidgets('teach HUD shows Stop and invokes callback', (tester) async {
    const deviceIid = 4242;
    final session = RemoteSession.of(ChatConn(), deviceIid);
    session.teach = RemoteTeachApi.inMemory(deviceIid);
    session.teach!.recording.value = true;
    var stopped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 600)),
          child: Scaffold(
            body: Stack(
              children: [
                UiRemoteTeachHud(
                  session: session,
                  deviceIid: deviceIid,
                  onStop: () => stopped = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stop'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(stopped, isTrue);
    session.teach?.dispose();
  });
}