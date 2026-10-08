import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> guestOrderPutBody({
  required int siteIid,
  required String customerName,
  String customerPhone = '',
  String note = '',
  required List<Map<String, dynamic>> items,
  List<Map<String, dynamic>> reservations = const [],
}) {
  final payloadItems = [
    for (final item in items) _itemWithReservations(item, reservations),
  ];
  return {
    'site_iid': siteIid,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'note': note,
    'reservations': [
      for (final item in payloadItems)
        if (item['reservations'] is List) ...(item['reservations'] as List).whereType<Map<String, dynamic>>(),
    ],
    'tx': {
      'subject_name': customerName,
      'subject_phone': customerPhone,
      'desc': note,
      'items': payloadItems,
    },
  };
}

Map<String, dynamic> _itemWithReservations(Map<String, dynamic> item, List<Map<String, dynamic>> reservations) {
  final existing = item['reservations'];
  if (existing is List && existing.isNotEmpty) return item;
  final pid = item['product_id'];
  final mine = [
    for (final row in reservations)
      if (row['product_id'] == pid) row,
  ];
  if (mine.isEmpty) return item;
  return {...item, 'reservations': mine};
}

class GuestOrderApi {
  static String get _apiBase => C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');

  static Future<Map<String, dynamic>> orderGet({required int siteIid, required int txId}) async {
    final resp = await http.post(
      Uri.parse('$_apiBase/v1/site/guest-order/get'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'site_iid': siteIid, 'tx_id': txId}),
    );
    if (resp.statusCode != 200) throw StateError(resp.body);
    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) throw StateError('invalid guest order response');
    return data;
  }

  static Future<Map<String, dynamic>> orderPut({
    required int siteIid,
    required String customerName,
    String customerPhone = '',
    String note = '',
    required List<Map<String, dynamic>> items,
    List<Map<String, dynamic>> reservations = const [],
  }) async {
    final resp = await http.post(
      Uri.parse('$_apiBase/v1/site/guest-order/put'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(guestOrderPutBody(
        siteIid: siteIid,
        customerName: customerName,
        customerPhone: customerPhone,
        note: note,
        items: items,
        reservations: reservations,
      )),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      final msg = data is Map ? data['error']?.toString() ?? resp.body : resp.body;
      throw StateError(msg);
    }
    if (data is! Map<String, dynamic>) throw StateError('invalid guest order response');
    return data;
  }
}