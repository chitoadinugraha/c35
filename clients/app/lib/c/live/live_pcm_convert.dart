import 'dart:typed_data';

Float32List pcmS16leToFloat32(Uint8List pcm, {int start = 0, int? end}) {
  final stop = end ?? pcm.length;
  final numSamples = (stop - start) ~/ 2;
  final out = Float32List(numSamples);
  final bd = ByteData.sublistView(pcm, start, stop);
  for (var i = 0; i < numSamples; i++) {
    final sample = bd.getInt16(i * 2, Endian.little);
    out[i] = sample / 32768.0;
  }
  return out;
}
