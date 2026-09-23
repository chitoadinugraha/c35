import 'package:alienai_c35/c/expense/expense_receipt.dart';

class ExpenseCategoryBreakdown {
  const ExpenseCategoryBreakdown({required this.label, this.path = '', this.totalMinor = 0});

  final String label;
  final String path;
  final int totalMinor;

  factory ExpenseCategoryBreakdown.fromJson(Map<String, dynamic> j) => ExpenseCategoryBreakdown(
        label: j['label']?.toString() ?? '',
        path: j['path']?.toString() ?? '',
        totalMinor: (j['total_minor'] as num?)?.round() ?? 0,
      );
}

class ExpenseRecentReceipt {
  const ExpenseRecentReceipt({
    required this.txId,
    required this.label,
    this.subtitle = '',
    this.totalMinor = 0,
    this.photoHash = '',
  });

  final String txId;
  final String label;
  final String subtitle;
  final int totalMinor;
  final String photoHash;

  factory ExpenseRecentReceipt.fromJson(Map<String, dynamic> j) => ExpenseRecentReceipt(
        txId: j['tx_id']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        subtitle: j['subtitle']?.toString() ?? '',
        totalMinor: (j['total_minor'] as num?)?.round() ?? 0,
        photoHash: j['photo_hash']?.toString() ?? '',
      );
}

class ExpenseGlanceCard {
  const ExpenseGlanceCard({
    required this.periodId,
    this.periodLabel = '',
    this.coach = '',
    this.totalMinor = 0,
    this.txCount = 0,
    this.currency = 'IDR',
    this.matchedQuery = '',
    this.matchedTotalMinor = 0,
    this.categoryBreakdown = const [],
    this.recent = const [],
  });

  final String periodId;
  final String periodLabel;
  final String coach;
  final int totalMinor;
  final int txCount;
  final String currency;
  final String matchedQuery;
  final int matchedTotalMinor;
  final List<ExpenseCategoryBreakdown> categoryBreakdown;
  final List<ExpenseRecentReceipt> recent;

  String amountLabel() => expenseFmtIdr(totalMinor);

  factory ExpenseGlanceCard.fromBlockBody(Map<String, dynamic> body) {
    final rawCategories = body['category_breakdown'] as List? ?? const [];
    final rawRecent = body['recent'] as List? ?? const [];
    return ExpenseGlanceCard(
      periodId: body['period_id']?.toString() ?? '',
      periodLabel: body['period_label']?.toString() ?? '',
      coach: body['coach']?.toString() ?? '',
      totalMinor: (body['total_minor'] as num?)?.round() ?? 0,
      txCount: (body['tx_count'] as num?)?.round() ?? 0,
      currency: body['currency']?.toString() ?? 'IDR',
      matchedQuery: body['matched_query']?.toString() ?? '',
      matchedTotalMinor: (body['matched_total_minor'] as num?)?.round() ?? 0,
      categoryBreakdown: rawCategories.map((e) => ExpenseCategoryBreakdown.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      recent: rawRecent.map((e) => ExpenseRecentReceipt.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  String periodTitle(String locale) {
    final label = periodLabel.trim();
    if (label.isNotEmpty) return label;
    final id = locale.toLowerCase().startsWith('id');
    final d = periodId.trim();
    if (d.isEmpty) return id ? 'Hari ini' : 'Today';
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yid = '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (d == today) return id ? 'Hari ini' : 'Today';
    if (d == yid) return id ? 'Kemarin' : 'Yesterday';
    return d;
  }
}
