import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

const _alienaiMailDomain = 'alienai.id';

String gravatarUrlForEmail(String email, {int size = 80}) {
  final normalized = email.trim().toLowerCase();
  if (normalized.isEmpty || !normalized.contains('@')) return '';
  final hash = md5.convert(utf8.encode(normalized)).toString();
  return 'https://www.gravatar.com/avatar/$hash?s=$size&d=404';
}

String? alienIdFromAlienaiEmail(String email) {
  final e = email.trim().toLowerCase();
  final at = e.indexOf('@');
  if (at <= 0) return null;
  final local = e.substring(0, at);
  final domain = e.substring(at + 1);
  if (domain != _alienaiMailDomain || local.isEmpty) return null;
  return local;
}

String mailEmailAvatarLetter(String email) {
  final e = email.trim();
  if (e.isEmpty) return '?';
  return e[0].toUpperCase();
}

Color mailEmailAvatarColor(String email) {
  final hash = email.hashCode.abs();
  const colors = [
    Color(0xFF3949AB),
    Color(0xFF00796B),
    Color(0xFF455A64),
    Color(0xFF7B1FA2),
    Color(0xFFE64A19),
    Color(0xFF1976D2),
    Color(0xFF00838F),
    Color(0xFF388E3C),
  ];
  return colors[hash % colors.length];
}

String mailEmailAvatarNetworkUrl({
  required String email,
  String hintUrl = '',
  MailEmailAvatarResolver? resolver,
  int gravatarSize = 80,
}) {
  final baseUrl = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
  final hint = hintUrl.trim();
  if (hint.isNotEmpty) {
    final served = fileImageUrl(hint, baseUrl: baseUrl);
    if (served.isNotEmpty) return served;
    if (hint.startsWith('http://') || hint.startsWith('https://')) return hint;
  }
  final known = resolver?.knownPic(email) ?? '';
  if (known.isNotEmpty) {
    final served = fileImageUrl(known, baseUrl: baseUrl);
    if (served.isNotEmpty) return served;
    if (known.startsWith('http://') || known.startsWith('https://')) return known;
  }
  return gravatarUrlForEmail(email, size: gravatarSize);
}

class MailEmailAvatarResolver {
  final Map<String, String> _picByEmail = {};

  void clear() => _picByEmail.clear();

  void register(String email, String pic) {
    final addr = email.trim().toLowerCase();
    final url = pic.trim();
    if (addr.isEmpty || url.isEmpty) return;
    _picByEmail[addr] = url;
  }

  String? knownPic(String email) => _picByEmail[email.trim().toLowerCase()];
}
