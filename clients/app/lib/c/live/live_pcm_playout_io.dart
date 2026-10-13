import 'dart:io';

import 'package:alienai_c35/c/live/live_pcm_playout.dart';
import 'package:alienai_c35/c/live/live_pcm_playout_channel.dart';

Future<LivePcmPlayout?> createLivePcmPlayout() async {
  if (Platform.isAndroid) {
    return LivePcmPlayoutChannel();
  }
  return null;
}

Future<void> warmUpLivePcmPlayout() async {}

Future<void> disposeLivePcmPlayout() async {}
