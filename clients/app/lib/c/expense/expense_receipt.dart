import 'package:alienai_c35/c/ui/money_format.dart';

String expenseFmtIdr(int minor) => 'Rp ${moneyFmtIdrGrouped(minor)}';

class ExpenseItemRow {
  ExpenseItemRow({
    required this.name,
    this.nameId = '',
    this.qty = 1,
    this.priceMinor = 0,
    this.totalMinor = 0,
    this.objId = 0,
  });

  String name;
  String nameId;
  double qty;
  int priceMinor;
  int totalMinor;
  int objId;

  String label(String locale) {
    final isId = locale.toLowerCase().startsWith('id');
    if (isId && nameId.trim().isNotEmpty) return nameId.trim();
    if (!isId && name.trim().isNotEmpty) return name.trim();
    if (nameId.trim().isNotEmpty) return nameId.trim();
    if (name.trim().isNotEmpty) return name.trim();
    return isId ? 'Item' : 'Item';
  }

  int lineTotal() => totalMinor > 0 ? totalMinor : (priceMinor * (qty > 0 ? qty : 1)).round();

  factory ExpenseItemRow.fromJson(Map<String, dynamic> j) => ExpenseItemRow(
        name: j['name']?.toString() ?? '',
        nameId: j['name_id']?.toString() ?? '',
        qty: (j['qty'] as num?)?.toDouble() ?? 1,
        priceMinor: (j['price_minor'] as num?)?.round() ?? 0,
        totalMinor: (j['total_minor'] as num?)?.round() ?? 0,
        objId: (j['obj_id'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_id': nameId,
        'qty': qty,
        'price_minor': priceMinor,
        'total_minor': totalMinor,
        'obj_id': objId,
      };
}

class ExpenseTodaySummary {
  const ExpenseTodaySummary({this.soFarMinor = 0, this.afterMinor = 0, this.txCount = 0});

  final int soFarMinor;
  final int afterMinor;
  final int txCount;

  factory ExpenseTodaySummary.fromJson(Map<String, dynamic> j) => ExpenseTodaySummary(
        soFarMinor: (j['so_far_minor'] as num?)?.round() ?? 0,
        afterMinor: (j['after_minor'] as num?)?.round() ?? 0,
        txCount: (j['tx_count'] as num?)?.round() ?? 0,
      );
}

class ExpenseReceiptCard {
  const ExpenseReceiptCard({
    required this.txId,
    required this.headline,
    this.subtitle = '',
    this.coach = '',
    this.totalMinor = 0,
    this.currency = 'IDR',
    this.saved = true,
    this.duplicate = false,
    this.duplicateReason = '',
    this.photoHash = '',
    this.paymentMethod = '',
    this.items = const [],
    this.today = const ExpenseTodaySummary(),
  });

  final String txId;
  final String headline;
  final String subtitle;
  final String coach;
  final int totalMinor;
  final String currency;
  final bool saved;
  final bool duplicate;
  final String duplicateReason;
  final String photoHash;
  final String paymentMethod;
  final List<ExpenseItemRow> items;
  final ExpenseTodaySummary today;

  String amountLabel() => expenseFmtIdr(totalMinor);

  factory ExpenseReceiptCard.fromBlockBody(Map<String, dynamic> body) {
    final today = Map<String, dynamic>.from(body['today'] as Map? ?? const {});
    final rawItems = body['items'] as List? ?? const [];
    return ExpenseReceiptCard(
      txId: body['tx_id']?.toString() ?? '',
      headline: body['headline']?.toString() ?? '',
      subtitle: body['subtitle']?.toString() ?? '',
      coach: body['coach']?.toString() ?? '',
      totalMinor: (body['total_minor'] as num?)?.round() ?? 0,
      currency: body['currency']?.toString() ?? 'IDR',
      saved: body['saved'] != false,
      duplicate: body['duplicate'] == true,
      duplicateReason: body['duplicate_reason']?.toString() ?? '',
      photoHash: body['photo_hash']?.toString() ?? '',
      paymentMethod: body['payment_method']?.toString() ?? '',
      items: rawItems.map((e) => ExpenseItemRow.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      today: ExpenseTodaySummary.fromJson(today),
    );
  }
}
