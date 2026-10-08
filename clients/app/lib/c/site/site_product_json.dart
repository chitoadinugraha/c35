import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:fixnum/fixnum.dart';

/// Extended catalog fields stored in [SiteProduct.productJson] (CSA SiteProductDraft parity).
class SiteProductExtras {
  const SiteProductExtras({
    this.active = true,
    this.sortOrder = 0,
    this.durationValue = 1,
    this.durationUnit = 'day',
    this.reservationGuestPicks = false,
    this.stockUnit = '',
    this.stockWarningEnabled = false,
    this.stockWarningQty = 0,
    this.stockCriticalEnabled = false,
    this.stockCriticalQty = 0,
    this.stockShowToCustomer = false,
    this.stockShowMaxQty = 0,
  });

  final bool active;
  final int sortOrder;
  final int durationValue;
  final String durationUnit;
  final bool reservationGuestPicks;
  final String stockUnit;
  final bool stockWarningEnabled;
  final int stockWarningQty;
  final bool stockCriticalEnabled;
  final int stockCriticalQty;
  final bool stockShowToCustomer;
  final int stockShowMaxQty;

  SiteProductExtras copyWith({
    bool? active,
    int? sortOrder,
    int? durationValue,
    String? durationUnit,
    bool? reservationGuestPicks,
    String? stockUnit,
    bool? stockWarningEnabled,
    int? stockWarningQty,
    bool? stockCriticalEnabled,
    int? stockCriticalQty,
    bool? stockShowToCustomer,
    int? stockShowMaxQty,
  }) =>
      SiteProductExtras(
        active: active ?? this.active,
        sortOrder: sortOrder ?? this.sortOrder,
        durationValue: durationValue ?? this.durationValue,
        durationUnit: durationUnit ?? this.durationUnit,
        reservationGuestPicks: reservationGuestPicks ?? this.reservationGuestPicks,
        stockUnit: stockUnit ?? this.stockUnit,
        stockWarningEnabled: stockWarningEnabled ?? this.stockWarningEnabled,
        stockWarningQty: stockWarningQty ?? this.stockWarningQty,
        stockCriticalEnabled: stockCriticalEnabled ?? this.stockCriticalEnabled,
        stockCriticalQty: stockCriticalQty ?? this.stockCriticalQty,
        stockShowToCustomer: stockShowToCustomer ?? this.stockShowToCustomer,
        stockShowMaxQty: stockShowMaxQty ?? this.stockShowMaxQty,
      );
}

Map<String, dynamic> siteProductJsonMap(String raw) {
  if (raw.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}

SiteProductExtras siteProductExtrasRead(SiteProduct product) {
  final map = siteProductJsonMap(product.productJson);
  final active = map['active'] is bool ? map['active'] as bool : !product.isArchived;
  final sortFromJson = (map['sort_order'] as num?)?.toInt();
  final sortOrder = product.sortOrder != 0 ? product.sortOrder : (sortFromJson ?? 0);
  final durationValue = (map['duration_value'] as num?)?.toInt();
  final unitRaw = map['duration_unit']?.toString().trim() ?? '';
  final reservationSel = map['reservation_unit_selection']?.toString().trim() ?? '';
  return SiteProductExtras(
    active: active,
    sortOrder: sortOrder,
    durationValue: durationValue != null && durationValue > 0 ? durationValue : 1,
    durationUnit: unitRaw.isEmpty ? 'day' : unitRaw,
    reservationGuestPicks: reservationSel == 'guest_picks',
    stockUnit: map['stock_unit']?.toString() ?? '',
    stockWarningEnabled: map['stock_warning_enabled'] == true,
    stockWarningQty: (map['stock_warning_qty'] as num?)?.toInt() ?? 0,
    stockCriticalEnabled: map['stock_critical_enabled'] == true,
    stockCriticalQty: (map['stock_critical_qty'] as num?)?.toInt() ?? 0,
    stockShowToCustomer: map['stock_show_to_customer'] == true,
    stockShowMaxQty: (map['stock_show_max_qty'] as num?)?.toInt() ?? 0,
  );
}

Map<String, dynamic> siteProductExtrasToJsonMap(SiteProductExtras extras) => {
      'active': extras.active,
      'sort_order': extras.sortOrder,
      'duration_value': extras.durationValue,
      'duration_unit': extras.durationUnit,
      'reservation_unit_selection': extras.reservationGuestPicks ? 'guest_picks' : 'system',
      'stock_unit': extras.stockUnit,
      'stock_warning_enabled': extras.stockWarningEnabled,
      'stock_warning_qty': extras.stockWarningQty,
      'stock_critical_enabled': extras.stockCriticalEnabled,
      'stock_critical_qty': extras.stockCriticalQty,
      'stock_show_to_customer': extras.stockShowToCustomer,
      'stock_show_max_qty': extras.stockShowMaxQty,
    };

List<String> siteProductBarcodesRead(SiteProduct product) {
  final map = siteProductJsonMap(product.productJson);
  final fromList = map['barcodes'];
  if (fromList is List) {
    return fromList.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList(growable: false);
  }
  final legacy = map['barcode']?.toString().trim() ?? '';
  return legacy.isEmpty ? const [] : [legacy];
}

SiteProduct siteProductApplyBarcodes(SiteProduct product, List<String> barcodes) {
  final out = product.clone();
  final map = siteProductJsonMap(out.productJson);
  map.remove('barcode');
  final clean = barcodes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
  if (clean.isEmpty) {
    map.remove('barcodes');
  } else {
    map['barcodes'] = clean;
  }
  out.productJson = jsonEncode(map);
  return out;
}

/// Gallery images (excluding primary [SiteProduct.pic]).
List<String> siteProductPicsRead(SiteProduct product) {
  final map = siteProductJsonMap(product.productJson);
  final raw = map['pics'];
  if (raw is! List) return const [];
  return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty && e != product.pic).toList(growable: false);
}

SiteProduct siteProductApplyPics(SiteProduct product, List<String> pics) {
  final out = product.clone();
  final map = siteProductJsonMap(out.productJson);
  final clean = pics.map((e) => e.trim()).where((e) => e.isNotEmpty && e != out.pic).toList(growable: false);
  if (clean.isEmpty) {
    map.remove('pics');
  } else {
    map['pics'] = clean;
  }
  out.productJson = jsonEncode(map);
  return out;
}

String siteProductJsonMergeExtras(String productJson, SiteProductExtras extras) {
  final base = siteProductJsonMap(productJson);
  base.addAll(siteProductExtrasToJsonMap(extras));
  return jsonEncode(base);
}

SiteProduct siteProductApplyExtras(SiteProduct product, SiteProductExtras extras) {
  final out = product.clone();
  out.isArchived = !extras.active;
  out.sortOrder = extras.sortOrder;
  out.productJson = siteProductJsonMergeExtras(out.productJson, extras);
  return out;
}

SiteProduct siteProductFromPasteRow(
  int siteIid, {
  required String name,
  String description = '',
  int price = 0,
  SiteProductExtras extras = const SiteProductExtras(),
}) {
  final base = SiteProduct(
    siteIid: Int64(siteIid),
    name: name,
    desc: description,
    price: Int64(price),
    canSell: true,
  );
  return siteProductApplyExtras(base, extras);
}
