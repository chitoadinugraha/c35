import 'dart:typed_data';

import 'package:alienai_c35/c/api/referral_conn.dart' show invokeResError;
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/voice.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:ulid/ulid.dart';

class VoiceApi {
  VoiceApi(this.conn);

  final ChatConn conn;

  Future<String?> sttTranscribe({
    required Uint8List audio,
    required String mime,
    String? lang,
    String? reqId,
  }) async {
    final id = (reqId != null && reqId.isNotEmpty) ? reqId : Ulid().toString();
    final res = await conn.invoke(
      InvokeReq(
        voiceStt: ReqVoiceStt(
          audio: audio,
          mime: mime,
          lang: lang ?? VoicePrefs.instance.speechLang,
          reqId: id,
        ),
      ),
    );
    if (res.hasVoiceStt()) {
      final stt = res.voiceStt;
      if (stt.error.isNotEmpty) {
        throw ApiException(uiApiErrorMessage(stt.error, fallback: 'Cloud speech recognition failed. Please try again.'));
      }
      final text = stt.text.trim();
      return text.isEmpty ? null : text;
    }
    final err = invokeResError(res, fallback: 'Cloud speech recognition failed. Please try again.');
    if (err != null) {
      throw ApiException(uiApiErrorMessage(err, fallback: 'Cloud speech recognition failed. Please try again.'));
    }
    return null;
  }

  Future<({Uint8List bytes, String mime})?> ttsSynthesize({
    required String text,
    String? lang,
    String? reqId,
  }) async {
    final id = (reqId != null && reqId.isNotEmpty) ? reqId : Ulid().toString();
    final res = await conn.invoke(
      InvokeReq(
        voiceTts: ReqVoiceTts(
          text: text,
          lang: lang ?? VoicePrefs.instance.speechLang,
          reqId: id,
        ),
      ),
    );
    if (res.hasVoiceTts()) {
      final tts = res.voiceTts;
      if (tts.error.isNotEmpty) {
        throw ApiException(uiApiErrorMessage(tts.error, fallback: 'Cloud voice playback failed. Please try again.'));
      }
      if (tts.audio.isEmpty) return null;
      return (bytes: Uint8List.fromList(tts.audio), mime: tts.mime.isNotEmpty ? tts.mime : 'audio/mpeg');
    }
    final err = invokeResError(res, fallback: 'Cloud voice playback failed. Please try again.');
    if (err != null) {
      throw ApiException(uiApiErrorMessage(err, fallback: 'Cloud voice playback failed. Please try again.'));
    }
    return null;
  }
}
