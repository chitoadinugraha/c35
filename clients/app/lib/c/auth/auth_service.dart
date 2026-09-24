import 'dart:convert';

import 'package:alienai_c35/c/account/account_api.dart';
import 'package:alienai_c35/c/api/settings_conn.dart';
import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

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

(int referredByIid, bool referralDismissed) authReferralStateFrom(Map<String, dynamic> data) {
  final id = data['identity'] is Map<String, dynamic> ? data['identity'] as Map<String, dynamic> : const <String, dynamic>{};
  final refBy = int.tryParse('${id['referred_by_iid'] ?? data['referred_by_iid'] ?? ''}') ?? 0;
  final dismissed = id['referral_prompt_dismissed'] == true || data['referral_prompt_dismissed'] == true;
  return (refBy, dismissed);
}

class AuthService extends ChangeNotifier {
  LoginResult? _login;
  AuthSignInBusy _busy = AuthSignInBusy.none;
  var _sessionLocked = false;
  var _manualLocked = false;
  var _sessionUnlockMode = 'tap';

  LoginResult? get login => _login;
  bool get signedIn => _login != null || Session.instance.signedIn;
  AuthSignInBusy get busy => _busy;
  bool get anyBusy => _busy != AuthSignInBusy.none;
  bool get sessionLocked => _sessionLocked || _manualLocked;
  String get sessionUnlockMode => _sessionUnlockMode;

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
      if (res.statusCode == 200) {
        await _identityMergeFromAuthBody(jsonDecode(res.body) as Map<String, dynamic>);
        return null;
      }
      if (res.statusCode == 401) return 'Invalid session';
      return null;
    } catch (e) {
      lError('Session check failed: $e');
      return null;
    }
  }

  Future<void> _identityMergeFromAuthBody(Map<String, dynamic> data) async {
    final id = data['identity'] is Map<String, dynamic> ? data['identity'] as Map<String, dynamic> : const <String, dynamic>{};
    final roles = sessionGlobalRolesParse(data['global_roles'] ?? data['roles'] ?? id['global_roles'] ?? id['roles'] ?? id['is_root']);
    final refBy = int.tryParse('${id['referred_by_iid'] ?? data['referred_by_iid'] ?? ''}') ?? 0;
    final dismissed = id['referral_prompt_dismissed'] == true || data['referral_prompt_dismissed'] == true;
    await Session.instance.identityMerge(
      name: '${id['name'] ?? ''}',
      alienId: '${id['alien_id'] ?? id['handle'] ?? ''}',
      pic: authPicFrom(data),
      email: '${id['email'] ?? ''}',
      globalRoles: roles.isEmpty ? null : roles,
      referredByIid: refBy > 0 ? refBy : null,
      referralDismissed: dismissed ? true : null,
    );
    final handle = Session.instance.handle;
    if (_login != null) {
      _login = LoginResult(
        uid: _login!.uid,
        token: _login!.token,
        name: Session.instance.name,
        email: Session.instance.email,
        handle: handle,
        pic: Session.instance.pic,
      );
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> claimReferral(String code) async {
    final token = sessionAuthToken();
    if (token.isEmpty) throw ApiException('Not signed in');
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/v1/auth/referral/claim');
    final res = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    ).timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || data['ok'] != true) {
      throw ApiException(data['error'] as String? ?? 'Referral claim failed');
    }
    await Session.instance.referralDismissedPut();
    await validateSessionForServer();
    return data;
  }

  Future<void> dismissReferralPrompt() async {
    await Session.instance.referralDismissedPut();
    final token = sessionAuthToken();
    if (token.isEmpty) return;
    try {
      final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
      await http.post(
        Uri.parse('$base/v1/auth/referral/dismiss'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<String> claimAlienId({required String alienId, String? referralCode}) async {
    final token = sessionAuthToken();
    if (token.isEmpty) throw ApiException('Not signed in');
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/v1/auth/alien_id/claim');
    final res = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'alien_id': alienId,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      }),
    ).timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || data['ok'] != true) {
      throw ApiException(data['error'] as String? ?? 'Failed to set Alien ID');
    }
    final claimed = '${data['alien_id'] ?? alienId}';
    await Session.instance.identityMerge(alienId: claimed);
    await validateSessionForServer();
    return claimed;
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

  Future<LoginResult> signInWithGoogle() async {
    if (anyBusy) throw ApiException('Busy');
    _busy = AuthSignInBusy.google;
    notifyListeners();
    try {
      final authBase = C35Config.providerAuthBase;
      final clientId = const Uuid().v4();
      final uri = Uri.parse('$authBase/a/auth/google').replace(queryParameters: {
        'return': C35AppId.oauthReturn,
        'public_origin': authBase,
        'client_id': clientId,
      });
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw ApiException('Could not open browser for Google sign-in.');
      for (var i = 0; i < 90; i++) {
        if (i > 0) await Future<void>.delayed(const Duration(seconds: 1));
        final poll = await _pollGoogle(clientId, authBase);
        if (poll.$1 != null) throw ApiException(poll.$1!);
        if (poll.$2 == null) continue;
        return poll.$2!;
      }
      throw ApiException('Google sign-in timed out. Please try again.');
    } finally {
      _busy = AuthSignInBusy.none;
      notifyListeners();
    }
  }

  Future<(String?, LoginResult?)> _pollGoogle(String clientId, String authBase) async {
    try {
      final uri = Uri.parse('$authBase/a/auth/google/result').replace(queryParameters: {'client_id': clientId});
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return (null, null);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ready'] != true) return (null, null);
      if (body['ok'] != true) return ('Google sign-in was denied or cancelled', null);
      final uid = int.tryParse('${body['uid']}');
      final token = '${body['token'] ?? body['session_id'] ?? ''}'.trim();
      if (uid == null || uid <= 0 || token.isEmpty) return ('Google sign-in failed', null);
      final (refBy, dismissed) = authReferralStateFrom(body);
      final stored = await _store(
        LoginResult(
          uid: uid,
          token: token,
          name: '${body['name'] ?? ''}',
          email: '${body['email'] ?? ''}',
          handle: '${body['handle'] ?? ''}',
          pic: authPicFrom(body),
        ),
        globalRoles: authGlobalRolesFrom(body),
        referredByIid: refBy,
        referralDismissed: dismissed,
      );
      await validateSessionForServer();
      return (null, _login ?? stored);
    } catch (_) {
      return (null, null);
    }
  }

  Future<LoginResult> _complete(Uri uri, Map<String, dynamic> body) async {
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw ApiException(data['error'] as String? ?? 'Invalid credentials');
    final token = data['token'] as String? ?? '';
    final idData = data['identity'] as Map<String, dynamic>? ?? {};
    final uid = (idData['id'] as num?)?.toInt() ?? (data['uid'] as num?)?.toInt() ?? 0;
    if (token.isEmpty || uid == 0) throw ApiException('Sign-in failed.');
    final (refBy, dismissed) = authReferralStateFrom(data);
    final stored = await _store(
      LoginResult(
        uid: uid,
        token: token,
        name: '${idData['name'] ?? idData['handle'] ?? data['name'] ?? ''}',
        email: '${idData['email'] ?? data['email'] ?? ''}',
        handle: '${idData['handle'] ?? ''}',
        pic: authPicFrom(data),
      ),
      globalRoles: authGlobalRolesFrom(data),
      referredByIid: refBy,
      referralDismissed: dismissed,
    );
    await validateSessionForServer();
    return _login ?? stored;
  }

  Future<LoginResult> _store(
    LoginResult result, {
    List<String> globalRoles = const [],
    int referredByIid = 0,
    bool referralDismissed = false,
  }) async {
    await Session.instance.put(
      uid: result.uid,
      name: result.name,
      handle: result.handle,
      pic: result.pic,
      email: result.email,
      token: result.token,
      globalRoles: globalRoles,
      referredByIid: referredByIid,
      referralDismissed: referralDismissed,
    );
    _login = LoginResult(uid: result.uid, token: result.token, name: result.name, email: result.email, handle: result.handle, pic: result.pic);
    notifyListeners();
    return _login!;
  }

  Future<void> checkSessionStatus(SettingsConn conn) async {
    if (!signedIn) return;
    try {
      final api = AccountApi(invoke: conn.authInvoke, uid: Session.instance.uid);
      final status = await api.sessionStatus(clientId: await deviceInstallId());
      _sessionUnlockMode = status.unlockMode.isEmpty ? 'tap' : status.unlockMode;
      _sessionLocked = status.isLocked;
      notifyListeners();
    } catch (_) {}
  }

  void lockSession() {
    if (!signedIn) return;
    _manualLocked = true;
    notifyListeners();
  }

  Future<bool> unlockSession(SettingsConn conn, {String pin = ''}) async {
    if (!signedIn) return false;
    if (_manualLocked && !_sessionLocked && _sessionUnlockMode == 'tap' && pin.isEmpty) {
      _manualLocked = false;
      notifyListeners();
      return true;
    }
    final api = AccountApi(invoke: conn.authInvoke, uid: Session.instance.uid);
    final ok = await api.sessionUnlock(clientId: await deviceInstallId(), pin: pin);
    if (ok) {
      _sessionLocked = false;
      _manualLocked = false;
      notifyListeners();
    }
    return ok;
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
    _sessionLocked = false;
    _manualLocked = false;
    notifyListeners();
  }
}

String uiAuthError(Object e) {
  if (e is ApiException) return uiApiErrorMessage(e.message, fallback: 'Sign-in failed. Please try again.');
  return uiFriendlyError(e, fallback: 'Sign-in failed. Please try again.');
}
