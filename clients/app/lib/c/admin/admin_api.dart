import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/c/pb/c35/inst.pb.dart';
import 'package:alienai_c35/c/pb/c35/log.pb.dart';
import 'package:alienai_c35/c/pb/c35/object.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

class AdminApi {
  AdminApi(ReferralConn conn) : _invoke = conn.invoke, _chat = null;

  AdminApi.chat(ChatConn conn) : _invoke = conn.invoke, _chat = conn;

  final Future<InvokeRes> Function(InvokeReq) _invoke;
  final ChatConn? _chat;

  ChatConn get chatConn {
    final c = _chat;
    if (c == null) throw 'AdminApi.chat(ChatConn) required';
    return c;
  }

  Future<void> userPut({
    required int targetId,
    String? name,
    String? avatarUrl,
    int? referredByUid,
    bool clearReferredBy = false,
    String? handle,
    String? authEmail,
  }) async {
    final req = ReqAdminUserPut(targetIdentityId: Int64(targetId));
    if (name != null) req.name = name;
    if (avatarUrl != null) req.avatarUrl = avatarUrl;
    if (clearReferredBy) {
      req.referredByUid = Int64.ZERO;
    } else if (referredByUid != null) {
      req.referredByUid = Int64(referredByUid);
    }
    if (handle != null) req.handle = handle;
    if (authEmail != null) req.authEmail = authEmail;
    final res = await _invoke(InvokeReq(reqId: const Uuid().v4(), adminUserPut: req));
    invokeResThrow(res, fallback: 'Failed to update user');
  }

  Future<List<AdminUserHit>> userSearch(String query, {int limit = 20}) async {
    final res = await _invoke(InvokeReq(
      reqId: const Uuid().v4(),
      adminUserSearch: ReqAdminUserSearch(query: query, limit: limit),
    ));
    invokeResThrow(res, fallback: 'Search failed');
    if (!res.hasAdminUserSearch()) return [];
    return res.adminUserSearch.users;
  }

  Future<bool> authEmailAvailable(String email, {int excludeId = 0}) async {
    final q = email.trim().toLowerCase();
    if (q.isEmpty) return false;
    final hits = await userSearch(q, limit: 10);
    for (final h in hits) {
      if (h.email.trim().toLowerCase() == q && h.identityId.toInt() != excludeId) return false;
    }
    return true;
  }

  Future<bool> handleAvailable(String handle, {int excludeId = 0}) async {
    var id = handle.trim().toLowerCase();
    if (id.startsWith('@')) id = id.substring(1);
    if (id.isEmpty) return false;
    final hits = await userSearch(id, limit: 10);
    for (final h in hits) {
      final hId = h.handle.trim().toLowerCase().replaceFirst('@', '');
      if (hId == id && h.identityId.toInt() != excludeId) return false;
    }
    return true;
  }

  Future<List<Log>> adminLogList(ReqAdminLogList req) async {
    final res = await _invoke(InvokeReq(reqId: const Uuid().v4(), adminLogList: req));
    invokeResThrow(res, fallback: 'Failed to load logs');
    if (!res.hasAdminLogList()) return [];
    return res.adminLogList.logs;
  }

  Future<List<InstDoc>> instList({String? scope, String? kind, bool? enabled, bool includeDeleted = false}) async {
    final req = ReqInstList(includeDeleted: includeDeleted);
    if (scope != null) req.scope = scope;
    if (kind != null) req.kind = kind;
    if (enabled != null) req.enabled = enabled;
    final res = await _invoke(InvokeReq(reqId: const Uuid().v4(), instList: req));
    invokeResThrow(res, fallback: 'Failed to load inst');
    if (!res.hasInstList()) return [];
    return res.instList.items;
  }

  Future<InstDoc> instPut(InstDoc doc) async {
    final res = await _invoke(InvokeReq(reqId: const Uuid().v4(), instPut: ReqInstPut(doc: doc)));
    invokeResThrow(res, fallback: 'Failed to save inst');
    if (!res.hasInstPut() || !res.instPut.hasDoc()) throw 'Failed to save inst';
    return res.instPut.doc;
  }

  Future<void> instDelete(String id) async {
    final res = await _invoke(InvokeReq(reqId: const Uuid().v4(), instDelete: ReqInstDelete(id: id)));
    invokeResThrow(res, fallback: 'Failed to delete inst');
  }

  Future<List<ObjectAliasDoc>> objectAliasList({bool? verified, String? lang, String? q, int limit = 200}) async {
    final req = ReqObjectAliasList(limit: limit);
    if (verified != null) req.verified = verified;
    if (lang != null) req.lang = lang;
    if (q != null && q.isNotEmpty) req.q = q;
    final res = await _invoke(InvokeReq(reqId: const Uuid().v4(), objectAliasList: req));
    invokeResThrow(res, fallback: 'Failed to load object aliases');
    if (!res.hasObjectAliasList()) return [];
    return res.objectAliasList.items;
  }

  Future<ObjectAliasDoc> objectAliasPut(ObjectAliasDoc doc) async {
    final res = await _invoke(InvokeReq(reqId: const Uuid().v4(), objectAliasPut: ReqObjectAliasPut(doc: doc)));
    invokeResThrow(res, fallback: 'Failed to save object alias');
    if (!res.hasObjectAliasPut() || !res.objectAliasPut.hasDoc()) throw 'Failed to save object alias';
    return res.objectAliasPut.doc;
  }

  Future<void> statsSubscribe() => chatConn.statsSubscribe();

  Future<void> statsUnsubscribe() => chatConn.statsUnsubscribe();

  Future<void> logSubscribe({int? ownerIid}) => chatConn.logSubscribe(ownerIid: ownerIid);

  Future<void> logUnsubscribe() => chatConn.logUnsubscribe();
}
