class VoiceTranscript {
  const VoiceTranscript({
    required this.lang,
    required this.txt,
    required this.confidence,
    required this.isFinal,
    this.interim = '',
  });

  final String lang;
  final String txt;
  final String interim;
  final double confidence;
  final bool isFinal;

  factory VoiceTranscript.fromMap(Map<String, dynamic> map) => VoiceTranscript(
        lang: '${map['lang'] ?? ''}',
        txt: '${map['txt'] ?? ''}',
        interim: '${map['interim'] ?? ''}',
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
        isFinal: map['isFinal'] == true,
      );
}
