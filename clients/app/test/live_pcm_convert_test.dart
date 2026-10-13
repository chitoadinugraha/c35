import 'dart:typed_data';

import 'package:alienai_c35/c/live/live_pcm_convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pcmS16leToFloat32 normalizes peak sample', () {
    final pcm = Uint8List(4);
    final bd = ByteData.sublistView(pcm);
    bd.setInt16(0, 32767, Endian.little);
    bd.setInt16(2, -32768, Endian.little);
    final floats = pcmS16leToFloat32(pcm);
    expect(floats.length, 2);
    expect(floats[0], closeTo(1.0, 0.001));
    expect(floats[1], closeTo(-1.0, 0.001));
  });
}
