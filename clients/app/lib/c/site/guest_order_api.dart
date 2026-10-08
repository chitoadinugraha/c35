import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:http/http.dart' as http;

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
  }) async {
    final resp = await http.post(
      Uri.parse('$_apiBase/v1/site/guest-order/put'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'site_iid': siteIid,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'note': note,
        'tx': {
          'subject_name': customerName,
          'subject_phone': customerPhone,
          'desc': note,
          'items': items,
        },
      }),
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