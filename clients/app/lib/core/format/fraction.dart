/// Quantity as whole + fraction parts (e.g. portion pickers).
int _gcd(int a, int b) {
  var x = a.abs();
  var y = b.abs();
  while (y != 0) {
    final t = y;
    y = x % y;
    x = t;
  }
  return x == 0 ? 1 : x;
}

({int num, int den}) fractionFromQty(double qty, {int maxDen = 12}) {
  if (qty <= 0 || !qty.isFinite) return (num: 1, den: 1);
  if (qty == qty.roundToDouble()) return (num: qty.round(), den: 1);

  var bestNum = 1;
  var bestDen = 1;
  var bestErr = double.infinity;
  for (var d = 1; d <= maxDen; d++) {
    final n = (qty * d).round();
    if (n < 1) continue;
    final err = (qty - n / d).abs();
    if (err < bestErr) {
      bestErr = err;
      bestNum = n;
      bestDen = d;
    }
  }
  final g = _gcd(bestNum, bestDen);
  return (num: bestNum ~/ g, den: bestDen ~/ g);
}

({int whole, int fracNum, int fracDen}) fractionPartsFromQty(double qty, {int maxDen = 12}) {
  if (qty <= 0 || !qty.isFinite) return (whole: 1, fracNum: 0, fracDen: 1);
  final whole = qty.floor();
  final rem = qty - whole;
  if (rem < 0.001) return (whole: whole, fracNum: 0, fracDen: 1);
  final f = fractionFromQty(rem, maxDen: maxDen);
  return (whole: whole, fracNum: f.num, fracDen: f.den);
}

double fractionPartsToQty(int whole, int fracNum, int fracDen) {
  if (fracNum <= 0 || fracDen <= 0) return whole.toDouble();
  return whole + fracNum / fracDen;
}

String fractionPartsLabel(int num, int den) {
  if (den == 1) return '$num';
  if (num <= den) return '$num/$den';
  final whole = num ~/ den;
  final rem = num % den;
  if (rem == 0) return '$whole';
  return '$whole $rem/$den';
}

String _fracShortLabel(int num, int den) => switch ((num, den)) {
      (1, 8) => '⅛',
      (1, 6) => '⅙',
      (1, 5) => '⅕',
      (1, 4) => '¼',
      (1, 3) => '⅓',
      (3, 8) => '⅜',
      (1, 2) => '½',
      (5, 8) => '⅝',
      (2, 3) => '⅔',
      (3, 4) => '¾',
      (4, 5) => '⅘',
      (5, 6) => '⅚',
      (7, 8) => '⅞',
      _ => fractionPartsLabel(num, den),
    };

String fractionQtyPartsLabel(int whole, int fracNum, int fracDen) {
  if (fracNum <= 0 || fracDen <= 0) return '$whole';
  final frac = _fracShortLabel(fracNum, fracDen);
  if (whole <= 0) return frac;
  return '$whole $frac';
}

String fractionLabel(double qty, {int maxDen = 12}) {
  final p = fractionPartsFromQty(qty, maxDen: maxDen);
  return fractionQtyPartsLabel(p.whole, p.fracNum, p.fracDen);
}
