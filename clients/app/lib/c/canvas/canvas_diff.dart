import 'dart:math';

enum DiffLineType {
  unchanged,
  added,
  removed,
}

class CanvasDiffLine {
  const CanvasDiffLine({
    required this.type,
    required this.text,
    this.oldLine,
    this.newLine,
  });

  final DiffLineType type;
  final String text;
  final int? oldLine;
  final int? newLine;
}

List<CanvasDiffLine> computeCanvasDiff(String oldText, String newText) {
  if (oldText.isEmpty && newText.isEmpty) return const [];

  final a = oldText.isEmpty ? <String>[] : oldText.split('\n');
  final b = newText.isEmpty ? <String>[] : newText.split('\n');

  final n = a.length;
  final m = b.length;

  // LCS dynamic programming table
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));

  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      if (a[i - 1] == b[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
      }
    }
  }

  // Backtrack to build diff
  final diff = <CanvasDiffLine>[];
  var i = n;
  var j = m;

  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && a[i - 1] == b[j - 1]) {
      diff.add(CanvasDiffLine(
        type: DiffLineType.unchanged,
        text: a[i - 1],
        oldLine: i,
        newLine: j,
      ));
      i--;
      j--;
    } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
      diff.add(CanvasDiffLine(
        type: DiffLineType.added,
        text: b[j - 1],
        newLine: j,
      ));
      j--;
    } else if (i > 0 && (j == 0 || dp[i][j - 1] < dp[i - 1][j])) {
      diff.add(CanvasDiffLine(
        type: DiffLineType.removed,
        text: a[i - 1],
        oldLine: i,
      ));
      i--;
    }
  }

  return diff.reversed.toList();
}

typedef CanvasDiffType = DiffLineType;

extension CanvasDiffLinesExt on List<CanvasDiffLine> {
  int get addedCount => where((l) => l.type == DiffLineType.added).length;
  int get removedCount => where((l) => l.type == DiffLineType.removed).length;
  bool get hasDifferences => any((l) => l.type != DiffLineType.unchanged);
}
