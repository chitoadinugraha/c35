import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:http/http.dart' as http;

class GuestMemberProfile {
  const GuestMemberProfile({
    required this.userIid,
    required this.displayName,
    required this.pic,
    required this.email,
    required this.contactId,
  });

  final int userIid;
  final String displayName;
  final String pic;
  final String email;
  final int contactId;

  static GuestMemberProfile fromJson(Map<String, dynamic> json) => GuestMemberProfile(
        userIid: (json['user_iid'] as num?)?.toInt() ?? 0,
        displayName: json['display_name']?.toString() ?? '',
        pic: json['pic']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        contactId: (json['contact_id'] as num?)?.toInt() ?? 0,
      );
}

class GuestMemberOrderSummary {
  const GuestMemberOrderSummary({
    required this.txId,
    required this.state,
    required this.total,
    required this.progressLabel,
  });

  final int txId;
  final String state;
  final int total;
  final String progressLabel;

  static GuestMemberOrderSummary fromJson(Map<String, dynamic> json) => GuestMemberOrderSummary(
        txId: (json['tx_id'] as num?)?.toInt() ?? 0,
        state: json['state']?.toString() ?? '',
        total: (json['total'] as num?)?.toInt() ?? 0,
        progressLabel: json['progress_label']?.toString() ?? '',
      );
}

class GuestMemberApi {
  static String get _apiBase => C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');

  static Map<String, String> _headers() {
    final token = sessionAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<GuestMemberProfile> me({required int siteIid}) async {
    final resp = await http.post(
      Uri.parse('$_apiBase/v1/site/guest-member/me'),
      headers: _headers(),
      body: jsonEncode({'site_iid': siteIid}),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data is! Map<String, dynamic>) {
      final msg = data is Map ? data['error']?.toString() ?? resp.body : resp.body;
      throw StateError(msg);
    }
    return GuestMemberProfile.fromJson(data);
  }

  static Future<List<GuestMemberOrderSummary>> orderList({required int siteIid}) async {
    final resp = await http.post(
      Uri.parse('$_apiBase/v1/site/guest-order/list'),
      headers: _headers(),
      body: jsonEncode({'site_iid': siteIid}),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data is! Map<String, dynamic>) {
      final msg = data is Map ? data['error']?.toString() ?? resp.body : resp.body;
      throw StateError(msg);
    }
    final raw = data['orders'];
    if (raw is! List) return [];
    return raw.map((e) => GuestMemberOrderSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<int> merge({
    required int siteIid,
    required String visitorId,
    required List<int> orderIds,
  }) async {
    final resp = await http.post(
      Uri.parse('$_apiBase/v1/site/guest-member/merge'),
      headers: _headers(),
      body: jsonEncode({
        'site_iid': siteIid,
        'visitor_id': visitorId,
        'order_ids': orderIds,
      }),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data is! Map<String, dynamic>) {
      final msg = data is Map ? data['error']?.toString() ?? resp.body : resp.body;
      throw StateError(msg);
    }
    return (data['merged_count'] as num?)?.toInt() ?? 0;
  }
}
