import 'package:alienai_c35/c/ui/money_format.dart';

class SiteProductPasteRow {
  const SiteProductPasteRow({required this.name, this.description = '', this.price = 0});

  final String name;
  final String description;
  final int price;

  SiteProductPasteRow copyWith({String? name, String? description, int? price}) => SiteProductPasteRow(
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
      );
}

const _headerAliases = {
  'name': ['nama', 'name', 'produk', 'product', 'item'],
  'price': ['harga', 'price'],
  'desc': ['desc', 'description', 'deskripsi', 'keterangan'],
};

String _normalizeHeader(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String? _headerKind(String value) {
  final normalized = _normalizeHeader(value);
  for (final entry in _headerAliases.entries) {
    for (final alias in entry.value) {
      if (normalized == alias || normalized.startsWith('$alias ')) return entry.key;
    }
  }
  return null;
}

int _parsePriceToken(String raw) {
  final compact = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final rb = RegExp(r'^(\d[\d.,]*)(?:rb|k)$').firstMatch(compact);
  if (rb != null) {
    final base = moneyParseIdrInt(rb.group(1)!) ?? 0;
    return base > 0 ? base * 1000 : 0;
  }
  final jt = RegExp(r'^(\d[\d.,]*)(?:jt|juta|m)$').firstMatch(compact);
  if (jt != null) {
    final base = moneyParseIdrInt(jt.group(1)!) ?? 0;
    return base > 0 ? base * 1000000 : 0;
  }
  return moneyParseIdrInt(compact) ?? 0;
}

bool _looksLikePrice(String value) => value.trim().isNotEmpty && _parsePriceToken(value) > 0;

({String name, int price})? _parseTrailingAmount(String input) {
  final match = RegExp(r'^(.+?)\s+(\S+)$').firstMatch(input.trim());
  if (match == null) return null;
  final price = _parsePriceToken(match.group(2)!);
  if (price <= 0) return null;
  return (name: match.group(1)!.trim(), price: price);
}

String _detectDelimiter(List<String> lines) {
  var tab = 0, comma = 0, semi = 0;
  for (final line in lines) {
    if (line.contains('\t')) tab++;
    if (line.contains(',')) comma++;
    if (line.contains(';')) semi++;
  }
  if (tab >= comma && tab >= semi && tab > 0) return '\t';
  if (semi >= comma && semi > 0) return ';';
  if (comma > 0) return ',';
  return '\t';
}

List<String> _splitLine(String line, String delimiter) {
  if (delimiter == '\t') return line.split('\t').map((c) => c.trim()).toList();
  return line
      .split(delimiter)
      .map((c) => c.trim().replaceAll(RegExp(r'''^["']|["']$'''), ''))
      .toList();
}

Map<String, int> _mapHeaderColumns(List<String> cells) {
  final map = <String, int>{};
  for (var i = 0; i < cells.length; i++) {
    final kind = _headerKind(cells[i]);
    if (kind != null && !map.containsKey(kind)) map[kind] = i;
  }
  return map;
}

SiteProductPasteRow? _rowFromCells(List<String> cells, Map<String, int> columns) {
  String pick(String kind, int fallback) =>
      columns.containsKey(kind) ? (cells[columns[kind]!]) : (cells.length > fallback ? cells[fallback] : '');

  var name = '';
  var description = '';
  var price = 0;

  if (columns.containsKey('name') || columns.containsKey('price') || columns.containsKey('desc')) {
    name = pick('name', 0);
    description = pick('desc', 2);
    price = _parsePriceToken(pick('price', 1));
  } else if (cells.length >= 3) {
    name = cells[0];
    price = _parsePriceToken(cells[1]);
    description = cells.sublist(2).join(' ').trim();
  } else if (cells.length == 2) {
    name = cells[0];
    if (_looksLikePrice(cells[1])) {
      price = _parsePriceToken(cells[1]);
    } else {
      description = cells[1];
    }
  } else if (cells.length == 1) {
    final trailing = _parseTrailingAmount(cells[0]);
    if (trailing != null) {
      name = trailing.name;
      price = trailing.price;
    } else {
      name = cells[0];
    }
  }

  name = name.trim();
  description = description.trim();
  if (name.isEmpty) return null;
  return SiteProductPasteRow(name: name, description: description, price: price);
}

List<SiteProductPasteRow> siteProductParsePasteText(String text) {
  final lines = text
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return [];

  final delimiter = _detectDelimiter(lines);
  final splitLines = lines.map((l) => _splitLine(l, delimiter)).toList();
  final headerColumns = _mapHeaderColumns(splitLines.first);
  final hasHeader = headerColumns.containsKey('name') ||
      headerColumns.containsKey('price') ||
      headerColumns.containsKey('desc');
  final dataLines = hasHeader ? splitLines.sublist(1) : splitLines;

  return dataLines
      .map((cells) => _rowFromCells(cells, hasHeader ? headerColumns : {}))
      .whereType<SiteProductPasteRow>()
      .toList();
}
