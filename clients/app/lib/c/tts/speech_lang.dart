/// One supported speech locale. Add a new language by appending to [kSpeechLangs] — see `_/docs/speech_languages.md`.
class SpeechLangDef {
  const SpeechLangDef({required this.locale, required this.label, required this.ttsTl, required this.flag, required this.hints, this.voiceNameHints = const []});
  final String locale;
  final String label;
  final String ttsTl;
  final String flag;
  final Set<String> hints;
  final List<String> voiceNameHints;
}

const kSpeechLangAuto = 'auto';
const kSpeechLangFallback = 'id-ID';
const kSpeechLangDefault = kSpeechLangAuto;

/// First entry wins ties. Latin tokenizer `[a-z]+` only — non-latin langs need `speechLangTokens` extended.
const kSpeechLangs = <SpeechLangDef>[
  SpeechLangDef(locale: 'id-ID', label: 'Indonesian', ttsTl: 'id', flag: 'iconify://circle-flags:id', hints: _idHints, voiceNameHints: ['indonesia', 'gadis', 'ardi']),
  SpeechLangDef(locale: 'en-US', label: 'English', ttsTl: 'en', flag: 'iconify://circle-flags:us', hints: _enHints),
];

Iterable<String> speechLangTokens(String text) => text.toLowerCase().split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty);

SpeechLangDef? speechLangDef(String lang) {
  for (final d in kSpeechLangs) {
    if (d.locale == lang || lang.startsWith('${d.ttsTl}-') || lang == d.ttsTl) return d;
  }
  return null;
}

String? speechLangDetect(String text) {
  final words = speechLangTokens(text).toList();
  SpeechLangDef? best;
  var bestHits = 0;
  for (final lang in kSpeechLangs) {
    final hits = words.where(lang.hints.contains).length;
    if (hits > bestHits) {
      bestHits = hits;
      best = lang;
    }
  }
  return bestHits == 0 ? null : best!.locale;
}

String speechLangResolve(String text, {String last = '', required String locale}) {
  final detected = speechLangDetect(text);
  if (detected != null) return detected;
  if (last.isNotEmpty) return last;
  if (locale != kSpeechLangAuto && speechLangDef(locale) != null) return locale;
  return kSpeechLangFallback;
}

/// BCP-47 locale for STT when prefs may be [kSpeechLangAuto].
String speechLangSttLocale(String pref, {String last = ''}) {
  if (pref != kSpeechLangAuto) return speechLangDef(pref)?.locale ?? kSpeechLangFallback;
  if (last.isNotEmpty) return last;
  return kSpeechLangFallback;
}

List<String> get speechLangOptions => [kSpeechLangAuto, ...kSpeechLangs.map((d) => d.locale)];

String speechTextCap(String text, {int maxSentences = 2}) {
  final parts = text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().isNotEmpty).toList();
  return parts.length <= maxSentences ? text : parts.take(maxSentences).join(' ');
}

String speechTextClean(String raw) {
  var text = raw;
  text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  text = text.replaceAll(RegExp(r'`[^`]*`'), ' ');
  text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? '');
  text = text.replaceAll(RegExp(r'https?://[^\s]+'), ' ');
  text = text.replaceAll(RegExp(r'^[#*>-]+\s*', multiLine: true), ' ');
  text = text.replaceAll(RegExp(r'[*_~`]+'), ' ');
  text = text.replaceAll(RegExp(r'<thought>[\s\S]*?</thought>'), ' ');
  text = text.replaceAll(
    RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
      unicode: true,
    ),
    ' ',
  );
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text;
}

String speechLangLabel(String lang) {
  if (lang == kSpeechLangAuto) return 'Auto';
  return speechLangDef(lang)?.label ?? lang;
}

String? speechLangFlag(String lang) => lang == kSpeechLangAuto ? null : speechLangDef(lang)?.flag;

String speechLangTtsCode(String lang) => speechLangDef(lang)?.ttsTl ?? 'en';

