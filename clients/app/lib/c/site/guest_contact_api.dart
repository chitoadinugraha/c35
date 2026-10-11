import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> guestContactPutBody({
  required int siteIid,
  required String name,
  required String contactVal,
  String message = '',
}) {
  return {
    'site_iid': siteIid,
    'name': name,
    'contact_val': contactVal,
    'message': message,
  };
}

class GuestContactApi {
  static String get _apiBase => C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');

  static Future<Map<String, dynamic>> contactPut({
    required int siteIid,
    required String name,
    required String contactVal,
    String message = '',
  }) async {
    final resp = await http.post(
      Uri.parse('$_apiBase/v1/site/guest-contact/put'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(guestContactPutBody(
        siteIid: siteIid,
        name: name,
        contactVal: contactVal,
        message: message,
      )),
    );
    final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) {
      throw StateError('Gagal kirim');
    }
    if (resp.statusCode != 200 || data['ok'] == false) {
      final msg = data['error']?.toString().trim();
      throw StateError(msg == null || msg.isEmpty ? 'Gagal kirim' : msg);
    }
    return data;
  }
}
