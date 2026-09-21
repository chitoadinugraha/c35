import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';

Future<void> settingsBootstrap() async {
  await Future.wait([
    PromptUsagePrefs.instance.load(),
    VoicePrefs.instance.load(),
  ]);
}
