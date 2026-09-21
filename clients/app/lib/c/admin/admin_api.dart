import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

class AdminApi {
  AdminApi(this.conn);

  final ReferralConn conn;

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
    final res = await conn.invoke(InvokeReq(reqId: const Uuid().v4(), adminUserPut: req));
    invokeResThrow(res, fallback: 'Failed to update user');
  }

  Future<List<AdminUserHit>> userSearch(String query, {int limit = 20}) async {
    final res = await conn.invoke(InvokeReq(
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
}
