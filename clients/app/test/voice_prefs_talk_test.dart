import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('talk defaults off, persists across load, and stays independent of speak', () async {
    SharedPreferences.setMockInitialValues({});
    await VoicePrefs.instance.load();
    expect(VoicePrefs.instance.talkEnabled, isFalse);
    expect(VoicePrefs.instance.speakEnabled, isTrue);

    await VoicePrefs.instance.setTalkEnabled(true);
    expect(VoicePrefs.instance.talkEnabled, isTrue);
    expect(VoicePrefs.instance.speakEnabled, isTrue);

    await VoicePrefs.instance.load();
    expect(VoicePrefs.instance.talkEnabled, isTrue);
    expect(VoicePrefs.instance.speakEnabled, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('voice_talk_enabled'), isTrue);

    await VoicePrefs.instance.setSpeakEnabled(true);
    expect(VoicePrefs.instance.speakEnabled, isTrue);
    expect(VoicePrefs.instance.talkEnabled, isTrue);
    expect(prefs.getBool('voice_talk_enabled'), isTrue);
  });
}
