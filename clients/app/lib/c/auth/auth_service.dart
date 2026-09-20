import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum AuthSignInBusy { none, password, signUp, google }

class LoginResult {
  const LoginResult({required this.uid, required this.token, required this.name, required this.email, required this.handle, this.pic = ''});
  final int uid;
  final String token;
  final String name;
  final String email;
  final String handle;
  final String pic;
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

String authPicFrom(Map<String, dynamic> data) {
  final id = data['identity'];
  final idMap = id is Map<String, dynamic> ? id : const <String, dynamic>{};
  for (final v in [data['pic'], data['avatar_url'], idMap['pic'], idMap['avatar_url']]) {
    final s = '${v ?? ''}'.trim();
    if (s.isNotEmpty) return s;
  }
  return '';
}

List<String> authGlobalRolesFrom(Map<String, dynamic> data) {
  final id = data['identity'];
  final idMap = id is Map<String, dynamic> ? id : const <String, dynamic>{};
  for (final key in ['global_roles', 'roles', 'badges']) {
    final roles = sessionGlobalRolesParse(data[key] ?? idMap[key]);
    if (roles.isNotEmpty) return roles;
  }
  if (idMap['is_root'] == true) return const ['root'];
  return const [];
}

class AuthService extends ChangeNotifier {
  LoginResult? _login;
  AuthSignInBusy _busy = AuthSignInBusy.none;

  LoginResult? get login => _login;
  bool get signedIn => _login != null || Session.instance.signedIn;
  AuthSignInBusy get busy => _busy;
  bool get anyBusy => _busy != AuthSignInBusy.none;

  Future<void> restore() async {
    await Session.instance.restore();
    if (!Session.instance.signedIn) return;
    final invalid = await validateSessionForServer();
    if (invalid != null) {
      await signOut();
      return;
    }
    _login = LoginResult(
      uid: Session.instance.uid,
      token: Session.instance.token,
      name: Session.instance.name,
      email: Session.instance.email,
      handle: Session.instance.handle,
      pic: Session.instance.pic,
    );
    sessionTick.value++;
    notifyListeners();
  }

  Future<String?> validateSessionForServer() async {
    final token = sessionAuthToken();
    if (token.isEmpty) return 'Missing session token';
    try {
      final res = await http.get(
        Uri.parse('${C35Config.authApiBase}/v1/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return null;
      if (res.statusCode == 401) return 'Invalid session';
      return null;
    } catch (e) {
      lError('Session check failed: $e');
      return null;
    }
  }

  Future<LoginResult> signInWithPassword({required String identifier, required String password}) async {
    _busy = AuthSignInBusy.password;
    notifyListeners();
    try {
      return await _complete(Uri.parse('${C35Config.authApiBase}/v1/auth/signin'), {'login': identifier.trim(), 'password': password});
    } finally {
      _busy = AuthSignInBusy.none;
      notifyListeners();
    }
  }

  Future<LoginResult> signUp({required String name, required String email, required String password, String? referralCode}) async {
    _busy = AuthSignInBusy.signUp;
    notifyListeners();
    try {
      return await _complete(Uri.parse('${C35Config.authApiBase}/v1/auth/signup'), {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (referralCode != null && referralCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').isNotEmpty)
          'referral_code': referralCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase(),
      });
    } finally {
      _busy = AuthSignInBusy.none;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async => throw ApiException('Google sign-in not configured for c35 Phase 1');

  Future<LoginResult> _complete(Uri uri, Map<String, dynamic> body) async {
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw ApiException(data['error'] as String? ?? 'Invalid credentials');
    final token = data['token'] as String? ?? '';
    final idData = data['identity'] as Map<String, dynamic>? ?? {};
    final uid = (idData['id'] as num?)?.toInt() ?? (data['uid'] as num?)?.toInt() ?? 0;
    if (token.isEmpty || uid == 0) throw ApiException('Sign-in failed.');
    return _store(
      LoginResult(
        uid: uid,
        token: token,
        name: '${idData['name'] ?? idData['handle'] ?? data['name'] ?? ''}',
        email: '${idData['email'] ?? data['email'] ?? ''}',
        handle: '${idData['handle'] ?? ''}',
        pic: authPicFrom(data),
      ),
      globalRoles: authGlobalRolesFrom(data),
    );
  }

  Future<LoginResult> _store(LoginResult result, {List<String> globalRoles = const []}) async {
    await Session.instance.put(
      uid: result.uid,
      name: result.name,
      handle: result.handle,
      pic: result.pic,
      email: result.email,
      token: result.token,
      globalRoles: globalRoles,
    );
    _login = LoginResult(uid: result.uid, token: result.token, name: result.name, email: result.email, handle: result.handle, pic: result.pic);
    notifyListeners();
    return _login!;
  }

  Future<void> signOut({bool clearStored = true}) async {
    final token = sessionAuthToken();
    if (token.isNotEmpty) {
      try {
        await http.post(Uri.parse('${C35Config.authApiBase}/v1/auth/signout'), headers: {'Authorization': 'Bearer $token'});
      } catch (_) {}
    }
    await Session.instance.clear(clearStored: clearStored);
    _login = null;
    notifyListeners();
  }
}

String uiAuthError(Object e) {
  if (e is ApiException) return uiApiErrorMessage(e.message, fallback: 'Sign-in failed. Please try again.');
  return uiFriendlyError(e, fallback: 'Sign-in failed. Please try again.');
}
