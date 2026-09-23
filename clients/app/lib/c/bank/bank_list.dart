class BankDoc {
  const BankDoc({required this.id, required this.name, required this.shortName});

  final String id;
  final String name;
  final String shortName;
}

class BankList {
  BankList._();

  static List<BankDoc>? _cache;

  static Future<List<BankDoc>> load() async {
    _cache ??= bankListFallback;
    return _cache!;
  }

  static String label(String bankId) {
    final id = bankId.trim();
    if (id.isEmpty) return '';
    for (final b in _cache ?? bankListFallback) {
      if (b.id == id) return b.shortName;
    }
    return id.toUpperCase();
  }
}

const bankListFallback = <BankDoc>[
  BankDoc(id: 'bca', name: 'Bank Central Asia', shortName: 'BCA'),
  BankDoc(id: 'mandiri', name: 'Bank Mandiri', shortName: 'Mandiri'),
  BankDoc(id: 'bni', name: 'Bank Negara Indonesia', shortName: 'BNI'),
  BankDoc(id: 'bri', name: 'Bank Rakyat Indonesia', shortName: 'BRI'),
  BankDoc(id: 'bsi', name: 'Bank Syariah Indonesia', shortName: 'BSI'),
  BankDoc(id: 'cimb', name: 'CIMB Niaga', shortName: 'CIMB Niaga'),
  BankDoc(id: 'danamon', name: 'Bank Danamon', shortName: 'Danamon'),
  BankDoc(id: 'permata', name: 'Bank Permata', shortName: 'Permata'),
  BankDoc(id: 'jago', name: 'Bank Jago', shortName: 'Jago'),
  BankDoc(id: 'seabank', name: 'SeaBank Indonesia', shortName: 'SeaBank'),
];