const _idHints = {
  'yang', 'dan', 'ini', 'itu', 'dengan', 'untuk', 'tidak', 'bisa', 'ada', 'kamu', 'kita', 'apa',
  'atau', 'dari', 'sudah', 'akan', 'saya', 'aku', 'karena', 'jadi', 'mau', 'juga', 'kalau',
  'sekarang', 'mungkin', 'ingin', 'adalah', 'pada', 'dalam', 'oleh', 'sebagai', 'bagi', 'tentang',
  'seperti', 'antara', 'secara', 'tanpa', 'hingga', 'sampai', 'terhadap', 'kepada', 'namun',
  'tetapi', 'tapi', 'sedangkan', 'melainkan', 'sehingga', 'supaya', 'agar', 'meskipun', 'walaupun',
  'serta', 'sambil', 'bahkan', 'lagi', 'pun', 'nya', 'di', 'ke', 'berdasarkan', 'dasar', 'mengenai',
  'terkait', 'merupakan', 'yaitu', 'yakni', 'ialah', 'adapun', 'sementara', 'selain',
  'hari', 'waktu', 'saat', 'jam', 'pukul', 'detik', 'menit', 'tanggal', 'bulan', 'tahun', 'minggu',
  'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'ahad', 'besok', 'kemarin', 'lusa',
  'pagi', 'siang', 'sore', 'malam', 'dulu', 'nanti', 'kelak', 'tadi', 'semalam',
  'januari', 'februari', 'maret', 'april', 'mei', 'juni', 'juli', 'agustus', 'september',
  'oktober', 'november', 'desember',
  'apakah', 'siapa', 'dimana', 'kemana', 'darimana', 'mana', 'kapan', 'mengapa', 'kenapa',
  'bagaimana', 'gimana', 'berapa', 'dia', 'ia', 'mereka', 'beliau', 'kami', 'anda', 'kalian',
  'dapat', 'perlu', 'harus', 'wajib', 'boleh', 'mesti', 'sedang', 'telah', 'pernah', 'belum',
  'masih', 'tahu', 'lihat', 'lihatlah', 'dengar', 'buat', 'bikin', 'ambil', 'beri', 'bantu', 'tolong',
  'buka', 'tutup', 'pilih', 'pakai', 'gunakan', 'punya', 'memiliki', 'menjadi', 'melakukan',
  'memberikan', 'menggunakan', 'mengetahui', 'mengatakan', 'bicara', 'jawab', 'tanya', 'cari',
  'temukan', 'kirim', 'baca', 'tulis', 'kerja', 'belajar', 'sebut', 'disebutkan', 'menyebutkan',
  'turun', 'penurunan', 'naik', 'kenaikan',
  'halo', 'hai', 'selamat', 'terima', 'kasih', 'makasih', 'sama', 'silakan', 'mohon', 'maaf',
  'iya', 'ya', 'bukan', 'benar', 'betul', 'salah', 'oke', 'baik', 'baiklah', 'tentu', 'siap',
  'salam', 'jumpa', 'pasti', 'pastinya',
  'sangat', 'amat', 'sekali', 'cukup', 'kurang', 'lebih', 'paling', 'banyak', 'sedikit',
  'hanya', 'cuma', 'hampir', 'selalu', 'sering', 'kadang', 'jarang', 'semua',
  'seluruh', 'setiap', 'tiap', 'beberapa', 'sebagian', 'lain', 'lainnya', 'tersebut',
  'nol', 'satu', 'dua', 'tiga', 'empat', 'lima', 'enam', 'tujuh', 'delapan', 'sembilan',
  'sepuluh', 'belas', 'puluh', 'ratus', 'ribu', 'juta', 'miliar', 'pertama', 'kedua', 'ketiga',
  'orang', 'teman', 'nama', 'tempat', 'jalan', 'kota', 'negara', 'indonesia', 'bahasa',
  'dunia', 'rumah', 'kantor', 'sekolah', 'uang', 'harga', 'info', 'informasi', 'berita',
  'gambar', 'pesan', 'teks', 'aplikasi', 'sistem', 'hal', 'cara', 'contoh', 'hasil',
  'sumber', 'daftar', 'liter', 'bbm', 'pertamina', 'pertalite', 'pertamax', 'solar',
  'kabar',
};

const _enHints = {
  'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does',
  'did', 'you', 'your', 'yours', 'we', 'our', 'ours', 'they', 'them', 'their', 'theirs', 'he',
  'him', 'his', 'she', 'her', 'hers', 'it', 'its', 'what', 'which', 'who', 'whom', 'whose',
  'when', 'where', 'why', 'how', 'this', 'that', 'these', 'those', 'with', 'for', 'and', 'not',
  'can', 'could', 'would', 'should', 'will', 'shall', 'may', 'might', 'must', 'about', 'from',
  'into', 'through', 'during', 'before', 'after', 'above', 'below', 'to', 'of', 'in', 'on', 'at',
  'by', 'up', 'down', 'out', 'off', 'over', 'under', 'again', 'further', 'then', 'once', 'here',
  'there', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no',
  'nor', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 'just', 'because', 'as', 'until',
  'while', 'maybe', 'something', 'anything', 'nothing', 'someone', 'anyone', 'everyone',
  'today', 'tomorrow', 'yesterday', 'now', 'time', 'day', 'days', 'week', 'month', 'year',
  'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'january',
  'february', 'march', 'april', 'june', 'july', 'august', 'september', 'october',
  'november', 'december', 'please', 'help', 'thank', 'thanks', 'good', 'morning', 'afternoon',
  'evening', 'night', 'hello', 'hi', 'yes', 'yeah', 'sure', 'okay', 'like', 'make', 'get',
  'see', 'know', 'think', 'take', 'come', 'go', 'give', 'look', 'tell', 'ask', 'answer',
  'latest', 'status', 'project',
};
