/// Parsed `commerce_boot` from `site_boot_get` / published `__SITE_GUEST__`.
class GuestCommerceBoot {
  const GuestCommerceBoot({
    required this.enabled,
    this.products = const [],
    this.objects = const [],
    this.taxes = const [],
    this.paymentMethods = const [],
  });

  final bool enabled;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> objects;
  final List<Map<String, dynamic>> taxes;
  final List<Map<String, dynamic>> paymentMethods;

  factory GuestCommerceBoot.fromJson(Object? raw) {
    if (raw is! Map) {
      return const GuestCommerceBoot(enabled: false);
    }
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    final enabled = map['enabled'] != false;
    return GuestCommerceBoot(
      enabled: enabled,
      products: _list(map['products']),
      objects: _list(map['objects']),
      taxes: _list(map['taxes']),
      paymentMethods: _list(map['payment_methods']),
    );
  }

  Map<int, Map<String, dynamic>> productCatalog() {
    final out = <int, Map<String, dynamic>>{};
    for (final row in products) {
      final id = (row['product_id'] as num?)?.toInt();
      if (id != null && id > 0) out[id] = row;
    }
    return out;
  }

  static List<Map<String, dynamic>> _list(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) item.map((k, v) => MapEntry(k.toString(), v)),
    ];
  }
}

int guestCommerceTaxTotal(int subtotal, List<Map<String, dynamic>> taxes) {
  var tax = 0;
  for (final row in taxes) {
    final pct = (row['percent'] as num?)?.toDouble() ?? 0;
    if (pct <= 0) continue;
    tax += (subtotal * pct / 100).round();
  }
  return tax;
}

String guestPaymentChoiceLabel(String paymentId, List<Map<String, dynamic>> methods) {
  for (final m in methods) {
    if (m['id']?.toString() == paymentId) {
      final title = m['title']?.toString().trim() ?? '';
      if (title.isNotEmpty) return title;
    }
  }
  return paymentId;
}

String guestOrderNoteWithPayment({
  required String note,
  required String paymentId,
  required List<Map<String, dynamic>> paymentMethods,
}) {
  final trimmed = note.trim();
  final pay = guestPaymentChoiceLabel(paymentId, paymentMethods).trim();
  if (pay.isEmpty) return trimmed;
  final line = 'Pembayaran: $pay';
  if (trimmed.isEmpty) return line;
  if (trimmed.contains(line)) return trimmed;
  return '$trimmed\n$line';
}