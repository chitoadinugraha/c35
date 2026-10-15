typedef MicStreamCandidate = ({int sampleRate, int numChannels, int bitRate});

/// PCM `record` stream configs: mobile and web prefer 16 kHz mono (Live uplink + STT).
/// Live Call uplink on Windows: 16 kHz mono first (Gemini Live); avoid stereo + AEC.
List<MicStreamCandidate> liveCallMicStreamCandidates({
  required bool isMobile,
  required bool isWeb,
  required bool isWindowsDesktop,
}) {
  if (isWindowsDesktop) {
    return micStreamCandidates(isMobile: true, isWeb: false);
  }
  return micStreamCandidates(isMobile: isMobile, isWeb: isWeb);
}

List<MicStreamCandidate> micStreamCandidates({required bool isMobile, required bool isWeb}) {
  if (isMobile || isWeb) {
    return [
      (sampleRate: 16000, numChannels: 1, bitRate: 256000),
      (sampleRate: 48000, numChannels: 1, bitRate: 768000),
      (sampleRate: 44100, numChannels: 1, bitRate: 705600),
    ];
  }
  return [
    (sampleRate: 48000, numChannels: 2, bitRate: 1536000),
    (sampleRate: 48000, numChannels: 1, bitRate: 768000),
    (sampleRate: 44100, numChannels: 2, bitRate: 1411200),
    (sampleRate: 44100, numChannels: 1, bitRate: 705600),
    (sampleRate: 16000, numChannels: 1, bitRate: 256000),
  ];
}
